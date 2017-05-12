package Lab::XPRESSION::Xpress::PlotterGUI_bidirectional;

use strict;
use IPC::Run qw( start pump finish timeout );
use Time::HiRes qw/gettimeofday tv_interval/;
use Time::HiRes qw/usleep/, qw/time/;

our $VERSION = '3.542';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $plot  = shift;

    my $self = bless { plot => $plot }, $class;

    $self->{gpipe} = $self->get_gnuplot_pipe();

    return $self;
}

sub get_gnuplot_pipe {
    my $self = shift;

    # Incrementally read from / write to scalars.
    # $in is drained as it is fed to cat's stdin,
    # $out accumulates cat's stdout
    # $err accumulates cat's stderr
    # $h is for "harness".
    my @cmd = qw( gnuplot );
    my $read;
    my $write;
    my $plot;
    my $h = start \@cmd, \$write, \$plot, \$read, timeout(10);
    local $| = 1;

    # redirect gnuplot OUTPUT via pipe to STDOUT:
    $write = "set output '|'\n";
    pump $h while length $write;    ## Wait for all input to go

    # store pipe variables in $self:
    my $gpipe->{pipe} = $h;
    $gpipe->{write} = \$write;
    $gpipe->{read}  = \$read;
    $gpipe->{plot}  = \$plot;

    return $gpipe;

}

sub gnuplot {
    my $self = shift;
    my $cmd  = shift;
    my $pipe = $self->{gpipe}->{pipe};
    my $read = $self->{gpipe}->{read};
    $$read = "";
    my $write = $self->{gpipe}->{write};

    $$write = "$cmd\n print 'EOF'\n";
    pump $pipe until $$read =~ /EOF/;    ## Wait for all input to go

    # remove EOF
    chop $$read;                         # \n
    chop $$read;                         # remove F
    chop $$read;                         # remove O
    chop $$read;                         # remove E

    return $$read;

}

sub close_gpipe {
    my $self = shift;
    finish $self->{gpipe}->{pipe} or die "cat returned $?";

    return $self;
}

