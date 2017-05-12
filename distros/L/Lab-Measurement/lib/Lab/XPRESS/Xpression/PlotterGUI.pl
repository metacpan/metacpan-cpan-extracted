package Lab::XPRESS::Xpression::PlotterGUI;

our $VERSION = '3.542';

use strict;
use Time::HiRes qw/gettimeofday tv_interval/;
use Time::HiRes qw/usleep/, qw/time/;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $plot  = shift;
    my %plot  = %$plot;

    my $self = bless { plot => $plot }, $class;

    $self->{gpipe} = $self->get_gnuplot_pipe();

    return $self;
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

sub init_gnuplot {
    my $self = shift;

    $self->names2numbers();

    my %plot = %{ $self->{plot} };
    my $gp;
    my $gpipe = $self->{gpipe};

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

    print $gpipe $gp;
    $gp = "";

    if ( defined $plot{'title'} ) {
        $gp .= "set title '$plot{'title'}'\n";
    }

    if ( defined $plot{'y2'} ) {
        $gp .= "set y2tics\n";
        $gp .= "set ytics nomirror\n";
    }

    if ( defined $plot{X}->{range} ) {
        $gp .= "set xrange [$plot{X}->{range}]\n";
    }

    if ( defined $plot{Y}->{range} ) {
        $gp .= "set yrange [$plot{Y}->{range}]\n";
    }

    if ( defined $plot{Y2}->{range} ) {
        $gp .= "set y2range [$plot{Y2}->{range}]\n";
    }

    if ( defined $plot{Z}->{range} ) {
        $gp .= "set zrange [$plot{Z}->{range}]\n";
    }

    if ( defined $plot{CB}->{range} ) {
        $gp .= "set cbrange [$plot{CB}->{range}]\n";
    }

    if ( defined $plot{X}->{format} ) {
        $gp .= "set format x '" . $plot{X}->{format} . "'\n";
    }

    if ( defined $plot{Y}->{format} ) {
        $gp .= "set format y '" . $plot{Y}->{format} . "'\n";
    }

    if ( defined $plot{Y2}->{format} ) {
        $gp .= "set format y2 '" . $plot{Y2}->{format} . "'\n";
    }

    if ( defined $plot{Z}->{format} ) {
        $gp .= "set format Z '" . $plot{Z}->{format} . "'\n";
    }

    if ( defined $plot{CB}->{format} ) {
        $gp .= "set format cb '" . $plot{CB}->{format} . "'\n";
    }

    if ( defined $plot{X}->{label} ) {
        $gp .= "set xlabel '$plot{X}->{label}'\n";
    }
    else {
        $gp .= "set xlabel '$plot{X}->{column_name}'\n";
    }

    if ( defined $plot{Y}->{label} ) {
        $gp .= "set ylabel '$plot{Y}->{label}'\n";
    }
    else {
        $gp .= "set ylabel '@{$plot{Y}->{wave}}[0]->{column_name}'\n";
    }

    if ( defined $plot{Y2}->{label} ) {
        $gp .= "set y2label '$plot{Y2}->{label}'\n";
    }
    else {
        $gp .= "set y2label '@{$plot{Y2}->{wave}}[0]->{column_name}'\n";
    }

    if ( defined $plot{Z}->{label} ) {
        $gp .= "set zlabel '$plot{Z}->{label}'\n";
    }
    else {
        $gp .= "set zlabel '@{$plot{Z}->{wave}}[0]->{column_name}'\n";
    }

    if ( defined $plot{CB}->{label} ) {
        $gp .= "set cblabel '$plot{CB}->{label}'\n";
    }
    else {
        $gp .= "set cblabel '@{$plot{CB}->{wave}}[0]->{column_name}'\n";
    }

    if ( defined $plot{'grid'} ) {
        $gp .= "set grid $plot{'grid'}\n";
    }

    if ( not defined $plot{X} ) {
        die "Error while plotting data. x-axis is not defined.";
    }

    if ( not defined $plot{Y} ) {
        die "Error while plotting data. y-axis is not defined.";
    }

    if (    not defined $plot{Z}
        and not defined $plot{CB}
        and $plot{type} eq 'pm3d' ) {
        die
            "Error while plotting data. Plot type = pm3d: z-axis and/or cb-axis are not defined.";
    }

    %{ $self->{plot} } = %plot;

    print $gpipe $gp;
    usleep(1e4);
    return $gpipe;

}

sub plot {
    my $self = shift;

    # if plot mode == pm3d, then change to other start routine:
    if ( $self->{plot}->{type} eq 'standard' ) {
        $self->plot_standard();
    }
    elsif ( $self->{plot}->{'type'} eq 'pm3d' ) {
        $self->plot_pm3d();
    }

}

