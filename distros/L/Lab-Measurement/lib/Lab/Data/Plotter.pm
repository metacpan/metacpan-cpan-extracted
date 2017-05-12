#!/usr/bin/perl

package Lab::Data::Plotter;
our $VERSION = '3.542';

use strict;
use Lab::Data::Meta;
use Data::Dumper;
use Time::HiRes qw/gettimeofday tv_interval/;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ( $main_meta, $options, @other ) = @_;
    my @other_metas;
    for my $meta ( $main_meta, @other ) {
        unless ( ref $meta eq 'Lab::Data::Meta' ) {
            for ( "", qw/.META META .meta meta/ ) {
                if ( -e $meta . $_ ) {
                    $meta = $meta . $_;
                    last;
                }
            }
            die "Metafile $meta does not exist!" unless ( -e $meta );
            $meta = Lab::Data::Meta->new_from_file($meta);
        }
        push @other_metas, $meta;
    }

    $main_meta = shift @other_metas;

    my $self = bless {
        meta        => $main_meta,
        options     => $options,
        other_metas => \@other_metas,
    }, $class;

    return $self;
}

sub start_live_plot {
    my ( $self, $plot, $interval ) = @_;
    $self->{live_plot}->{pipe}    = $self->_start_plot($plot);
    $self->{live_plot}->{plot}    = $plot;
    $self->{live_plot}->{refresh} = $interval;
    $self->{live_plot}->{last}    = [gettimeofday];
}

sub update_live_plot {
    my $self = shift;
    return unless ( defined $self->{live_plot} );

    return
        if (
        ( $self->{live_plot}->{refresh} )
        && ( tv_interval( $self->{live_plot}->{last}, [gettimeofday] )
            < ( $self->{live_plot}->{refresh} ) )
        );

    $self->{live_plot}->{last} = [gettimeofday];

    $self->_plot( $self->{live_plot}->{pipe}, $self->{live_plot}->{plot} );
}

sub force_update {
    my $self = shift;
    return unless ( defined $self->{live_plot} );
    $self->{live_plot}->{last} = [gettimeofday];
    $self->_plot( $self->{live_plot}->{pipe}, $self->{live_plot}->{plot} );
}

sub stop_live_plot {
    my $self = shift;
    return unless ( defined $self->{live_plot} );

    close $self->{live_plot}->{pipe};
    undef $self->{live_plot};
}

sub plot {
    my ( $self, $plot ) = @_;

    die "Plot what?" unless ( $self->{meta} && $plot );

    my $gpipe = $self->_start_plot($plot);
    $self->_plot( $gpipe, $plot );

    return $gpipe;
}