sub init_gnuplot {
    my $self = shift;

    $self->names2numbers();

    my %plot = %{ $self->{plot} };
    my $gp;

    $gp .= "set title font 'arial,18'\n";
    $gp .= "set xlabel font 'arial,12'\n";
    $gp .= "set ylabel font 'arial,12'\n";
    $gp .= "set y2label font 'arial,12'\n";
    $gp .= "set zlabel font 'arial,12'\n";
    $gp .= "set cblabel font 'arial,12'\n";
    $gp .= "set xtics font 'arial,10'\n";
    $gp .= "set ytics font 'arial,10'\n";
    $gp .= "set ztics font 'arial,10'\n";
    $gp .= "set cbtics font 'arial,8'\n";
    $gp .= "set key font 'arial,8'  at graph 1,1.15\n";
    $gp .= "set title offset -32,0.6\n";

    # store column_names and axis index to gnuplot terminal:

    $self->gnuplot($gp);
    $gp = "";

    if ( defined $self->{plot}->{title} ) {
        $gp .= "set title '$self->{plot}->{title}'\n";
    }

    if ( defined @{ $self->{plot}->{Y2}->{waves} }[0] ) {
        $gp .= "set y2tics\n";
        $gp .= "set ytics nomirror\n";
    }

    if ( defined $self->{plot}->{X}->{range} ) {
        $gp .= "set xrange [$self->{plot}->{X}->{range}]\n";
    }

    if ( defined $self->{plot}->{Y}->{range} ) {
        $gp .= "set yrange [$self->{plot}->{Y}->{range}]\n";
    }

    if ( defined $self->{plot}->{Y2}->{range} ) {
        $gp .= "set y2range [$self->{plot}->{Y2}->{range}]\n";
    }

    if ( defined $self->{plot}->{Z}->{range} ) {
        $gp .= "set zrange [$self->{plot}->{Z}->{range}]\n";
    }

    if ( defined $self->{plot}->{CB}->{range} ) {
        $gp .= "set cbrange [$self->{plot}->{CB}->{range}]\n";
    }

    if ( defined $self->{plot}->{X}->{format} ) {
        $gp .= "set format x '" . $self->{plot}->{X}->{format} . "'\n";
    }

    if ( defined $self->{plot}->{Y}->{format} ) {
        $gp .= "set format y '" . $self->{plot}->{Y}->{format} . "'\n";
    }

    if ( defined $self->{plot}->{Y2}->{format} ) {
        $gp .= "set format y2 '" . $self->{plot}->{Y2}->{format} . "'\n";
    }

    if ( defined $self->{plot}->{Z}->{format} ) {
        $gp .= "set format z '" . $self->{plot}->{Z}->{format} . "'\n";
    }

    if ( defined $self->{plot}->{CB}->{format} ) {
        $gp .= "set format cb '" . $self->{plot}->{CB}->{format} . "'\n";
    }

    if ( $self->{plot}->{X}->{label} eq "" ) {
        $self->{plot}->{X}->{label}
            = @{ $self->{plot}->{X}->{wave} }[0]->{column_name};
        $gp
            .= "set xlabel '@{$self->{plot}->{X}->{wave}}[0]->{column_name}'\n";
    }
    else {
        $gp .= "set xlabel '$self->{plot}->{X}->{label}'\n";
    }

    if ( $self->{plot}->{Y}->{label} eq "" ) {
        if ( defined @{ $self->{plot}->{Y}->{wave} }[0] ) {
            $self->{plot}->{Y}->{label}
                = @{ $self->{plot}->{Y}->{wave} }[0]->{column_name};
            $gp
                .= "set ylabel '@{$self->{plot}->{Y}->{wave}}[0]->{column_name}'\n";
        }
    }
    else {

        $gp .= "set ylabel '$self->{plot}->{Y}->{label}'\n";
    }

    if ( $self->{plot}->{Y2}->{label} eq "" ) {
        if ( defined @{ $self->{plot}->{Y2}->{wave} }[0] ) {
            $self->{plot}->{Y2}->{label}
                = @{ $self->{plot}->{Y2}->{wave} }[0]->{column_name};
            $gp
                .= "set y2label '@{$self->{plot}->{Y2}->{wave}}[0]->{column_name}'\n";
        }
    }
    else {
        $gp .= "set y2label '$self->{plot}->{Y2}->{label}'\n";
    }

    if ( $self->{plot}->{CB}->{label} eq "" ) {
        if ( defined @{ $self->{plot}->{CB}->{wave} }[0] ) {
            $self->{plot}->{CB}->{label}
                = @{ $self->{plot}->{CB}->{wave} }[0]->{column_name};
            $gp
                .= "set cblabel '@{$self->{plot}->{CB}->{wave}}[0]->{column_name}'\n";
        }
    }
    else {
        $gp .= "set cblabel '$self->{plot}->{CB}->{label}'\n";
    }

    if ( $self->{plot}->{Z}->{label} eq "" ) {
        if ( defined @{ $self->{plot}->{Z}->{wave} }[0] ) {
            $self->{plot}->{Z}->{label}
                = @{ $self->{plot}->{Z}->{wave} }[0]->{column_name};
            $gp
                .= "set zlabel '@{$self->{plot}->{Z}->{wave}}[0]->{column_name}'\n";
        }
    }
    else {
        $gp .= "set zlabel '$self->{plot}->{Z}->{label}'\n";
    }

    if ( $self->{plot}->{grid} == 1 ) {
        $gp .= "set grid\n";
    }
    elsif ( $self->{plot}->{grid} == 0 ) {
        $gp .= "unset grid\n";
    }

    if ( not defined $self->{plot}->{X}->{wave} ) {
        warn "Error while plotting data. x-axis is not defined.";
        return;
    }

    if ( not defined $self->{plot}->{Y}->{wave} ) {
        warn "Error while plotting data. y-axis is not defined.";
        return;
    }

    if (    not defined $self->{plot}->{Z}->{wave}
        and not defined $self->{plot}->{CB}->{wave}
        and $self->{plot}->{type} eq 'pm3d' ) {
        warn
            "Error while plotting data. Plot type = pm3d: z-axis and/or cb-axis are not defined.";
        return;
    }

    %{ $self->{plot} } = %plot;

    $self->gnuplot($gp);
    usleep(1e4);

}