sub plot_standard {
    my $self  = shift;
    my $gp    = "";
    my $gpipe = $self->{gpipe};

    #-------------------------------------------------------------------------------------------------#
    #---- y1-axis ------------------------------------------------------------------------------------#
    #-------------------------------------------------------------------------------------------------#

    my $x = $self->{plot}->{X}->{column_number};
    $gp = "plot ";
    foreach my $wave ( @{ $self->{plot}->{Y}->{wave} } ) {
        if ( not defined $wave ) {
            next;
        }
        else {
            $gp .= "$wave->{filename} ";
            $gp .= "using $x:$wave->{column_number} ";
            $gp .= "axis x1y1 ";
            $gp
                .= "every $wave->{LineIncrement}:$wave->{BlockIncrement}:$wave->{LineFrom}:$wave->{BlockFrom}:$wave->{LineTo}:$wave->{BlockTo} ";
            $gp .= "with $wave->{style} ";
            $gp .= "linecolor $wave->{color} ";
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
            $gp .= "$wave->{filename} ";
            $gp .= "using $x:$wave->{column_number} ";
            $gp .= "axis x1y2 ";
            $gp
                .= "every $wave->{LineIncrement}:$wave->{BlockIncrement}:$wave->{LineFrom}:$wave->{BlockFrom}:$wave->{LineTo}:$wave->{BlockTo} ";
            $gp .= "with $wave->{style} ";
            $gp .= "linecolor $wave->{color} ";
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
    $gp .= "\n";
    my $gpipe = $self->{gpipe};
    print $gpipe $gp;

    return $self;

}

sub plot_pm3d {
    my $self = shift;
    my $gp   = "";

    $gp .= "#\n# Set color plot\n";
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

    my $gpipe = $self->{gpipe};
    print $gpipe $gp;
    $gp = "";

    if ( defined $self->{plot}->{Z} ) {
        $gp = "";

        #		$gp .= "splot '$filename' using $self->{plot}->{X}->{column_number}:@{$self->{plot}->{Y}->{wave}}[0]->{coolumn_number}:@{$self->{pot}->{Z}->{wave}}[0]->{column_number}; \n";
    }
    elsif ( defined $self->{plot}->{'cb-axis'} ) {
        $gp = "";

        #		$gp .= "splot '$filename' using $self->{plot}->{X}->{column_number}:@{$self->{plot}->{Y}->{wave}}[0]->{coolumn_number}:@{$self->{pot}->{CB}->{wave}}[0]->{column_number}; \n";
    }

    print $gpipe $gp;
    return 1;

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
    $gp .= "set terminal png\n";
    $gp .= "set output '$filename'\n";
    $gp .= "replot\n";

    my $gpipe = $self->{gpipe};
    print $gpipe $gp;

    # set output terminal back to wxt:
    $gp .= "set terminal wxt\n";

}

sub save_plot {
    my $self = shift;

}

sub names2numbers {
    my $self = shift;

    # replace columnames by columnumbers:
    if ( exists $self->{plot}->{column_names}{ $self->{plot}->{'x-axis'} } ) {
        $self->{plot}->{'x-axis'}
            = $self->{plot}->{column_names}{ $self->{plot}->{'x-axis'} };
    }

    my $temp = ();
    foreach my $axis ( @{ $self->{plot}->{'y-axis'} } ) {

        if ( exists $self->{plot}->{column_names}{$axis} ) {
            push( @{$temp}, $self->{plot}->{column_names}{$axis} );
        }
        elsif ( $axis <= $self->{plot}->{number_of_columns} ) {
            push( @{$temp}, $axis );
        }
        else {
            print "$axis does not exist\n";
        }
        $self->{plot}->{'y-axis'} = $temp;
    }

    my $temp = ();
    foreach my $axis ( @{ $self->{plot}->{'y2-axis'} } ) {
        if ( exists $self->{plot}->{column_names}{$axis} ) {
            push( @{$temp}, $self->{plot}->{column_names}{$axis} );
        }
        elsif ( $axis <= $self->{plot}->{number_of_columns} ) {
            push( @{$temp}, $axis );
        }
        $self->{plot}->{'y2-axis'} = $temp;
    }

    if ( exists $self->{plot}->{column_names}{ $self->{plot}->{'z-axis'} } ) {
        $self->{plot}->{'z-axis'}
            = $self->{plot}->{column_names}{ $self->{plot}->{'z-axis'} };
    }

    if ( exists $self->{plot}->{column_names}{ $self->{plot}->{'cb-axis'} } )
    {
        $self->{plot}->{'cb-axis'}
            = $self->{plot}->{column_names}{ $self->{plot}->{'cb-axis'} };
    }

}

