# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::Logging::Graphs;
use strict;
use warnings;
use 5.010;

use GD;
use GD::Simple;
use GD::Graph;
use GD::Graph::area;
use GD::Graph::lines;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::linespoints;
use GD::Graph::colour qw(:lists);
use Maplat::Helpers::DateStrings;
use Carp;

our $VERSION = 0.995;

my ($graphWidth, $graphHeight, $graphHBarHeight) = (900, 400, 650);
my ($smallgraphWidth, $smallgraphHeight) = (200, 100);
my $slidingWindowSize = 4;

my %plugins;
my @paintcolors;

BEGIN {
    # Make a list of static colors
    my @tempcolors = colour_list(1000);
    foreach my $color (@tempcolors) {
        next if(!defined($color));
        next if($color eq "white");
        push @paintcolors, $color;
    }
    @paintcolors = (@paintcolors, @paintcolors, @paintcolors, @paintcolors);
}


sub registerPlugin {
    my ($devicetype, $funcref) = @_;
    
    $plugins{$devicetype} = $funcref;
    return;
}

sub simpleGraph {
    my ($dbh, $devicetype, $graphname, $hostname, $ctime, $starttime) = @_;
    
    if(defined($plugins{$devicetype})) {
        return $plugins{$devicetype}->($dbh, $devicetype, $graphname, $hostname, $ctime, $starttime);
    }
    
    my $selstmt = "SELECT * FROM logging_reportgraphs
                    WHERE device_type = ?
                    AND graph_name = ?";
    my $selsth = $dbh->prepare_cached($selstmt)
            or croak($dbh->errstr);
    $selsth->execute($devicetype, $graphname) or croak($dbh->errstr);
    my $graph = $selsth->fetchrow_hashref;
    $selsth->finish;
    
    
    if(!defined($graph)) {
        return;
    }
    
    my $table = 'logging_log_' . lc($devicetype);
    
    return genGraph($dbh, $graph, $table, $hostname, $ctime, $starttime);
}

sub genGraph {
    my ($dbh, $graph, $table, $host, $ctime, $starttime) = @_;

    # Starttime is the time defining when the graph starts. If it is not defined, and endtime of
    # now() is presumed and starttime is now() - $timeframe
    # starttime is an ISO timestring, as accepted my PostgreSQL.

    my ($timeframe, $precision, $numElements) = parseCTime($ctime);
    
    my $fastQuery = 0;
    if(!defined($starttime) || $starttime eq '') {
        $starttime = offsetISODate(getISODate(), 0 - $timeframe);
    }
    my $endtime = offsetISODate($starttime, $timeframe);
    
    # Prepare various dynamic data storages
    my @cols;
    my @pgcols = ("displaydate");
    my @tmp1;
    my %stor = (displaydate => \@tmp1);
    foreach my $column (@{$graph->{columnnames}}) {
        my @tmp2;
        $stor{"sum_" . $column} = \@tmp2;
        if($column =~ /_ok$/) {
            push @cols, "sum(((" . $column . "::integer)*100))/count(*) as sum_" . $column;
        } else {
            push @cols, "sum($column)/count(*) as sum_" . $column;
        }
        push @pgcols, "sum_" . $column;
    }
    
    # Read data from database
    my ($stmt, $sth);
    
    # if starttime is empty (of the last datasets counting back from now() are used), which is the default use,
    # we use a simple statement and use prepare_cached for speed. If we use a specific starttime, we have to do some
    # extra math to get the right data. This is also usually a one-of calculation for each specific starttime, so
    # we do *not* cache the statement to save some precious server resources in the long run

    $stmt = "SELECT displaydate_" . $ctime . " AS displaydate,
        " . join(',', @cols) . "
        FROM $table
        WHERE hostname = ?
        AND logtime >= ?
        AND logtime < ?
        group by  displaydate_" . $ctime . "
        order by displaydate_" . $ctime;
    
    $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);

    #print "** $stmt **\n";
    $sth->execute($host, $starttime, $endtime) or croak($dbh->errstr);
    my %datarows;
    my $coredate = '';
    while((my $row = $sth->fetchrow_hashref)) {
        my $nicedate = $row->{displaydate};
        $nicedate =~ s/\+\d\d$//o;
        $row->{displaydate} = $nicedate;
        $datarows{$nicedate} = $row;
        # Make core date always the last date and add to the back (incl. filling in missing pieces)
        if($coredate eq '') {
            $coredate = $nicedate;
        }
       } 
    $sth->finish;
    
    return calcGraph($dbh, $graph, $table, $host, $ctime, $starttime, $coredate, \%datarows);
}