sub update_plot {
    my $self = shift;
    $self->{plot} = shift;

}

sub available {
    my $self = shift;

    return $self->gnuplot("");
}

sub plot {
    my $self = shift;

    # if plot mode == pm3d, then change to other start routine:
    if ( $self->{plot}->{type} eq 'Standard' ) {
        $self->plot_standard();
    }
    elsif ( $self->{plot}->{'type'} eq 'Color-Map' ) {
        $self->plot_pm3d();
    }
    elsif ( $self->{plot}->{'type'} eq 'vertical Linetraces' ) {
        $self->plot_pm3d();
        $self->bind_keys();
        $self->plot_linetraces();
        $self->plot_linetraces('vertical');
    }
    elsif ( $self->{plot}->{'type'} eq 'horizontal Linetraces' ) {
        $self->plot_pm3d();
        $self->bind_keys();
        $self->plot_linetraces();
        $self->plot_linetraces('horizontal');
    }

}

sub plot_standard {
    my $self = shift;
    my $gp   = "";

    #-------------------------------------------------------------------------------------------------#
    #---- y1-axis ------------------------------------------------------------------------------------#
    #-------------------------------------------------------------------------------------------------#

    my $x = @{ $self->{plot}->{X}->{wave} }[0]->{column_number};
    $gp = "plot ";
    foreach my $wave ( @{ $self->{plot}->{Y}->{wave} } ) {
        if ( not defined $wave ) {
            next;
        }
        else {
            $gp .= "'$wave->{filename}' ";
            $gp .= "using $x : $wave->{column_number} ";
            $gp
                .= "every $wave->{LineIncrement}:$wave->{BlockIncrement}:$wave->{LineFrom}:$wave->{BlockFrom}:$wave->{LineTo}:$wave->{BlockTo} ";
            $gp .= "axis x1y1 ";
            $gp .= "with $wave->{style} ";
            $gp .= "linecolor rgb '$wave->{color}' ";
            if ( $wave->{style} =~ /line/ ) {
                $gp .= "linewidth $wave->{size} ";
            }
            if ( $wave->{style} =~ /points/ ) {
                $gp .= "pointtype 13 ";
                $gp .= "pointsize $wave->{size} ";
            }
            $gp .= "title '$wave->{label}', ";
        }
    }

    #-------------------------------------------------------------------------------------------------#
    #---- y2-axis ------------------------------------------------------------------------------------#
    #-------------------------------------------------------------------------------------------------#

    foreach my $wave ( @{ $self->{plot}->{Y2}->{wave} } ) {
        if ( not defined $wave ) {
            next;
        }
        else {
            $gp .= "'$wave->{filename}' ";
            $gp .= "using $x:$wave->{column_number} ";
            $gp
                .= "every $wave->{LineIncrement}:$wave->{BlockIncrement}:$wave->{LineFrom}:$wave->{BlockFrom}:$wave->{LineTo}:$wave->{BlockTo} ";
            $gp .= "axis x1y2 ";
            $gp .= "with $wave->{style} ";
            $gp .= "linecolor rgb '$wave->{color}' ";
            if ( $wave->{style} =~ /line/ ) {
                $gp .= "linewidth $wave->{size} ";
            }
            if ( $wave->{style} =~ /points/ ) {
                $gp .= "pointtype 13 ";
                $gp .= "pointsize $wave->{size} ";
            }
            $gp .= "title '$wave->{label}', ";
        }
    }

    # remove last comma and send to gnuplot console:
    chop $gp;
    chop $gp;
    $gp .= "\n";
    $self->gnuplot($gp);

    return $self;

}

