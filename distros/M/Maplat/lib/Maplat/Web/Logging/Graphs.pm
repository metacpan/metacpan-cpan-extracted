# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Logging::Graphs;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);

use Maplat::Helpers::DateStrings;
use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    return $self;
}

sub reload {
    my ($self) = shift;
    
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    
    $self->register_webpath($self->{admin}->{webpath}, "get_admin");
    $self->register_webpath($self->{user}->{webpath}, "get_user");
    return;
}

sub get_admin {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{admin}->{pagetitle},
        webpath    =>  $self->{admin}->{webpath},
    );
    
    my $mustupdate = $cgi->param("submitform") || "0";
    if($mustupdate eq "1") {
        my @graph_ids = $cgi->param("graph_id");
        my $upstmt = "UPDATE logging_reportgraphs SET graph_name=?, title=?, ylabel=?,
                      graph_type=?, cummulate=?, columnnames=?, columnlabels=? WHERE graph_name=? AND device_type=?";
        my $upsth = $dbh->prepare_cached($upstmt) or croak($dbh->errstr);
        my $delstmt = "DELETE FROM logging_reportgraphs WHERE graph_name=? AND device_type=?";
        my $delsth = $dbh->prepare_cached($delstmt) or croak($dbh->errstr);
        my $instmt = "INSERT INTO logging_reportgraphs
                        (graph_name, device_type, title, ylabel, graph_type, cummulate, columnnames, columnlabels)
                        VALUES
                        (?,?,?,?,?,?,?,?)";
        my $insth = $dbh->prepare_cached($instmt) or croak($dbh->errstr);

        foreach my $graph_id (@graph_ids) {
            my $graph_name = $cgi->param("graph_name_" . $graph_id) || "";
            my $newname = $cgi->param("new_graph_name_" . $graph_id) || "";
            my $devtype = $cgi->param("devicetype_" . $graph_id) || "";
            my $title = $cgi->param("title_" . $graph_id) || "";
            my $ylabel = $cgi->param("ylabel_" . $graph_id) || "";
            my $type = $cgi->param("type_" . $graph_id) || "";
            my $cummulate = $cgi->param("cummulate_" . $graph_id) || "";
            if($cummulate eq "") {
                $cummulate = 'false';
            } else {
                $cummulate = 'true';
            }
            my $colnames = $cgi->param("colnames_" . $graph_id) || "";
            my @columnnames = split /\,/, $colnames;
            my $collabels = $cgi->param("collabels_" . $graph_id) || "";
            my @columnlabels = split /\,/, $collabels;
            
            my $delete = $cgi->param("delete_" . $graph_id) || "";
            
            if($graph_id eq "__NEW__") {
                if($newname ne "") {
                    if($insth->execute($newname, $devtype, $title, $ylabel, $type, $cummulate, \@columnnames, \@columnlabels)) {
                        $dbh->commit;
                    } else {
                        $dbh->rollback;
                    }                    
                }
            } elsif($delete eq "") {
                if($upsth->execute($newname, $title, $ylabel, $type, $cummulate, \@columnnames, \@columnlabels, $graph_name, $devtype)) {
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            } else {
                if($delsth->execute($graph_name, $devtype)) {
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            }

        }
        $upsth->finish;
        $delsth->finish;
        $insth->finish;
        $dbh->rollback;
    }

    my $stmt = "SELECT * " .
                "FROM logging_reportgraphs " .
                "ORDER BY graph_name, device_type";

    my @graphs;
    my $graphcnt = 0;
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);

    while((my $graph = $sth->fetchrow_hashref)) {
        $graphcnt++;
        
        $graph->{id} = $graph->{graph_name} . "__" . $graph->{device_type};
        $graph->{graphcnt} = $graphcnt;
        
        $graph->{colnames} = join(',', @{$graph->{columnnames}});
        $graph->{collabels} = join(',', @{$graph->{columnlabels}});
        
        push @graphs, $graph;
    }
    $sth->finish;
    $dbh->rollback;

    $webdata{graphs} = \@graphs;
    
    my %graphtypes = (
        lines        => 'Connected lines',
        linespoints    => 'Discrete points',
        area        => 'Filled areas',
        bars        => 'Vertical bars',
        hbars        => 'Horizontal bars',
    );
    
    my @gtypes;
    foreach my $gkey (sort keys %graphtypes) {
        my %tmp = (
            type    => $gkey,
            label    => $graphtypes{$gkey},
        );
        push @gtypes, \%tmp;
    }
    $webdata{graphtypes} = \@gtypes;
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/graphs_admin", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_user {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{user}->{pagetitle},
        webpath    =>  $self->{user}->{webpath},
    );
    
    my $mustupdate = $cgi->param("submitform") || "0";
    if($mustupdate eq "1") {
        my @graph_ids = $cgi->param("graph_id");
        my $upstmt = "UPDATE logging_reportgraphs SET title=?, ylabel=?,
                      graph_type=?, cummulate=?, columnnames=?, columnlabels=? WHERE graph_name=? AND device_type=?";
        my $upsth = $dbh->prepare_cached($upstmt) or croak($dbh->errstr);

        foreach my $graph_id (@graph_ids) {
            my $graph_name = $cgi->param("graph_name_" . $graph_id) || "";
            my $devtype = $cgi->param("devicetype_" . $graph_id) || "";
            my $title = $cgi->param("title_" . $graph_id) || "";
            my $ylabel = $cgi->param("ylabel_" . $graph_id) || "";
            my $type = $cgi->param("type_" . $graph_id) || "";
            my $cummulate = $cgi->param("cummulate_" . $graph_id) || "";
            if($cummulate eq "") {
                $cummulate = 'false';
            } else {
                $cummulate = 'true';
            }
            my $colnames = $cgi->param("colnames_" . $graph_id) || "";
            my @columnnames = split /\,/, $colnames;
            my $collabels = $cgi->param("collabels_" . $graph_id) || "";
            my @columnlabels = split /\,/, $collabels;
            

            if($upsth->execute($title, $ylabel, $type, $cummulate, \@columnnames, \@columnlabels, $graph_name, $devtype)) {
                $dbh->commit;
            } else {
                $dbh->rollback;
            }

        }
        $upsth->finish;
        $dbh->rollback;
    }

    my $stmt = "SELECT * " .
                "FROM logging_reportgraphs " .
                "ORDER BY graph_name, device_type";

    my @graphs;
    my $graphcnt = 0;
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);

    while((my $graph = $sth->fetchrow_hashref)) {
        $graphcnt++;
        
        $graph->{id} = $graph->{graph_name} . '__' . $graph->{device_type};
        $graph->{graphcnt} = $graphcnt;
        
        $graph->{colnames} = join(',', @{$graph->{columnnames}});
        $graph->{collabels} = join(',', @{$graph->{columnlabels}});
        
        push @graphs, $graph;
    }
    $sth->finish;
    $dbh->rollback;

    $webdata{graphs} = \@graphs;
    
    my %graphtypes = (
        lines        => 'Connected lines',
        linespoints    => 'Discrete points',
        area        => 'Filled areas',
        bars        => 'Vertical bars',
        hbars        => 'Horizontal bars',
    );
    
    my @gtypes;
    foreach my $gkey (sort keys %graphtypes) {
        my %tmp = (
            type    => $gkey,
            label    => $graphtypes{$gkey},
        );
        push @gtypes, \%tmp;
    }
    $webdata{graphtypes} = \@gtypes;
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/graphs_user", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}
1;
__END__

=head1 NAME

Maplat::Web::Logging::Graphs - configure Graphs to generate from logged data.

=head1 SYNOPSIS

  use Maplat::Web;
  use Maplat::Web::Logging;
  
Then configure() the module as you would normally.

=head1 DESCRIPTION

    <module>
        <modname>logginggraphs</modname>
        <pm>Logging::Graphs</pm>
        <options>
            <linktitle>Graphs</linktitle>
            <user>
                    <webpath>/logging/graphsuser</webpath>
                    <pagetitle>Graphs</pagetitle>
            </user>
            <admin>
                    <webpath>/logging/graphsadm</webpath>
                    <pagetitle>Graphs ADM</pagetitle>
            </admin>
            <db>maindb</db>
            <minurls>4</minurls>
        </options>
    </module>

This module provides the webmasks required to configure graphs generated from logged data.

=head2 get_user

Internal function, renders the user view.

=head2 get_admin

Internal function, renders the admin view.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
