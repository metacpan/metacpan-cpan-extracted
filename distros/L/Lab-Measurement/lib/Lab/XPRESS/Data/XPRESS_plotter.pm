package Lab::XPRESS::Data::XPRESS_plotter;
#ABSTRACT: XPRESS plotting module
$Lab::XPRESS::Data::XPRESS_plotter::VERSION = '3.881';
use v5.20;

use strict;
use Time::HiRes qw/gettimeofday tv_interval/;
use Time::HiRes qw/usleep/, qw/time/;

sub new {
    my $proto    = shift;
    my $class    = ref($proto) || $proto;
    my $filename = shift;
    my $plot;

    if ( ref( @_[0] ) eq 'HASH' ) {
        $plot = @_[0];
    }
    else {
        $plot = shift;
    }

    my $self = bless {
        filename => $filename,
        plot     => $plot
    }, $class;

    my %plot = %$plot;

    $self->{PAUSE} = -1
        ; # negative value ==> pause disabled, positive value ==> pause enabled

    if ( $self->{plot}->{refresh} eq 'block' ) {
        $self->{PAUSE} = 1;
    }

    $self->{gpipe} = $self->get_gnuplot_pipe();

    return $self;
}

sub prepair_plot_config_data {
    my $self = shift;

    # prepair y-axis:
    if ( ref( $self->{plot}->{'y-axis'} ) ne 'ARRAY' ) {
        $self->{plot}->{'y-axis'} = [ $self->{plot}->{'y-axis'} ];
    }

    # prepair y2-axis:
    if ( ref( $self->{plot}->{'y2-axis'} ) ne 'ARRAY' ) {
        $self->{plot}->{'y2-axis'} = [ $self->{plot}->{'y2-axis'} ];
    }

    # replace columnames by columnumbers:
    if ( exists $self->{COLUMN_NAMES}{ $self->{plot}->{'x-axis'} } ) {
        $self->{plot}->{'x-axis'}
            = $self->{COLUMN_NAMES}{ $self->{plot}->{'x-axis'} };
    }

    my $temp = ();
    foreach my $axis ( @{ $self->{plot}->{'y-axis'} } ) {
        if ( exists $self->{COLUMN_NAMES}{$axis} ) {
            push( @{$temp}, $self->{COLUMN_NAMES}{$axis} );
        }
        elsif ( $axis <= $self->{NUMBER_OF_COLUMNS} ) {
            push( @{$temp}, $axis );
        }
        else {
            print "$axis does not exist\n";
        }
        $self->{plot}->{'y-axis'} = $temp;
    }

    my $temp = ();
    foreach my $axis ( @{ $self->{plot}->{'y2-axis'} } ) {
        if ( exists $self->{COLUMN_NAMES}{$axis} ) {
            push( @{$temp}, $self->{COLUMN_NAMES}{$axis} );
        }
        elsif ( $axis <= $self->{NUMBER_OF_COLUMNS} ) {
            push( @{$temp}, $axis );
        }
        $self->{plot}->{'y2-axis'} = $temp;
    }

    if ( exists $self->{COLUMN_NAMES}{ $self->{plot}->{'z-axis'} } ) {
        $self->{plot}->{'z-axis'}
            = $self->{COLUMN_NAMES}{ $self->{plot}->{'z-axis'} };
    }

    if ( exists $self->{COLUMN_NAMES}{ $self->{plot}->{'cb-axis'} } ) {
        $self->{plot}->{'cb-axis'}
            = $self->{COLUMN_NAMES}{ $self->{plot}->{'cb-axis'} };
    }

}