sub plot_pm3d {
    my $self = shift;
    my $gp   = "";

    $gp .= "#\n# Set color plot\n";
    $gp .= "set term wxt 0\n";
    $gp .= "set pm3d map corners2color c1\n";
    $gp .= "set view map\n";
    $gp .= "set key font 'arial,8' at graph 1,1.15 \n";

    #$gp.="set palette ".$self->{meta}->plot_palette($plot)."\n";

    $gp .= "set border 4095 front linetype -1 linewidth 1.000\n";
    $gp .= "set style data pm3d\n";
    $gp .= "set style function pm3d\n";
    $gp .= "set ticslevel 0\n";
    $gp .= "set size 0.95,1\n";

    $gp .= "set title offset -23,0.2\n";

    $self->gnuplot($gp);

    $gp = "";

    if ( defined @{ $self->{plot}->{Z}->{wave} }[0] ) {
        $gp = "";
        $gp
            .= "splot '@{$self->{plot}->{Z}->{wave}}[0]->{filename}' using @{$self->{plot}->{X}->{wave}}[0]->{column_number}:@{$self->{plot}->{Y}->{wave}}[0]->{column_number}:@{$self->{plot}->{Z}->{wave}}[0]->{column_number}; \n";
    }
    elsif ( defined @{ $self->{plot}->{CB}->{wave} }[0] ) {
        $gp = "";
        $gp .= "splot '@{$self->{plot}->{CB}->{wave}}[0]->{filename}' ";
        $gp
            .= "using @{$self->{plot}->{X}->{wave}}[0]->{column_number} : @{$self->{plot}->{Y}->{wave}}[0]->{column_number} : @{$self->{plot}->{CB}->{wave}}[0]->{column_number} ";
        $gp
            .= "every $self->{plot}->{LineIncrement}:$self->{plot}->{BlockIncrement}:$self->{plot}->{LineFrom}:$self->{plot}->{BlockFrom}:$self->{plot}->{LineTo}:$self->{plot}->{BlockTo} ";
        $gp .= "ti '' ";
        $gp .= ";\n";
    }

    $self->gnuplot($gp);

    return 1;

}

sub plot_linetraces {
    my $self = shift;
    my $mode = shift;

    my $gp = "";

    if ( not defined $mode ) {
        $gp .= "set term wxt 1 \n";

        $gp .= "LineFrom = 0\n";
        $gp .= "LineTo = 0\n";
        $gp .= "LineIncrement = 1\n";

        $gp .= "BlockFrom = 0\n";
        $gp .= "BlockTo = 0\n";
        $gp .= "BlockIncrement = 1\n";

        $self->gnuplot($gp);

    }

    elsif ( $mode eq "vertical" ) {
        $gp = "";
        $gp .= "set term wxt 1 \n";
        $gp .= "set title 'vertical Linetrace';\n";
        $gp .= "set xlabel '$self->{plot}->{Y}->{label}' ;\n";
        $gp .= "set ylabel '$self->{plot}->{CB}->{label}' ;\n";
        $gp .= "set yrange [$self->{plot}->{CB}->{range}] ;\n";
        $gp
            .= "set obj 1 rect from graph 0, graph 1.11 to graph 1, graph 1.01 front fc rgb '#2F3239'; ";
        $gp
            .= "set label 1 '' at graph 0.5, graph 1.06 front center tc rgb 'white';; ";
        $gp .= "plot '@{$self->{plot}->{CB}->{wave}}[0]->{filename}' ";
        $gp
            .= "using @{$self->{plot}->{Y}->{wave}}[0]->{column_number}:@{$self->{plot}->{CB}->{wave}}[0]->{column_number} ";
        $gp .= "every :BlockIncrement::BlockFrom::BlockTo ";
        $gp .= "with points ";
        $gp .= "linecolor rgb '@{$self->{plot}->{CB}->{wave}}[0]->{color}' ";
        $gp .= "pointtype 13 ";
        $gp .= "pointsize @{$self->{plot}->{CB}->{wave}}[0]->{size} ";
        $gp .= "title '@{$self->{plot}->{CB}->{wave}}[0]->{label}' ;\n";
        $self->gnuplot($gp);
    }
    elsif ( $mode eq "horizontal" ) {
        $gp = "";
        $gp .= "set term wxt 2 \n";
        $gp .= "set title 'horizontal Linetrace';\n";
        $gp .= "set xlabel '$self->{plot}->{X}->{label}' ;\n";
        $gp .= "set ylabel '$self->{plot}->{CB}->{label}' ;\n";
        $gp
            .= "set obj 1 rect from graph 0, graph 1.11 to graph 1, graph 1.01 front fc rgb '#2F3239'; ";
        $gp
            .= "set label 1 '' at graph 0.5, graph 1.06 front center tc rgb 'white';; ";
        $gp .= "plot '@{$self->{plot}->{CB}->{wave}}[0]->{filename}' ";
        $gp
            .= "using @{$self->{plot}->{X}->{wave}}[0]->{column_number}:@{$self->{plot}->{CB}->{wave}}[0]->{column_number} ";
        $gp .= "every LineIncrement::LineFrom::LineTo ";
        $gp .= "with points ";
        $gp .= "linecolor rgb '@{$self->{plot}->{CB}->{wave}}[0]->{color}' ";
        $gp .= "pointtype 13 ";
        $gp .= "pointsize @{$self->{plot}->{CB}->{wave}}[0]->{size} ";
        $gp .= "title '@{$self->{plot}->{CB}->{wave}}[0]->{label}' ;\n";
        $self->gnuplot($gp);
    }

}