sub calcGraph {
    
    my ($dbh, $graph, $table, $host, $ctime, $starttime, $coredate, $datarows) = @_;

    my ($timeframe, $precision, $numElements) = parseCTime($ctime);

    my @pgcols = ("displaydate");
    my @tmp1;
    my %stor = (displaydate => \@tmp1);
    foreach my $column (@{$graph->{columnnames}}) {
        push @pgcols, "sum_" . $column;
    }

    my $datecount = 1;
    if($coredate eq '') {
        $coredate = getISODate();
    }
    
    my @alldates = ($coredate);
    while($datecount < $numElements) {
        $coredate = offsetISODate($coredate, $precision);
        push @alldates, $coredate;
        $datecount++;
    }
    
    my $calcslider = 0;
    if($graph->{graph_type} =~ /lines/ && $graph->{cummulate}) {
        # Special case: If the graph type is lines or linespoints and cummulate is set
        # (which is normally not possible), we assume that there are only two data
        # sets: The "real" value and a sliding average we calculate in THIS function.
        # We assume that both sets are defined in graph, as "data" and "slider". The
        # slider does not need to hold values, we calculate them here.

        $graph->{cummulate} = 0;
        $calcslider = 1;
    }

    my ($ymin, $ymax);
    my @slider;
    foreach my $rowdate (@alldates) {
        my $nicedate = $rowdate;
        $nicedate =~ s/\+\d\d$//o;
                
        if(defined($datarows->{$rowdate})) {
            my $row = $datarows->{$rowdate};

            if($calcslider) {
                push @slider, $row->{sum_data};
                if((scalar @slider) > $slidingWindowSize) {
                    shift @slider;
                }
                my $avg = 0;
                foreach my $slid (@slider) {
                    $avg += $slid;
                }
                $avg = $avg / (scalar @slider);
                $row->{sum_slider} = $avg;            
            }
            
            my $sum = 0;
            foreach my $pgcol (@pgcols) {
                if($pgcol eq 'displaydate') {
                    push @{$stor{$pgcol}}, $nicedate;
                } else {
                    push @{$stor{$pgcol}}, $row->{$pgcol};
                }
                next if($pgcol !~ /^sum_/);
                if($graph->{cummulate}) {
                    if($pgcol =~ /^sum_/) {
                        $sum += $row->{$pgcol};
                    }
                } else {
                    $sum = $row->{$pgcol};
                    if(!defined($ymin)) {
                        $ymin = $sum;
                        $ymax = $sum;
                    } elsif($ymin > $sum) {
                        $ymin = $sum;
                    } elsif($ymax < $sum) {
                        $ymax = $sum;
                    }                
                }
            }

            # For cummulated graphs, we need the SUM of all columns to work out ymin/ymax
            if($graph->{cummulate}) {
                if(!defined($ymin)) {
                    $ymin = $sum;
                    $ymax = $sum;
                } elsif($ymin > $sum) {
                    $ymin = $sum;
                } elsif($ymax < $sum) {
                    $ymax = $sum;
                }
            }
        } else {
            # Push a dummy row, don't change min/max stuff
            
            # The expeption here is if we calculate a sliding average
            # and usezero is set. In this case, we need to consider unavailable
            # data within our average.
            if($calcslider) {
                push @{$stor{displaydate}}, $nicedate;
                push @{$stor{sum_data}}, 0;
                push @slider, 0;
                if((scalar @slider) > $slidingWindowSize) {
                    shift @slider;
                }
                my $avg = 0;
                foreach my $slid (@slider) {
                    $avg += $slid;
                }
                $avg = $avg / (scalar @slider);
                push @{$stor{sum_slider}}, $avg;            
            } else {
                foreach my $pgcol (@pgcols) {
                    if($pgcol eq "displaydate") {
                        push @{$stor{$pgcol}}, $nicedate;
                    } else {
                        if(defined($graph->{usezero}) && $graph->{usezero}) {
                            push @{$stor{$pgcol}}, 0;
                        } else {
                            push @{$stor{$pgcol}}, undef;
                        }
                    }
                }
            }
        }
    }
    
    # Sanitize ymin/ymax -> we ALWAYS want y==0 to show up
    if(!defined($ymin)) {
        return defaultImage();
    } elsif($ymin > 0) {
        $ymin = 0;
    }
    
    if(!defined($ymax)) {
        return defaultImage();
    } elsif($ymax < 0) {
        $ymax = 0;
    }
    
    # Prepare data for painting
    my @graphdata;
    foreach my $pgcol (@pgcols) {
        push @graphdata, $stor{$pgcol};
    }
    my @legend = @{$graph->{columnlabels}};
    my $classname = $graph->{graph_type};
    
    # Get correct class and set some default values
    my $paint;
    given($classname) {
        when("lines") {
            $paint = GD::Graph::lines->new($graphWidth, $graphHeight);
        }
        when("linespoints") {
            $paint = GD::Graph::linespoints->new($graphWidth, $graphHeight);
        }
        when("area") {
            $paint = GD::Graph::area->new($graphWidth, $graphHeight);
        }
        when("bars") {
            $paint = GD::Graph::bars->new($graphWidth, $graphHeight);
        }
        when("hbars") {
            $paint = GD::Graph::hbars->new($graphWidth, $graphHBarHeight);
        }
    }
    $paint->set_legend(@legend);
    
    
    
    
    
    $paint->set( 
        #'dclrs' => [ qw(lgreen blue red purple orange lred green pink dyellow) ],
        #'dclrs' => [@paintcolors],
        'title' => $graph->{title} . " / $ctime / $host", 
        'x_label' => 'Time', 
        'y_label' => $graph->{ylabel}, 
        'long_ticks' => 1, 
        'tick_length' => 0, 
        'x_ticks' => 0, 
        'x_label_position' => .5, 
        'y_label_position' => .5, 
        
        'bgclr' => 'white', 
        'transparent' => 0, 
        
        'y_tick_number' => 10, 
        'y_number_format' => '%d', 
        'y_max_value' => $ymax, 
        'y_min_value' => $ymin, 
        'y_plot_values' => 1, 
        'x_plot_values' => 1, 
        
        'zero_axis' => 1, 
        'lg_cols' => 7,     
        'accent_treshold' => 100_000, 
    );
    if($graph->{cummulate}) {
        $paint->set(
            'cumulate' => 2,
        );
    }
    
    if($classname ne "hbars") {
        $paint->set(
            'x_labels_vertical'=> 1, 
        );        
    }
    
    if($classname eq "lines") {
        if($calcslider) {
            $paint->set(
                'line_width'=> 5, 
            );
        } else {
            $paint->set(
                'line_width'=> 2, 
            );
        }
    }
    
    $paint->plot(\@graphdata);
    
    my $img = $paint->gd->png();

    return $img;
}