sub _start_plot {
    my ( $self, $plot ) = @_;
    die "plot \"$plot\" undefined"
        unless ( defined( $self->{meta}->plot($plot) ) );

    my $gpipe;
    if ( $self->{options}->{dump} ) {
        open $gpipe, ">" . $self->{options}->{dump}
            or die "cannot open gnuplot dump file "
            . $self->{options}->{dump};
    }
    else {
        $gpipe = $self->get_gnuplot_pipe();
    }

    my $gp = "";
    $gp .= "# Encoding of this file\n";
    $gp .= "set encoding iso_8859_1\n";

    # grrr ^^^

    if ( $self->{options}->{eps} ) {
        $gp .= "#\n# Output to file\n";
        $gp .= "set terminal postscript color enhanced 10\n";
        $gp .= qq(set output ") . $self->{options}->{eps} . qq("\n);
    }
    elsif ( $self->{options}->{jpg} ) {
        $gp .= "#\n# Output to file, jpeg format\n";
        $gp .= "set terminal jpeg giant enhanced size 1024,768 crop\n";
        $gp .= qq(set output ") . $self->{options}->{jpg} . qq("\n);
    }

    if ( $self->{meta}->plot_type($plot) eq 'pm3d' ) {
        $gp .= "#\n# Set color plot\n";
        $gp .= "set pm3d map corners2color c1\n";
        $gp .= "set view map\n";
        if ( $self->{meta}->plot_palette($plot) ) {
            $gp .= "set palette " . $self->{meta}->plot_palette($plot) . "\n";
        }
    }

    #Quatsch. Aussen über Files loopen, dann über Konstanten
    if ( $self->{meta}->constant() ) {
        $gp .= "#\n# Constants\n";
        for ( @{ $self->{meta}->constant() } ) {
            unless ( $self->{options}->{multiple} ) {
                $gp .= ( $_->{name} ) . "=" . ( $_->{value} ) . "\n";
            }
            else {
                my $num = 0;
                for my $meta ( $self->{meta}, @{ $self->{othermetas} } ) {
                    $gp
                        .= ( $_->{name} )
                        . "$num++="
                        . ( $_->{value} ) . "\n";
                }
            }
        }
    }

    my $xaxis  = $self->{meta}->plot_xaxis($plot);
    my $yaxis  = $self->{meta}->plot_yaxis($plot);
    my $zaxis  = $self->{meta}->plot_zaxis($plot);
    my $cbaxis = $self->{meta}->plot_cbaxis($plot);

    $gp .= "#\n# Axis labels\n";
    for my $i (qw/x y z cb/) {
        my $axisname = "plot_" . $i . "axis";
        my $metaaxis = $self->{meta}->$axisname($plot);
        if ( defined $metaaxis ) {
            my $label
                = '"'
                . ( $self->{meta}->axis_label($metaaxis) ) . ' ('
                . ( $self->{meta}->axis_unit($metaaxis) ) . ")"
                . (
                $self->{options}->{fulllabels}
                ? ( '\n' . $self->{meta}->axis_description($metaaxis) )
                : ''
                ) . "\"\n";
            $gp .= "set " . $i . "label " . $label;
        }
    }

    if ( defined $self->{meta}->plot_grid($plot) ) {
        $gp .= "#\n# Grid\n";
        $gp .= "set grid " . ( $self->{meta}->plot_grid($plot) ) . "\n";
    }

    if ( $self->{meta}->plot_time($plot) ) {
        $gp .= "#\n# Time axes\n";
        for (qw/x y z cb/) {
            if ( $self->{meta}->plot_time($plot) =~ /$_/ ) {
                $gp .= "set " . $_ . "data time\n";
            }
        }
        $gp .= qq(set timefmt "%s"\n);
    }

    my $gp_help;
    for (qw/x y z cb/) {
        my $name = "plot_" . $_ . "format";
        if ( $self->{meta}->$name($plot) ) {
            $gp_help .= qq(set format $_ ")
                . ( $self->{meta}->$name($plot) ) . qq("\n);
        }
    }
    $gp .= "#\n# Axis format\n" . $gp_help if ($gp_help);

    unless ( $self->{options}->{multiple} ) {
        $gp .= "#\n# Ranges\n";
        my $xmin
            = ( defined $self->{meta}->axis_min($xaxis) )
            ? $self->{meta}->axis_min($xaxis)
            : "*";
        my $xmax
            = ( defined $self->{meta}->axis_max($xaxis) )
            ? $self->{meta}->axis_max($xaxis)
            : "*";
        my $ymin
            = ( defined $self->{meta}->axis_min($yaxis) )
            ? $self->{meta}->axis_min($yaxis)
            : "*";
        my $ymax
            = ( defined $self->{meta}->axis_max($yaxis) )
            ? $self->{meta}->axis_max($yaxis)
            : "*";
        $gp .= "set xrange [$xmin:$xmax]\n";
        $gp .= "set yrange [$ymin:$ymax]\n";
        if ($zaxis) {
            my $zmin
                = ( defined $self->{meta}->axis_min($zaxis) )
                ? $self->{meta}->axis_min($zaxis)
                : "*";
            my $zmax
                = ( defined $self->{meta}->axis_max($zaxis) )
                ? $self->{meta}->axis_max($zaxis)
                : "*";
            $gp .= "set zrange [$zmin:$zmax]\n";
        }
        if ($cbaxis) {
            my $cbmin
                = ( defined $self->{meta}->axis_min($cbaxis) )
                ? $self->{meta}->axis_min($cbaxis)
                : "*";
            my $cbmax
                = ( defined $self->{meta}->axis_max($cbaxis) )
                ? $self->{meta}->axis_max($cbaxis)
                : "*";
            $gp .= "set cbrange [$cbmin:$cbmax]\n";
            $gp .= "set zrange [$cbmin:$cbmax]\n"
                if ( $self->{meta}->plot_logscale($plot) );
        }
    }

    if ( $self->{meta}->plot_logscale($plot) ) {
        $gp .= "#\n# Axes with logscale\n";
        $gp .= "set logscale " . $self->{meta}->plot_logscale($plot) . "\n";
    }

    $gp .= "#\n# Title and labels\n";
    $gp .= qq(set title ");
    if ( $self->{meta}->dataset_title() ) {
        $gp .= $self->{meta}->dataset_title();
    }
    if ( $self->{meta}->sample() ) {
        $gp .= " " . $self->{meta}->sample();
    }
    $gp .= "\"\n";
    if ( $self->{options}->{fulllabels} ) {
        my $h      = 0.95;
        my $screen = 0.99;
        my @lines  = split "\n", $self->{meta}->dataset_description();
        for (@lines) {
            if ( $self->{meta}->plot_type($plot) eq 'pm3d' ) {
                $gp .= qq(set label "$_" at screen 0.01, screen $screen\n);
            }
            else {
                $gp .= qq(set label "$_" at graph 0.02, graph $h\n);
            }
            $h      -= 0.04;
            $screen -= 0.025;
            $screen = 0.13 if ( abs( $screen - 0.865 ) < 0.001 );
        }

    }
    if ( $self->{meta}->plot_label($plot) ) {
        my @labels = $self->{meta}->plot_label($plot);
        for (@labels) {
            my $text = $_->{text};
            my $x    = $_->{x};
            my $y    = $_->{y};
            $gp .= qq(set label "$text" at $x,$y center front\n);
        }
    }

    print $gpipe $gp;
    return $gpipe;
}

sub _plot {
    my ( $self, $gpipe, $plot ) = @_;

    my $xaxis  = $self->{meta}->plot_xaxis($plot);
    my $yaxis  = $self->{meta}->plot_yaxis($plot);
    my $zaxis  = $self->{meta}->plot_zaxis($plot);
    my $cbaxis = $self->{meta}->plot_cbaxis($plot);

    my $xexp  = $self->_flatten_exp($xaxis);
    my $yexp  = $self->_flatten_exp($yaxis);
    my $zexp  = $self->_flatten_exp($zaxis) if ($zaxis);
    my $cbexp = $self->_flatten_exp($cbaxis) if ($cbaxis);

    my $datafile = $self->{meta}->get_abs_path() . $self->{meta}->data_file();

    my $pp;
    if ( $self->{meta}->plot_type($plot) eq 'pm3d' ) {
        $pp
            = qq(splot "$datafile" using ($xexp):($yexp):($cbexp) title "$plot"\n);
    }
    else {
        if ( $self->{options}->{live_latest} ) {
            my %blocks = $self->{meta}->block();
            my @keys   = sort( keys %blocks );
            @keys = splice @keys, -$self->{options}->{live_latest};
            $pp = "plot ";
            for (@keys) {
                $pp
                    .= qq("$datafile" using ($xexp):($yexp) every :::$_::$_ title "$blocks{label}" with lines, );
            }
            $pp = substr $pp, 0, ( length $pp ) - 2;
        }
        else {
            $pp
                = qq(plot "$datafile" using ($xexp):($yexp) title "$plot" with lines\n);
        }
    }
    print $gpipe $pp;

}

sub _plot_multiple {
    my ( $self, $gpipe, $plot ) = @_;

    my $xaxis  = $self->{meta}->plot_xaxis($plot);
    my $yaxis  = $self->{meta}->plot_yaxis($plot);
    my $zaxis  = $self->{meta}->plot_zaxis($plot);
    my $cbaxis = $self->{meta}->plot_cbaxis($plot);

    my $xexp  = $self->_flatten_exp($xaxis);
    my $yexp  = $self->_flatten_exp($yaxis);
    my $zexp  = $self->_flatten_exp($zaxis) if ($zaxis);
    my $cbexp = $self->_flatten_exp($cbaxis) if ($cbaxis);

    my $datafile = $self->{meta}->get_abs_path() . $self->{meta}->data_file();

    my $pp = "#\n# Plot\n";
    if ( $self->{meta}->plot_type($plot) eq 'pm3d' ) {
        $pp
            .= qq(splot "$datafile" using ($xexp):($yexp):($cbexp) title "$plot"\n);
    }
    else {
        if ( $self->{options}->{last_live} ) {
            my %blocks = $self->{meta}->block();
            my @keys   = sort( keys %blocks );
            @keys = splice @keys, -$self->{options}->{last_live};
            $pp .= "plot ";
            for (@keys) {
                $pp
                    .= qq("$datafile" using ($xexp):($yexp) every :::$_::$_ title "$blocks{label}" with lines, );
            }
            $pp = substr $pp, 0, ( length $pp ) - 2;
        }
        else {
            $pp .= qq(plot "$datafile" using ($xexp):($yexp) title "$plot"\n);
        }
    }
    print $gpipe $pp;

}

sub _flatten_exp {
    my ( $self, $axis ) = @_;
    $_ = $self->{meta}->axis_expression($axis);
    while (/\$A\d+/) {
        s/\$A(\d+)/($self->{meta}->axis_expression($1))/e;
    }
    while (/\$C\d+/) {
        s/\$C(\d+)/'$'.($1+1)/e;
    }
    $_;
}

sub available_plots {
    my $self = shift;

    my %plots = $self->{meta}->plot();
    my @names = ( keys %plots );

    for (@names) {
        my $xlabel = $self->{meta}->axis_label( $plots{$_}->{xaxis} );
        my $ylabel = $self->{meta}->axis_label( $plots{$_}->{yaxis} );

        $plots{$_} = "$ylabel vs. $xlabel";
    }
    return %plots;
}

sub get_gnuplot_pipe {
    my $self = shift;
    my $gpname;
    if ( $^O =~ /MSWin32/ ) {
        $gpname = "pgnuplot";
    }
    else {
        $gpname = "gnuplot -noraise";
    }
    if ( open my $GP, "| $gpname" ) {
        my $oldfh = select($GP);
        $| = 1;
        select($oldfh);
        return $GP;
    }
    return undef;
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Data::Plotter - Plot data with Gnuplot

=head1 SYNOPSIS

  use Lab::Data::Plotter;
  
  my $plotter=new Lab::Data::Plotter($metafile);
  
  my %plots=$plotter->available_plots();
  my @names=keys %plots;
  
  $plotter->plot($names[0]);

=head1 DESCRIPTION

This module can plot data with GnuPlot. It plots data from C<.DATA> files
and takes into account the data information in the corresponding C<.META> file.

The module also offers the possibility to plot data live, while it is
being aquired.

=head1 CONSTRUCTOR

=head2 new

  $plotter=new Lab::Data::Plotter($meta,\%options);

Creates a Plotter object. C<$meta> is either an object of type
L<Lab::Data::Meta|Lab::Data::Meta> or a filename that points to a C<.META> file.

Available options are

=over 2

=item dump

=item eps

=item jpg

=item fulllabels

=item last_live

=back

=head1 METHODS

=head2 available_plots

  my %plots=$plotter->available_plots();

=head2 plot

  $plotter->plot($plot);

=head2 start_live_plot

  $plotter->start_live_plot($plot);

=head2 update_live_plot

  $plotter->update_live_plot();

=head2 stop_live_plot

  $plotter->stop_live_plot();

=head1 AUTHOR/COPYRIGHT

  Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>)
            2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