sub bind_keys {
    my $self = shift;
    my $gp   = "";

    $gp
        .= "bind 'Right'  'BlockFrom = BlockFrom + BlockIncrement; BlockTo = BlockTo + BlockIncrement; LineFrom = LineFrom + LineIncrement; LineTo = LineTo + LineIncrement; replot;\n' \n";
    $gp
        .= "bind 'Left' 'if ( BlockFrom > 0 ) { BlockFrom = BlockFrom - BlockIncrement; BlockTo = BlockTo - BlockIncrement; if ( LineFrom > 0 ) { LineFrom = LineFrom - LineIncrement; LineTo = LineTo - LineIncrement; } replot;}' \n";

    #$gp .= "bind 'Up' ' replot;\n' \n";
    #$gp .= "bind 'Down' 'if ( LineFrom > 0 ) { LineFrom = LineFrom - LineIncrement; LineTo = LineTo - LineIncrement; replot; }' \n";
    $self->gnuplot($gp);
}

sub save_png {
    my $self     = shift;
    my $filename = shift;
    my $gp;

    if ( not $filename =~ /\.png$/ ) {
        $filename .= ".png";
    }

    # set output terminal to png:
    $gp .= "#\n# Output to file\n";
    $gp .= "set terminal png size 640,480;\n";
    $gp .= "set output '$filename';\n";
    $gp .= "replot;\n";

    $self->gnuplot($gp);

    # set output terminal back to wxt:
    $gp .= "set terminal wxt\n";

    # redirect gnuplot OUTPUT via pipe to STDOUT:
    $gp .= "set output '|'\n";
    $self->gnuplot($gp);

}

sub save_plot {
    my $self = shift;

}

sub names2numbers {
    my $self = shift;

    # replace columnames by columnumbers:
    foreach my $axis (
        $self->{plot}->{X},  $self->{plot}->{Y}, $self->{plot}->{Y2},
        $self->{plot}->{CB}, $self->{plot}->{Z}
        ) {
        foreach my $wave ( @{ $axis->{wave} } ) {
            if (
                exists $self->{plot}->{column_names}{ $wave->{column_name} } )
            {
                $wave->{column_number}
                    = $self->{plot}->{column_names}{ $wave->{column_name} }
                    + 1;
            }
            elsif (
                $wave->{column_name} <= $self->{plot}->{number_of_columns} ) {
                $wave->{column_number} = $wave->{column_name};
            }
        }
    }

}

1;