sub defaultImage {

    my $paint = GD::Simple->new($smallgraphWidth, $smallgraphHeight);

    $paint->fgcolor('red');
    $paint->moveTo(0,0);
    $paint->line($smallgraphWidth-1, $smallgraphHeight-1);
    $paint->moveTo(0,$smallgraphHeight-1);
    $paint->line($smallgraphWidth-1, 1-$smallgraphHeight);
    
    $paint->fgcolor('black');
    $paint->moveTo(40,40);
    $paint->string("No data available");
    
    my $img = $paint->gd->png();
    return $img;
    
}

sub parseCTime {
    my ($ctime) = @_;
    
    my $precision; # in seconds
    my $timeframe; # in seconds
    my $numElements; # how many elements do we expect in the graph
    
    given($ctime) {
        when("hour") {
            $timeframe = 60*60; # 1 hour
            $precision = 60; # 1 minute
        }
        when("day") {
            $timeframe = 60*60*24; # 1 day
            $precision = 1800; # 30 minutes
        }
        when("week") {
            $timeframe = 60*60*24*7; # 7 day 604800
            $precision = 14400; # 4 hours
        }
        
        when("month") {
            $timeframe = 60*60*24*30; # 30 days
            $precision = 43200; # 12 hours
        }
        when("year") {
            $timeframe = 60*60*24*365; # 365 days
            $precision = 432000; # 5 days
        }
    }
    
    $numElements = int($timeframe/$precision);
    return ($timeframe, $precision, $numElements);    
}

1;
__END__

=head1 NAME

Maplat::Worker::Helpers::Graphs - generate logging graphs

=head1 SYNOPSIS

  use Maplat::Helpers::Logging::Graphs;
  
=head1 DESCRIPTION

This module provides the actual graph generating ability of Maplat::Logging. Currently, the only way to
generate graphs is through adding a correctly designed table and using Maplat::Worker::Logging::Graphs to
call this module.

It's planned that the Version 1.0 release will feature a (slightly) better interface that lets you add graph
generation for other stuff too while still using the same webinterface (e.g. a plugin or hook-infrastructure).

=head2 registerPlugin

Internal function, register a rendering plugin, interface is likely to change

=head2 simpleGraph

Internal function, generate a graph with simplified call arguments, also supports registered plugins,
interface is likely to change

=head2 calcGraph

Internal function, generates data for the graphs and calls genGraph to render them, API may change.

=head2 defaultImage

Internal function, generates a default image, API may change.

=head2 genGraph

Internal function, generates the graphs by using GD, API may change.

=head2 parseCTime

Internal function, API may change.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