sub get_gnuplot_pipe {
    my $self = shift;
    my $gpname;
    if ( $^O =~ /MSWin32/ ) {
        $gpname = "gnuplot";
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

    $self->prepair_plot_config_data();

    my %plot = %{ $self->{plot} };
    my $gp;
    my $gpipe = $self->{gpipe};

    $gp .= "set title font 'arial,18'\n";
    $gp .= "set xlabel font 'arial,12'\n";
    $gp .= "set ylabel font 'arial,12'\n";
    $gp .= "set zlabel font 'arial,12'\n";
    $gp .= "set cblabel font 'arial,12'\n";
    $gp .= "set xtics font 'arial,10'\n";
    $gp .= "set ytics font 'arial,10'\n";
    $gp .= "set ztics font 'arial,10'\n";
    $gp .= "set cbtics font 'arial,7'\n";
    $gp .= "set format cb '%.4e'\n";
    $gp .= "set key font 'arial,8'  at graph 1,1.15\n";
    $gp .= "set title offset -32,0.6\n";

    # store column_names and axis index to gnuplot terminal:
    my $i = 1;
    while ( my ( $column, $index ) = each %{ $self->{COLUMN_NAMES} } ) {
        $column =~ s/\s+/_/g;    #replace all whitespaces by '_'
        $column =~ s/\+/_/;      #replace '+'  by '_'
        $column =~ s/-/_/;       #replace '-'  by '_'
        $column =~ s/\//_/;      #replace '/'  by '_'
        $column =~ s/\*/_/;      #replace '*'  by '_'

        $gp .= "COLUMN_$index = '" . $column . "'; ";
        $i++;
    }
    print $gpipe $gp;
    $gp = "";

    my $i = 1;
    foreach my $y ( @{ $self->{plot}->{'y-axis'} } ) {
        if ( not defined $y ) { next; }
        $gp .= "Y1$i = $y; ";
        $i++;
    }
    print $gpipe $gp;
    $gp = "";

    my $i = 1;
    foreach my $y ( @{ $self->{plot}->{'y2-axis'} } ) {
        if ( not defined $y ) { next; }
        $gp .= "Y2$i = $y; ";
        $i++;
    }
    print $gpipe $gp;
    $gp = "";

    $gp .= "X1 = " . $self->{plot}->{'x-axis'} . "; ";

    # prepair data selection:

    if ( not defined $self->{plot}->{LineIncrement} ) {
        $self->{plot}->{LineIncrement} = 1;
    }
    $gp .= "LineIncrement = " . $self->{plot}->{LineIncrement} . "; ";

    if ( not defined $self->{plot}->{BlockIncrement} ) {
        $self->{plot}->{BlockIncrement} = 1;
    }
    $gp .= "BlockIncrement = " . $self->{plot}->{BlockIncrement} . "; ";

    if ( not defined $self->{plot}->{LineFrom} ) {
        $self->{plot}->{LineFrom} = 0;
    }
    $gp .= "LineFrom = " . $self->{plot}->{LineFrom} . "; ";

    if ( not defined $self->{plot}->{BlockFrom} ) {
        $self->{plot}->{BlockFrom} = 0;
    }
    $gp .= "BlockFrom = " . $self->{plot}->{BlockFrom} . "; ";

    if ( not defined $self->{plot}->{LineTo} ) {
        $self->{plot}->{LineTo} = $self->{LINE_NUM};
    }
    $gp .= "LineTo = " . $self->{plot}->{LineTo} . "; ";

    if ( not defined $self->{plot}->{BlockTo} ) {
        $self->{plot}->{BlockTo} = $self->{BLOCK_NUM};
    }
    $gp .= "BlockTo = " . $self->{plot}->{BlockTo} . "; ";

    $gp .= "BLOCK_NUM = " . $self->{BLOCK_NUM} . "; ";
    $gp .= "LINE_NUM = " . $self->{LINE_NUM} . "; ";

    #$gp .= "show variables;\n";
    print $gpipe $gp;
    $gp = "";

    if ( defined $plot{'title'} ) {
        $gp .= "set title '$plot{'title'}'\n";

        #print $gp."\n";
    }

    if ( defined $plot{'y2-axis'}[0] ) {
        $gp .= "set y2tics\n";
        $gp .= "set ytics nomirror\n";
    }

    if ( defined $plot{'x-min'} or defined $plot{'x-max'} ) {
        $gp .= "set xrange [$plot{'x-min'}:$plot{'x-max'}]\n";

        #print $gp."\n";
    }

    if ( defined $plot{'y-min'} or defined $plot{'y-max'} ) {
        $gp .= "set yrange [$plot{'y-min'}:$plot{'y-max'}]\n";

        #print $gp."\n";
    }

    if ( defined $plot{'z-min'} or defined $plot{'z-max'} ) {
        $gp .= "set zrange [$plot{'z-min'}:$plot{'z-max'}]\n";

        #print $gp."\n";
    }

    if ( defined $plot{'cb-min'} or defined $plot{'cb-max'} ) {
        $gp .= "set cbrange [$plot{'cb-min'}:$plot{'cb-max'}]\n";

        #print $gp."\n";
    }

    if ( defined $plot{'x-format'} ) {
        $gp .= "set format x '" . $plot{'x-format'} . "'\n";
    }

    if ( defined $plot{'y-format'} ) {
        $gp .= "set format y '" . $plot{'y-format'} . "'\n";
    }

    if ( defined $plot{'y2-format'} ) {
        $gp .= "set format y2 '" . $plot{'y2-format'} . "'\n";
    }

    if ( defined $plot{'z-format'} ) {
        $gp .= "set format z '" . $plot{'z-format'} . "'\n";
    }

    if ( defined $plot{'cb-format'} ) {
        $gp .= "set format cb '" . $plot{'cb-format'} . "'\n";
    }

    if ( defined $plot{'x-label'} ) {
        $gp .= "set xlabel '$plot{'x-label'}'\n";
    }
    elsif ( defined $plot{'x-axis'} ) {
        my $i = $plot{'x-axis'};
        $gp .= "set xlabel COLUMN_$i\n";
    }

    if ( defined $plot{'y-label'} ) {
        $gp .= "set ylabel '$plot{'y-label'}'\n";
    }
    elsif ( defined $plot{'y-axis'} ) {
        my $i = $plot{'y-axis'}[0];
        if ( $i ne "" ) { $gp .= "set ylabel COLUMN_$i\n"; };
    }

    if ( defined $plot{'y2-label'} ) {
        $gp .= "set y2label '$plot{'y2-label'}'\n";
    }
    elsif ( defined $plot{'y2-axis'} ) {
        my $i = $plot{'y2-axis'}[0];
        if ( $i ne "" ) { $gp .= "set y2label COLUMN_$i\n"; };
    }

    if ( defined $plot{'z-label'} ) {
        $gp .= "set zlabel '$plot{'z-label'}'\n";
    }
    elsif ( defined $plot{'z-axis'} ) {
        my $i = $plot{'z-axis'};
        $gp .= "set zlabel COLUMN_$i\n";
    }

    if ( defined $plot{'cb-label'} ) {
        $gp .= "set cblabel '$plot{'cb-label'}'\n";
    }
    elsif ( defined $plot{'cb-axis'} ) {
        my $i = $plot{'cb-axis'};
        $gp .= "set cblabel COLUMN_$i\n";
    }

    if ( defined $plot{'grid'} ) {
        $gp .= "set grid $plot{'grid'}\n";
    }

    if ( not defined $plot{'x-axis'} ) {
        die "Error while plotting data. x-axis is not defined.";
    }

    if ( not defined $plot{'y-axis'} ) {
        die "Error while plotting data. y-axis is not defined.";
    }

    if (    not defined $plot{'z-axis'}
        and not defined $plot{'cb-axis'}
        and $plot{'type'} eq 'pm3d' ) {
        die
            "Error while plotting data. Plot type = pm3d: z-axis and/or cb-axis are not defined.";
    }

    %{ $self->{plot} } = %plot;

    print $gpipe $gp;
    usleep(1e4);

    return $gpipe;

}

sub init_gnuplot_bindings {
    my $self = shift;

    $self->bind_s();
    $self->bind_x();
    $self->bind_y();

    if ( defined $self->{plot}->{'z-axis'} ) {
        $self->bind_z();
    }

    if ( defined $self->{plot}->{'cb-axis'} ) {
        $self->bind_c();
    }

}

sub toggle_pause {
    my $self = shift;

    $self->{PAUSE} *= -1;

    return;
}

sub start_plot {
    my $self      = shift;
    my $block_num = shift;
    my $filename  = $self->{filename};
    my $gp;
    my $gpipe = $self->{gpipe};

    print "Starting plot\n";

    # if plot mode == pm3d, then change to other start routine:
    if ( $self->{plot}->{'type'} eq 'pm3d' and $block_num <= 1 ) {
        return 1;
    }
    elsif ( $self->{plot}->{'type'} eq 'pm3d' and $block_num > 1 ) {
        $self->start_plot_pm3d($block_num);
        return 1;
    }

    my $gpipe = $self->{gpipe};
    print $gpipe $gp;

    # create PLOT-command:

    #-------------------------------------------------------------------------------------------------#
    #---- y1-axis ------------------------------------------------------------------------------------#
    #-------------------------------------------------------------------------------------------------#
    my $i = 1;
    $gp = "plot ";
    foreach my $y ( @{ $self->{plot}->{'y-axis'} } ) {
        if ( not defined $y ) {
            next;
        }

        if ( not defined $self->{plot}->{'type'} ) {
            $self->{plot}->{'type'} = 'point';
        }

        if ( $self->{plot}->{'type'}
            =~ /\b(line|lines|LINE|LINES|L|l|ln|LN)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                my $old_blocks    = $block_num - 2;
                my $current_block = $block_num - 1;
                $gp
                    .= "'$filename' using X1:Y1$i every :::0::$old_blocks with lines,";
                $gp .= "'$filename' using X1:Y1$i every :::$current_block"
                    . "::$current_block with lines,";
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using X1:Y1$i with lines,";
            }
        }
        elsif ( $self->{plot}->{'type'}
            =~ /\b(linetrace|LINETRACE|trace|TRACE)\b/ ) {

            #my $parameter = $self->{plot}->{'x-axis'};
            my $block_old
                = ( $block_num - 2 < 0 ) ? $block_num - 1 : $block_num - 2;
            my $block_new
                = ( $block_num - 1 < 0 ) ? $block_num : $block_num - 1;
            $gp .= "'$filename' using X1:Y1$i every :::$block_old"
                . "::$block_old with lines,";
            $gp .= "'$filename' using X1:Y1$i every :::$block_new"
                . "::$block_new with points";
        }
        elsif ( $self->{plot}->{'type'} =~ /\b(single|SINGLE)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                my $current_block = $block_num - 1;
                $gp .= "'$filename' using X1:Y1$i every :::$current_block"
                    . "::$current_block with lines,";
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using  X1:Y1$i with lines,";
            }
        }
        elsif ( $self->{plot}->{'type'} =~ /\b(rainbow|RAINBOW)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                foreach my $block ( 0 .. $block_num - 1 ) {
                    $gp .= "'$filename' using  X1:Y1$i every :::$block"
                        . "::$block with lines lt $block ti 'M_$block',";
                }
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using  X1:Y1$i with lines,";
            }
        }
        elsif ( $self->{plot}->{'type'}
            =~ /\b(points|point|POINTS|POINT|P|p|pt|PT)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                my $old_blocks    = $block_num - 2;
                my $current_block = $block_num - 1;
                $gp
                    .= "'$filename' using  X1:Y1$i every :::0::$old_blocks with lines,";
                $gp .= "'$filename' using  X1:Y1$i every :::$current_block"
                    . "::$current_block with points,";
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using  X1:Y1$i with points,";
            }
        }
        elsif ( $self->{plot}->{'type'} =~ /\b(man|MAN|empty|EMPTY)\b/ ) {
            $gp .= "'$filename',";
        }
        elsif ( $self->{plot}->{'type'} eq 'PlotterGUI' ) {
            $gp .= "'$self->{plot}->{filename}' ";
            $gp .= "using X1:Y1$i axis x1y1 ";
            $gp
                .= "every LineIncrement:BlockIncrement:LineFrom:BlockFrom:LineTo:BlockTo ";
            $gp .= "with @{$self->{plot}->{y_LineStyle}}[$i] ";
            if ( @{ $self->{plot}->{y_LineStyle} }[$i] =~ /lines/ ) {
                $gp .= "linecolor '@{$self->{plot}->{y_LineColor}}[$i]' ";
                $gp .= "linewidth '@{$self->{plot}->{y_LineSize}}[$i]' ";
            }
            if ( @{ $self->{plot}->{y1_style} }[$i] =~ /points/ ) {
                $gp .= "pointtype 13 ";
                $gp .= "pointsize '@{$self->{plot}->{y_LineSize}}[$i]' ";
            }
            $gp .= "ti '@{$self->{plot}->{y_ColumnLabel}}[$i]' ";

        }
        $i++;
    }

    #-------------------------------------------------------------------------------------------------#
    #---- y2-axis ------------------------------------------------------------------------------------#
    #-------------------------------------------------------------------------------------------------#
    my $i = 1;
    foreach my $y ( @{ $self->{plot}->{'y2-axis'} } ) {
        if ( not defined $y ) {
            next;
        }
        if ( $self->{plot}->{'type'}
            =~ /\b(line|lines|LINE|LINES|L|l|ln|LN)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                my $old_blocks    = $block_num - 2;
                my $current_block = $block_num - 1;
                $gp
                    .= "'$filename' using X1:Y2$i axis x1y2 every :::0::$old_blocks with lines,";
                $gp
                    .= "'$filename' using X1:Y2$i axis x1y2 every :::$current_block"
                    . "::$current_block with lines,";
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using X1:Y2$i axis x1y2 with lines,";
            }
        }
        elsif ( $self->{plot}->{'type'}
            =~ /\b(linetrace|LINETRACE|trace|TRACE)\b/ ) {

            #my $parameter = $self->{plot}->{'x-axis'};
            my $block_old
                = ( $block_num - 2 < 0 ) ? $block_num - 1 : $block_num - 2;
            my $block_new
                = ( $block_num - 1 < 0 ) ? $block_num : $block_num - 1;
            $gp .= "'$filename' using X1:Y1$i axis x1y2 every :::$block_old"
                . "::$block_old with lines,";
            $gp .= "'$filename' using X1:Y1$i axis x1y2 every :::$block_new"
                . "::$block_new with points";
        }
        elsif ( $self->{plot}->{'type'} =~ /\b(single|SINGLE)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                my $current_block = $block_num - 1;
                $gp
                    .= "'$filename' using X1:Y2$i axis x1y2 every :::$current_block"
                    . "::$current_block with lines,";
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using  X1:Y2$i axis x1y2 with lines,";
            }
        }
        elsif ( $self->{plot}->{'type'} =~ /\b(rainbow|RAINBOW)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                foreach my $block ( 0 .. $block_num - 1 ) {
                    $gp
                        .= "'$filename' using  X1:Y2$i axis x1y2 every :::$block"
                        . "::$block with lines lt $block ti 'M_$block',";
                }
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using X1:Y2$i axis x1y2 with lines,";
            }
        }
        elsif ( $self->{plot}->{'type'}
            =~ /\b(points|point|POINTS|POINT|P|p|pt|PT)\b/ ) {
            if ( $block_num > 1 ) {

                #my $parameter = $self->{plot}->{'x-axis'};
                my $old_blocks    = $block_num - 2;
                my $current_block = $block_num - 1;
                $gp
                    .= "'$filename' using X1:Y2$i axis x1y2 every :::0::$old_blocks with lines,";
                $gp
                    .= "'$filename' using X1:Y2$i axis x1y2 every :::$current_block"
                    . "::$current_block with points,";
            }
            else {
                #my $parameter = $self->{plot}->{'x-axis'};
                $gp .= "'$filename' using X1:Y2$i axis x1y2 with points,";
            }
        }
        elsif ( $self->{plot}->{'type'} =~ /\b(man|MAN|empty|EMPTY)\b/ ) {
            $gp .= "'$filename',";
        }
        $i++;
    }
    chop $gp;
    $gp .= "\n";
    my $gpipe = $self->{gpipe};
    print $gpipe $gp;

    $self->{plot}->{started} = 'started';

    $self->bind_s();

    return $self;

}

sub start_plot_pm3d {
    my $self      = shift;
    my $block_num = shift;

    my $filename = $self->{filename};
    my $gp;

    my $gpipe = $self->get_gnuplot_pipe();

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

    if ( ref( $self->{plot}->{'x-axis'} ) eq 'ARRAY' ) {
        $self->{plot}->{'x-axis'} = $self->{plot}->{'x-axis'}[0];
    }
    if ( ref( $self->{plot}->{'y-axis'} ) eq 'ARRAY' ) {
        $self->{plot}->{'y-axis'} = $self->{plot}->{'y-axis'}[0];
    }
    if ( ref( $self->{plot}->{'z-axis'} ) eq 'ARRAY' ) {
        $self->{plot}->{'z-axis'} = $self->{plot}->{'z-axis'}[0];
    }
    if ( ref( $self->{plot}->{'cb-axis'} ) eq 'ARRAY' ) {
        $self->{plot}->{'cb-axis'} = $self->{plot}->{'cb-axis'}[0];
    }

    $gp .= "X1 = " . $self->{plot}->{'x-axis'} . ";";
    $gp .= "Y11 = " . $self->{plot}->{'y-axis'} . ";";
    if ( defined $self->{plot}->{'z-axis'} ) {
        $gp .= "Z = " . $self->{plot}->{'z-axis'} . ";";
    }
    if ( defined $self->{plot}->{'cb-axis'} ) {
        $gp .= "CB = " . $self->{plot}->{'cb-axis'} . ";";
    }

    $gp .= "\n";
    my $gpipe = $self->{gpipe};
    print $gpipe $gp;
    $gp = "";

    if ( defined $self->{plot}->{'z-axis'} ) {
        $gp = "";
        $gp .= "splot '$filename' using X1:Y11:Z ; \n";
    }
    elsif ( defined $self->{plot}->{'cb-axis'} ) {
        $gp = "";
        $gp .= "splot '$filename' using X1:Y11:CB ; \n";
    }

    #print $gp."\n";
    print $gpipe $gp;
    $self->{plot}->{started} = 1;

    return 1;

}

sub _stop_live_plot {
    my $self = shift;

    return unless ( defined $self->{gpipe} );

    close $self->{gpipe};
    undef $self->{plot};
}

sub replot {
    my $self = shift;

    if ( $self->{PAUSE} > 0 ) {
        return 1;
    }
    else {
        my $gpipe = $self->{gpipe};
        print $gpipe "replot\n";
        return 1;
    }
}

sub gnuplot_cmd {
    my $self = shift;
    my $cmd  = shift;
    my $gp;
    my $gpipe = $self->{gpipe};

    $gp = "$cmd\n";

    print $gpipe $gp;
    return $self;

}

sub bind_x {
    my $self = shift;
    my $gp;

    # covert hash of columns to an array:
    my @columns = ();

    while ( my ( $column, $index ) = each %{ $self->{COLUMN_NAMES} } ) {
        $column =~ s/\s+/_/g;    #replace all whitespaces by '_'
        $column =~ s/\+/_/;      #replace '+'  by '_'
        $column =~ s/-/_/;       #replace '-'  by '_'
        $column =~ s/\//_/;      #replace '/'  by '_'
        $column =~ s/\*/_/;      #replace '*'  by '_'

        $columns[$index] = $column;
    }
    shift @columns;

    # foreach my $k ( keys %{$self->{COLUMN}})
    # {
    # push (@columns, $k);
    # }

    my $gpipe = $self->{gpipe};
    usleep(1e4);
    print $gpipe $gp;

    $gp = "";

    # bind x key:
    $gp .= 'bind x "';

    # draw background:
    $gp
        .= "set obj 1001 rect from graph 0, graph 0 to graph 1, graph 1 front fc rgb 'grey' fs transparent solid 0.8; ";
    $gp .= "set label 1001 '';\\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # draw 'buttons' for each column:
    my $m = 0;
    my $n = 0;
    foreach my $column (@columns) {
        $gp
            .= "set obj 100"
            . ( $m * 4 + $n + 2 )
            . " rect from graph (0.05+$n*(0.23)), graph ((1-0.05)-$m*(0.12)) to graph (0.05+$n*(0.23)+0.21), graph ((1-0.05)-$m*(0.12) - 0.1) front fc rgb '#2F3239'; ";
        $gp
            .= "set label 100"
            . ( $m * 4 + $n + 2 ) . " '"
            . $column
            . "' at graph (0.05+$n*(0.23) + 0.1), graph ((1-0.05)-$m*(0.12)-0.05) front center tc rgb 'white'; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;
        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "replot; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # check for mouseclicks:
    $m = 0;
    $n = 0;
    $gp .= "RANGE_X = GPVAL_X_MAX - GPVAL_X_MIN; ";
    $gp .= "RANGE_Y = GPVAL_Y_MAX - GPVAL_Y_MIN; ";
    $gp .= "LOOP = 1; ";
    $gp .= "while(LOOP){";
    $gp .= "pause mouse 'Click Mouse';";
    $gp .= "if (exists('MOUSE_X') && exists('MOUSE_Y')) {\\\n";
    print $gpipe $gp;
    usleep(2e4);
    $gp = "";

    foreach my $column (@columns) {
        $gp
            .= "if (( MOUSE_X < ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 + 0.21 )
            . " )) && ( MOUSE_X > ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 )
            . " )) && ( MOUSE_Y < ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 )
            . " )) && ( MOUSE_Y > ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 - 0.1 )
            . " ))) {";
        $gp .= "LOOP = 0;";
        $gp .= "X1 = " . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "set xlabel COLUMN_" . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "show variables; ";
        $gp .= "}; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;

        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "}";
    $gp .= "}; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    foreach ( 1 .. ( my $length = @columns + 1 ) ) {
        $gp .= "unset obj 100" . $_ . "; ";
        $gp .= "unset label 100" . $_ . "; ";
    }
    $gp .= "replot; ";

    $gp .= "\n";

    print $gpipe $gp;
    usleep(5e5);
    print $gpipe "\n";

}

sub bind_y {
    my $self = shift;
    my $gp;

    # covert hash of columns to an array:
    my @columns = ();
    while ( my ( $column, $index ) = each %{ $self->{COLUMN_NAMES} } ) {
        $column =~ s/\s+/_/g;    #replace all whitespaces by '_'
        $column =~ s/\+/_/;      #replace '+'  by '_'
        $column =~ s/-/_/;       #replace '-'  by '_'
        $column =~ s/\//_/;      #replace '/'  by '_'
        $column =~ s/\*/_/;      #replace '*'  by '_'

        $columns[$index] = $column;
    }
    shift @columns;

    my $gpipe = $self->{gpipe};
    usleep(1e4);
    print $gpipe $gp;

    $gp = "";

    # bind x key:
    $gp .= 'bind y "';

    # draw background:
    $gp
        .= "set obj 2001 rect from graph 0, graph 0 to graph 1, graph 1 front fc rgb 'grey' fs transparent solid 0.8; ";
    $gp .= "set label 2001 '';\\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # draw 'buttons' for each column:
    my $m = 0;
    my $n = 0;
    foreach my $column (@columns) {
        $gp
            .= "set obj 200"
            . ( $m * 4 + $n + 2 )
            . " rect from graph (0.05+$n*(0.23)), graph ((1-0.05)-$m*(0.12)) to graph (0.05+$n*(0.23)+0.21), graph ((1-0.05)-$m*(0.12) - 0.1) front fc rgb '#2F3239'; ";
        $gp
            .= "set label 200"
            . ( $m * 4 + $n + 2 ) . " '"
            . $column
            . "' at graph (0.05+$n*(0.23) + 0.1), graph ((1-0.05)-$m*(0.12)-0.05) front center tc rgb 'white'; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;
        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "replot; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # check for mouseclicks:
    $m = 0;
    $n = 0;
    $gp .= "RANGE_X = GPVAL_X_MAX - GPVAL_X_MIN; ";
    $gp .= "RANGE_Y = GPVAL_Y_MAX - GPVAL_Y_MIN; ";
    $gp .= "LOOP = 1; ";
    $gp .= "while(LOOP){";
    $gp .= "pause mouse 'Click Mouse';";
    $gp .= "if (exists('MOUSE_X') && exists('MOUSE_Y')) {\\\n";
    print $gpipe $gp;
    usleep(2e4);
    $gp = "";

    foreach my $column (@columns) {
        $gp
            .= "if (( MOUSE_X < ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 + 0.21 )
            . " )) && ( MOUSE_X > ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 )
            . " )) && ( MOUSE_Y < ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 )
            . " )) && ( MOUSE_Y > ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 - 0.1 )
            . " ))) {";
        $gp .= "LOOP = 0;";
        $gp .= "Y11 = " . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "set ylabel COLUMN_" . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "show variables; ";
        $gp .= "}; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;

        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "}";
    $gp .= "}; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    foreach ( 1 .. ( my $length = @columns + 1 ) ) {
        $gp .= "unset obj 200" . $_ . "; ";
        $gp .= "unset label 200" . $_ . "; ";
    }
    $gp .= "replot; ";

    $gp .= "\n";

    print $gpipe $gp;
    usleep(5e5);
    print $gpipe "\n";

}

sub bind_z {
    my $self = shift;
    my $gp;

    # covert hash of columns to an array:
    my @columns = ();
    while ( my ( $column, $index ) = each %{ $self->{COLUMN_NAMES} } ) {
        $column =~ s/\s+/_/g;    #replace all whitespaces by '_'
        $column =~ s/\+/_/;      #replace '+'  by '_'
        $column =~ s/-/_/;       #replace '-'  by '_'
        $column =~ s/\//_/;      #replace '/'  by '_'
        $column =~ s/\*/_/;      #replace '*'  by '_'

        $columns[$index] = $column;
    }
    shift @columns;

    my $gpipe = $self->{gpipe};
    usleep(1e4);
    print $gpipe $gp;

    $gp = "";

    # bind x key:
    $gp .= 'bind z "';

    # draw background:
    $gp
        .= "set obj 3001 rect from graph 0, graph 0 to graph 1, graph 1 front fc rgb 'grey' fs transparent solid 0.8; ";
    $gp .= "set label 3001 '';\\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # draw 'buttons' for each column:
    my $m = 0;
    my $n = 0;
    foreach my $column (@columns) {
        $gp
            .= "set obj 300"
            . ( $m * 4 + $n + 2 )
            . " rect from graph (0.05+$n*(0.23)), graph ((1-0.05)-$m*(0.12)) to graph (0.05+$n*(0.23)+0.21), graph ((1-0.05)-$m*(0.12) - 0.1) front fc rgb '#2F3239'; ";
        $gp
            .= "set label 300"
            . ( $m * 4 + $n + 2 ) . " '"
            . $column
            . "' at graph (0.05+$n*(0.23) + 0.1), graph ((1-0.05)-$m*(0.12)-0.05) front center tc rgb 'white'; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;
        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "replot; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # check for mouseclicks:
    $m = 0;
    $n = 0;
    $gp .= "RANGE_X = GPVAL_X_MAX - GPVAL_X_MIN; ";
    $gp .= "RANGE_Y = GPVAL_Y_MAX - GPVAL_Y_MIN; ";
    $gp .= "LOOP = 1; ";
    $gp .= "while(LOOP){";
    $gp .= "pause mouse 'Click Mouse';";
    $gp .= "if (exists('MOUSE_X') && exists('MOUSE_Y')) {\\\n";
    print $gpipe $gp;
    usleep(2e4);
    $gp = "";

    foreach my $column (@columns) {
        $gp
            .= "if (( MOUSE_X < ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 + 0.21 )
            . " )) && ( MOUSE_X > ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 )
            . " )) && ( MOUSE_Y < ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 )
            . " )) && ( MOUSE_Y > ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 - 0.1 )
            . " ))) {";
        $gp .= "LOOP = 0;";
        $gp .= "Z = " . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "set zlabel COLUMN_" . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "show variables; ";
        $gp .= "}; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;

        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "}";
    $gp .= "}; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    foreach ( 1 .. ( my $length = @columns + 1 ) ) {
        $gp .= "unset obj 300" . $_ . "; ";
        $gp .= "unset label 300" . $_ . "; ";
    }
    $gp .= "replot; ";

    $gp .= "\n";

    print $gpipe $gp;
    usleep(5e5);
    print $gpipe "\n";

}

sub bind_c {
    my $self = shift;
    my $gp;

    # covert hash of columns to an array:
    my @columns = ();
    while ( my ( $column, $index ) = each %{ $self->{COLUMN_NAMES} } ) {
        $column =~ s/\s+/_/g;    #replace all whitespaces by '_'
        $column =~ s/\+/_/;      #replace '+'  by '_'
        $column =~ s/-/_/;       #replace '-'  by '_'
        $column =~ s/\//_/;      #replace '/'  by '_'
        $column =~ s/\*/_/;      #replace '*'  by '_'

        $columns[$index] = $column;
    }
    shift @columns;

    my $gpipe = $self->{gpipe};
    usleep(1e4);
    print $gpipe $gp;

    $gp = "";

    # bind x key:
    $gp .= 'bind c "';

    # draw background:
    $gp
        .= "set obj 4001 rect from graph 0, graph 0 to graph 1, graph 1 front fc rgb 'grey' fs transparent solid 0.8; ";
    $gp .= "set label 4001 '';\\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # draw 'buttons' for each column:
    my $m = 0;
    my $n = 0;
    foreach my $column (@columns) {
        $gp
            .= "set obj 400"
            . ( $m * 4 + $n + 2 )
            . " rect from graph (0.05+$n*(0.23)), graph ((1-0.05)-$m*(0.12)) to graph (0.05+$n*(0.23)+0.21), graph ((1-0.05)-$m*(0.12) - 0.1) front fc rgb '#2F3239'; ";
        $gp
            .= "set label 400"
            . ( $m * 4 + $n + 2 ) . " '"
            . $column
            . "' at graph (0.05+$n*(0.23) + 0.1), graph ((1-0.05)-$m*(0.12)-0.05) front center tc rgb 'white'; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;
        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "replot; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    # check for mouseclicks:
    $m = 0;
    $n = 0;
    $gp .= "RANGE_X = GPVAL_X_MAX - GPVAL_X_MIN; ";
    $gp .= "RANGE_Y = GPVAL_Y_MAX - GPVAL_Y_MIN; ";
    $gp .= "LOOP = 1; ";
    $gp .= "while(LOOP){";
    $gp .= "pause mouse 'Click Mouse';";
    $gp .= "if (exists('MOUSE_X') && exists('MOUSE_Y')) {\\\n";
    print $gpipe $gp;
    usleep(2e4);
    $gp = "";

    foreach my $column (@columns) {
        $gp
            .= "if (( MOUSE_X < ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 + 0.21 )
            . " )) && ( MOUSE_X > ( GPVAL_X_MIN + RANGE_X * "
            . ( 0.05 + $n * 0.23 )
            . " )) && ( MOUSE_Y < ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 )
            . " )) && ( MOUSE_Y > ( GPVAL_Y_MIN + RANGE_Y * "
            . ( ( 1 - 0.05 ) - $m * 0.12 - 0.1 )
            . " ))) {";
        $gp .= "LOOP = 0;";
        $gp .= "CB = " . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "set cblabel COLUMN_" . ( $m * 4 + $n + 1 ) . "; ";
        $gp .= "show variables; ";
        $gp .= "}; \\\n";
        print $gpipe $gp;
        usleep(2e4);
        $gp = "";
        $n++;

        if ( $n >= 4 ) {
            $n = 0;
            $m++;
        }
    }
    $gp .= "}";
    $gp .= "}; \\\n";
    print $gpipe $gp;
    usleep(1e4);
    $gp = "";

    foreach ( 1 .. ( my $length = @columns + 1 ) ) {
        $gp .= "unset obj 400" . $_ . "; ";
        $gp .= "unset label 400" . $_ . "; ";
    }
    $gp .= "replot; ";

    $gp .= "\n";

    print $gpipe $gp;
    usleep(5e5);
    print $gpipe "\n";

}

sub bind_s {
    my $self = shift;
    my $gp;

    # split directory/filname ..
    if ( $self->{FILENAME} =~ /(.+)(\/|\/\/|\\|\\\\)(.+)\b/ ) {
        my $directory         = $1;
        my $filename          = $3;
        my $filenameextension = ".dat";
        if ( $filename =~ /(.+)(\..+)\b/ ) {
            $filename          = $1;
            $filenameextension = $2;
        }

        #print "$directory $filename $filenameextension\n";

        # create directory if it doesn't exist:
        if ( not -d $directory ) {
            warn
                "directory given by  $self->{FILENAME} doesn't exist. Create directory $directory";
            mkdir $directory;
        }

        # look for existing files:
        opendir( DIR, $directory );
        my @files     = readdir(DIR);
        my $max_index = 0;
        foreach my $file (@files) {
            my $temp_filename = $filename;
            $temp_filename =~ s/\(/\\\(/g;
            $temp_filename =~ s/\)/\\\)/g;
            if ( $file =~ /($temp_filename)_(\d+)(\.*)\b/ ) {
                if ( $2 > $max_index ) {
                    $max_index = $2;
                }
            }
        }
        closedir(DIR);
        $max_index++;

        # create filename for saving plot as eps-file:
        my $filename = $self->{FILENAME};
        $filename =~ /(.+)\.(.+)\b/;
        $filename = sprintf( "%s_%02d", $1, $self->{ID} + 1 );

        $gp .= "FILENAME = '" . $filename . "'; ";
        $gp .= "FILE_INDEX = " . $max_index . "; \n";
        my $gpipe = $self->{gpipe};
        print $gpipe $gp;
        $gp = "";

        $gp .= "bind s \"";
        $gp .= "print 'save...'; ";
        $gp .= "set term png size 1024,600; ";
        $gp .= "set output sprintf('%s_%02d.png', FILENAME, FILE_INDEX); ";
        $gp .= "replot; ";
        $gp .= "set term wxt; ";
        $gp .= "FILE_INDEX = FILE_INDEX + 1; ";
        $gp .= "\"; \n";
        my $gpipe = $self->{gpipe};
        print $gpipe $gp;
        usleep(1e5);
        print $gpipe "\n";
    }
}

sub save_plot {
    my $self     = shift;
    my $type     = shift;
    my $filename = shift;

    if ( not defined $type ) {
        $type = 'png';
    }

    if ( not defined $filename ) {
        $filename = "undefined.$type";
    }

    if ( $type eq 'eps' ) {
        $self->_save_eps($filename);
    }
    elsif ( $type eq 'png' ) {
        $self->_save_png($filename);
    }
    else {
        warn
            "in function 'save_plot': file type $type not defined. Possible types are 'png' and 'eps'.";
    }

    return $self;

}

sub _save_eps {
    my $self     = shift;
    my $filename = shift;
    $filename .= '.eps';
    my %plot = $self->{plot};

    #my %plot = %$plot;
    my $gp;

    # set output to eps:
    $gp .= "#\n# Output to file\n";
    $gp .= "set terminal postscript eps color size 13,9.75\n";
    $gp .= "set terminal postscript eps color enhanced\n";
    $gp .= "set output '$filename'\n";
    $gp .= "replot\n";

    my $gpipe = $self->{gpipe};
    print $gpipe $gp;

    return 1;

}

sub _save_png {
    my $self     = shift;
    my $filename = shift;
    $filename .= '.png';
    my %plot = $self->{plot};

    #my %plot = %$plot;
    my $gp;

    # set output to eps:
    $gp .= "#\n# Output to file\n";
    $gp .= "set terminal png\n";
    $gp .= "set output '$filename'\n";
    $gp .= "replot\n";

    my $gpipe = $self->{gpipe};
    print $gpipe $gp;

    return 1;

}

sub datazone {
    my $self   = shift;
    my $x_min  = shift;
    my $x_max  = shift;
    my $y_min  = shift;
    my $y_max  = shift;
    my $left   = shift;
    my $center = shift;
    my $right  = shift;

    my $gpipe = $self->{gpipe};

    # info bar:
    my $gp = "set style rect fc lt -1 fs solid 0.15 noborder\n";
    $gp
        .= "set object 1 rect from "
        . $x_min . ","
        . ( $y_min + 0.03 * ( $y_max - $y_min ) ) . " to "
        . $x_max . ","
        . ( $y_min + 0.1 * ( $y_max - $y_min ) )
        . " behind\n";

    $gp
        .= "set label 1 at "
        . ( $x_min + 0.025 * ( $x_max - $x_min ) ) . ","
        . ( $y_min + 0.06 *  ( $y_max - $y_min ) )
        . " left\n";
    $gp .= "set label 1 '$left'\n";

    $gp
        .= "set label 3 at "
        . ( $x_min + 0.5 *  ( $x_max - $x_min ) ) . ","
        . ( $y_min + 0.06 * ( $y_max - $y_min ) )
        . " center\n";
    $gp .= "set label 3 '$center'\n";

    $gp
        .= "set label 2 at "
        . ( $x_min + 0.975 * ( $x_max - $x_min ) ) . ","
        . ( $y_min + 0.06 *  ( $y_max - $y_min ) )
        . " right\n";
    $gp .= "set label 2 '$right'\n";

    print $gpipe $gp;

    return $self;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Data::XPRESS_plotter - XPRESS plotting module

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
