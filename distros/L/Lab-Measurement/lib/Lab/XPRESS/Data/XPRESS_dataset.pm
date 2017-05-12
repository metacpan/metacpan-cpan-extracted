package Lab::XPRESS::Data::XPRESS_dataset;

our $VERSION = '3.542';

use strict;
use Math::Trig;
use Statistics::LineFit;
use Math::Interpolate
    qw(derivatives constant_interpolate linear_interpolate robust_interpolate);
use Statistics::Descriptive;
use Time::HiRes qw/usleep/, qw/time/;
use Lab::XPRESS::Data::XPRESS_logger;
our $pi = 3.14159265358979323846264338327950288419716939937510582097;

sub new {

    my $proto    = shift;
    my $class    = ref($proto) || $proto;
    my $filename = shift;
    my $self     = {};
    bless( $self, $class );

    if ( not defined $filename ) {
        $self->{FILENAME} = $filename;
        $self->{HEADER}   = "";
        $self->{COLUMNS}  = 0;
        @{ $self->{COL_NAMES} } = ();
        $self->{BLOCKS} = 0;
        @{ $self->{DATA} } = ();
        return $self;
    }

    $self->{FILENAME} = $filename;
    $self->read_file($filename);

    # for debugging:
    # $self->print();

    if ( not @{ $self->{DATA}[0][0] }[0] ) {
        warn "WARNING: No Data in File $filename.";
        return -1;
    }
    elsif ( not @{ $self->{COL_NAMES} } ) {
        warn "WARNING: No ColumnNames defined in $filename.";
        return -1;
    }
    elsif ( ( my $len_COLUMNS = @{ $self->{COL_NAMES} } )
        != ( my $len_DATA = @{ $self->{DATA} } ) ) {
        warn
            "WARNING: Number of column names not equal to the number of data columns!";
        return -1;
    }

    return $self;

}

sub read_file {
    my $self     = shift;
    my $filename = shift;
    my $block    = 0;

    print "read $filename --> ";
    open FILE, "<", $filename or die $!;
    while (<FILE>) {

        #print $_;
        if ( $_ =~ m/^(#HEADER#|#CONFIG#)/ ) {
            $self->{HEADER} .= $_;

            #print LOG $_;
            #print $_;
        }
        elsif ( $_ =~ m/^#COLUMNS#/ ) {
            chomp $_;
            @{ $self->{COL_NAMES} } = split( /\t/, $_ );
            shift @{ $self->{COL_NAMES} };

            #print LOG $_;
            #print $_;
        }
        elsif ( $_ =~ m/^#/ ) {
            $self->{COMMENT} .= $_;
        }
        elsif ( $_ =~ m/^([^0-9a-z]+)?\n$/ ) {
            if ( @{ $self->{DATA}[0][0] }[0] ) {
                $block++;
            }
        }
        else {
            my $i = 0;
            chomp $_;
            my @data = split( /\t/, $_ );
            foreach my $data (@data) {

                # add data only if it is a number or a '?'
                if ( $data
                    =~ /(.*[^0-9-+.])?([+-]?([0-9]+)(\.[0-9]+)?(e|E)?([+-]?[0-9]+)?)([^0-9].*)?|\?/
                    ) {
                    push( @{ $self->{DATA}[$i][$block] }, $data );

                    #print "@{$self->{DATA}[$i]}[-1]\t";
                }
                $i++;
            }
        }
    }
    if ( not defined $self->{DATA}[0][$block][0] ) {
        $block--;
    }
    chomp $self->{HEADER};
    $self->{BLOCKS}  = $block + 1;
    $self->{COLUMNS} = @{ $self->{DATA} };
    $self->{LINES}   = @{ $self->{DATA}[0][0] };
    close FILE;

    return $self;

}

sub print {
    my $self   = shift;
    my $mode   = shift;
    my $column = shift;

    # HEADER:
    if ( not defined $mode or $mode =~ m/^(HEADER|header|H|h)$/ ) {
        print "\n\n---------\n#HEADER#\n---------\n";
        print $self->{HEADER};
        print
            "\n################################################################################\n\n";
    }

    # COMMENT:
    if ( not defined $mode or $mode =~ m/^(COMMENT|comment)$/ ) {
        print "\n\n---------\n#COMMENT#\n---------\n";
        print $self->{COMMENT};
        print
            "\n################################################################################\n\n";
    }

    # COLUMNS:
    if ( not defined $mode or $mode =~ m/^(COLUMNS|columns|C|c)$/ ) {
        print "\n\n---------\n#COLUMNS#\n---------\n";
        if ( ref( $self->{COL_NAMES} ) eq "ARRAY" ) {
            foreach my $item ( @{ $self->{COL_NAMES} } ) {
                print $item. "\n";
            }
        }
        else {
            print $self->{COL_NAMES} . "\n";
        }
        print
            "\n################################################################################\n\n";
    }

    # DATA:
    if ( not defined $mode or $mode =~ m/^(DATA|data|D|d)$/ ) {
        my @temp_columns = @{ $self->{COL_NAMES} };
        if ( ref( $self->{DATA} ) eq "ARRAY" ) {
            if ( ref( @{ $self->{DATA} }[0] ) eq "ARRAY" ) {
                if ( ref( @{ $self->{DATA}[0] }[0] ) eq "ARRAY" ) {
                    my $col = 0;
                    foreach my $c ( @{ $self->{DATA} } ) {
                        if ( not defined $column
                            or @{ $self->{COL_NAMES} }[$col] eq $column ) {
                            print shift(@temp_columns) . ":\n";
                            foreach my $block ( @{$c} ) {
                                print " --- \n";
                                foreach my $item ( @{$block} ) {
                                    print $item. "\t";
                                }
                                print "\n";
                            }
                            print "\n";
                        }
                        else {
                            shift(@temp_columns);
                        }
                        $col++;
                    }
                }
                else {
                    print shift(@temp_columns) . ":\n";
                    foreach my $block ( @{ $self->{DATA} } ) {
                        print " --- \n";
                        foreach my $item ( @{$block} ) {
                            print $item. "\t";
                        }
                        print "\n";
                    }
                    print "\n";
                }
            }
            else {
                foreach my $item ( @{ $self->{DATA} } ) {
                    print $item. "\t";
                }
                print "\n";
            }
        }
        else {
            print shift(@temp_columns) . ":\n";
            print $self->{DATA} . "\n";
        }
    }

    # empty print:
    return;

}

sub LOG {
    my $self         = shift;
    my $filenamebase = shift;
    my $DataStyle    = shift;

    if ( not defined $DataStyle ) {
        $DataStyle = 'Gnuplot';
    }

    #$filenamebase = "modified_datasets".$filenamebase;
    # create file-handle:
    $self->{logger} = new Lab::XPRESS::Data::XPRESS_logger($filenamebase);

    # Log HEADER:
    if ( $DataStyle eq 'Gnuplot' ) {
        $self->{logger}->LOG( $self->{HEADER} );
        $self->{logger}->LOG( $self->{COMMENT} );
        unshift( @{ $self->{COL_NAMES} }, "#COLUMNS#" );
        $self->{logger}->LOG( $self->{COL_NAMES} );
        shift( @{ $self->{COL_NAMES} } );
    }
    elsif ( $DataStyle eq 'Origin' ) {
        $self->{logger}->LOG( $self->{COL_NAMES} );
    }

    # Log data:
    for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {

        # log data row by row:
        my @datablock;
        foreach my $column ( @{ $self->{DATA} } ) {
            push( @datablock, @{$column}[$block] );
        }
        $self->{logger}->LOG( \@datablock );

        # start new block:
        $self->{logger}->LOG("");
    }
    $self->{logger}->close_file();
    return 1;
}

sub plot {
    my $self = shift;
    my $plot = shift;

    if ( exists $self->{COLUMN}{ $plot->{'x-axis'} } ) {
        $plot->{'x-axis'} = $self->{COLUMN}{ $plot->{'x-axis'} };
    }
    if ( exists $self->{COLUMN}{ $plot->{'y-axis'} } ) {
        $plot->{'y-axis'} = $self->{COLUMN}{ $plot->{'y-axis'} };
    }
    if ( exists $self->{COLUMN}{ $plot->{'y2-axis'} } ) {
        $plot->{'y2-axis'} = $self->{COLUMN}{ $plot->{'y2-axis'} };
    }
    if ( exists $self->{COLUMN}{ $plot->{'Z-axis'} } ) {
        $plot->{'z-axis'} = $self->{COLUMN}{ $plot->{'z-axis'} };
    }
    if ( exists $self->{COLUMN}{ $plot->{'cb-axis'} } ) {
        $plot->{'cb-axis'} = $self->{COLUMN}{ $plot->{'cb-axis'} };
    }

    $self->{plotter} = new Lab::Data::SG_plotter( $self->{FILENAME}, $plot );
    $self->{plotter}->start_plot( $self->{BLOCKS} );
    $self->{plotter}->save_plot( 'png', $self->{FILENAME} );

}

sub get_colnum {
    my $self   = shift;
    my $column = shift;

    # case 0:
    if ( $column =~ /^([0-9]+)$/ ) {
        return $1;
    }

    # case col[0]:
    if ( $column =~ m/^col[\(\[\{]([0-9]+)[\)\)\}](\.)*/ ) {
        return $1;
    }

    # case col[v_sd]:
    if ( $column =~ m/^col[\(\[\{]([\.]+)[\)\)\}](\.)*/ ) {
        for ( my $i = 0; $i < ( my $len = @{ $self->{COL_NAMES} } ); $i++ ) {
            if ( @{ $self->{COL_NAMES} }[$i] eq $1 ) {
                return $i;
            }
        }
    }

    # case v_sd:
    for ( my $i = 0; $i < ( my $len = @{ $self->{COL_NAMES} } ); $i++ ) {
        if ( @{ $self->{COL_NAMES} }[$i] eq $column ) {
            return $i;
        }
    }

    # case column not found:
    return -1;

}

sub get_colname {
    my $self   = shift;
    my $column = shift;

    return @{ $self->{COL_NAMES} }[$column];
}

sub rename_col {
    my $self     = shift;
    my $old_name = shift;
    my $new_name = shift;

    foreach ( @{ $self->{COL_NAMES} } ) {
        if ( $_ eq $old_name ) {
            $_ = $new_name;
        }
    }

    return $self;
}

sub extract_col {
    my $self = shift;
    my $column;
    my @column;

    if ( ( my $len = @_ ) > 1 ) {
        @column = @_;
    }
    else {
        $column = shift;
        push( @column, $column );
    }

    my $temp_self = $self->copy();

    my $data = new Lab::XPRESS::Data::XPRESS_dataset();

    $data->{HEADER} = $temp_self->{HEADER};
    $data->{BLOCKS} = $temp_self->{BLOCKS};
    foreach my $column (@column) {
        $column = $temp_self->get_colnum($column);
        if ( $column != -1 ) {
            push(
                @{ $data->{COL_NAMES} },
                @{ $temp_self->{COL_NAMES} }[$column]
            );
            push( @{ $data->{DATA} }, @{ $temp_self->{DATA} }[$column] );
        }
        else {
            # create new column if requested column not found:
            push( @{ $data->{COL_NAMES} }, $column );
            push( @{ $data->{DATA} },      @{ $temp_self->{DATA} }[0] );
            $data->insert_c($column);
        }
    }

    $data->{COLUMNS} = @{ $data->{DATA} };

    return $data;
}

sub extract_block {
    my $self = shift;
    my $block;
    my @block;

    if ( ( my $len = @_ ) > 1 ) {
        @block = @_;
    }
    else {
        $block = shift;
        push( @block, $block );
    }

    my $temp_self = $self->copy();

    my $data = new Lab::XPRESS::Data::XPRESS_dataset();

    $data->{HEADER}    = $temp_self->{HEADER};
    $data->{COLUMNS}   = $temp_self->{COLUMNS};
    $data->{COL_NAMES} = $temp_self->{COL_NAMES};
    $data->{BLOCKS}    = @block - 1;

    foreach my $block (@block) {
        if ( $block <= $temp_self->{BLOCKS} and $block >= 0 ) {
            foreach my $column ( 0 .. $temp_self->{COLUMNS} ) {
                push(
                    @{ $data->{DATA}[$column] },
                    @{ $temp_self->{DATA}[$column] }[$block]
                );
            }
        }
        else {
            warn "requested BLOCK $block not found within dataset.";
        }
    }

    return $data;
}

sub extract_line {
    my $self = shift;
    my $row;
    my @rows;

    if ( ( my $len = @_ ) > 1 ) {
        @rows = @_;
    }
    else {
        $row = shift;
        push( @rows, $row );
    }

    my $temp_self = $self->copy();

    my $data = new Lab::XPRESS::Data::XPRESS_dataset();

    $data->{HEADER}    = $temp_self->{HEADER};
    $data->{COLUMNS}   = $temp_self->{COLUMNS};
    $data->{COL_NAMES} = $temp_self->{COL_NAMES};
    $data->{BLOCKS}    = $temp_self->{BLOCKS};

    foreach my $row (@rows) {
        foreach my $column ( 0 .. $temp_self->{COLUMNS} ) {
            foreach my $block ( 0 .. $temp_self->{BLOCKS} ) {
                push(
                    @{ $data->{DATA}[$column][$block] },
                    @{ $temp_self->{DATA}[$column][$block] }[$row]
                );
            }
        }
    }

    return $data;

}

sub col_old {
    my $self = shift;
    my $column;
    my @column;

    if ( ( my $len = @_ ) > 1 ) {
        @column = @_;
    }
    else {
        undef(@column);
        $column = shift;
    }

    my $temp_self = $self->copy();

    my $data = new Lab::XPRESS::Data::XPRESS_dataset();
    if (@column) {
        $data->{HEADER}  = $temp_self->{HEADER};
        $data->{COLUMNS} = $temp_self->{COLUMNS};
        foreach my $column (@column) {
            if ( $column =~ /^-?[0-9]+$/ ) {
                push(
                    @{ $data->{COL_NAMES} },
                    @{ $temp_self->{COL_NAMES} }[$column]
                );
                push( @{ $data->{DATA} }, @{ $temp_self->{DATA} }[$column] );
            }
            else {
                my $flag_column_found = 0;
                for (
                    my $i = 0;
                    $i < ( my $len = @{ $temp_self->{COL_NAMES} } );
                    $i++
                    ) {
                    if ( @{ $temp_self->{COL_NAMES} }[$i] eq $column ) {
                        push(
                            @{ $data->{COL_NAMES} },
                            @{ $temp_self->{COL_NAMES} }[$i]
                        );
                        push(
                            @{ $data->{DATA} },
                            @{ $temp_self->{DATA} }[$i]
                        );
                        $flag_column_found = 1;
                        last;
                    }
                }

                # create new column if requested column not found:
                if ( $flag_column_found == 0 ) {
                    push( @{ $data->{COL_NAMES} }, $column );
                    push( @{ $data->{DATA} }, @{ $temp_self->{DATA} }[0] );
                    $data->insert_c($column);
                }
            }
        }
    }
    else {
        if ( $column =~ /^-?[0-9]+$/ ) {
            $data->{HEADER} = $temp_self->{HEADER};
            push(
                @{ $data->{COL_NAMES} },
                @{ $temp_self->{COL_NAMES} }[$column]
            );
            $data->{COLUMNS} = $temp_self->{COLUMNS};
            push( @{ $data->{DATA} }, @{ $temp_self->{DATA} }[$column] );
        }
        else {
            my $flag_column_found = 0;
            for (
                my $i = 0;
                $i < ( my $len = @{ $temp_self->{COL_NAMES} } );
                $i++
                ) {
                if ( @{ $temp_self->{COL_NAMES} }[$i] eq $column ) {
                    $data->{HEADER} = $temp_self->{HEADER};
                    push(
                        @{ $data->{COL_NAMES} },
                        @{ $temp_self->{COL_NAMES} }[$i]
                    );
                    push( @{ $data->{DATA} }, @{ $temp_self->{DATA} }[$i] );
                    $flag_column_found = 1;
                    last;
                }
            }

            # create new column if requested column not found:
            if ( $flag_column_found == 0 ) {
                push( @{ $data->{COL_NAMES} }, $column );
                push( @{ $data->{DATA} },      @{ $temp_self->{DATA} }[0] );
                $data->insert_c($column);
            }
        }
    }

    $data->{COLUMNS} = @{ $data->{DATA} };
    return $data;
}

sub add {
    my $self   = shift;
    my $value  = shift;
    my $column = shift;
    my $result;

    $result = $self->copy();
    @{ $result->{DATA} }       = ();
    @{ $result->{EXP_PARTS} }  = ();
    @{ $result->{EVAL_PARTS} } = ();

    if ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $value = $value->copy();
        map { $_ = $_ . " + " . @{ $value->{COL_NAMES} }[0]; }
            ( @{ $result->{COL_NAMES} } );
        for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0][$block] },
                map { $_ + shift( @{ $value->{DATA}[0][$block] } ); }
                    ( @{ $self->{DATA}[$column][$block] } )
            );
        }

    }
    else {
        map { $_ = $_ . " + " . "$value"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $block = 0;
            $block < ( my $len_b = @{ $self->{DATA}[$column] } );
            $block++
            ) {
            my $self_temp = $self->copy();
            push(
                @{ $result->{DATA}[$column][$block] },
                map { $_ + $value }
                    ( @{ $self_temp->{DATA}[$column][$block] } )
            );
        }
    }

    return $result;

}

sub subtract {
    my $self   = shift;
    my $value  = shift;
    my $column = shift;
    my $result;

    $column = $self->get_colnum($column);

    $result = $self->copy();
    @{ $result->{DATA} }       = ();
    @{ $result->{EXP_PARTS} }  = ();
    @{ $result->{EVAL_PARTS} } = ();

    if ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {

        # check for expressions:
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $value = $value->copy();

        # create new columname:
        map { $_ = $_ . " - " . @{ $value->{COL_NAMES} }[0]; }
            ( @{ $result->{COL_NAMES} } );

        # calculate:
        for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0][$block] },
                map { $_ - shift( @{ $value->{DATA}[0][$block] } ); }
                    ( @{ $self->{DATA}[$column][$block] } )
            );
        }

    }
    elsif ( ref($value) eq 'ARRAY' ) {
        $result = $result->extract_col($column);

        # calculate:
        for ( my $block = 0; $block < ( my $len_b = @{$value} ); $block++ ) {
            push(
                @{ $result->{DATA}[0][$block] },
                map { $_ - $value->[$block]; }
                    ( @{ $self->{DATA}[$column][$block] } )
            );
        }
    }
    else {
        # create new columname:
        map { $_ = $_ . " - " . "$value"; } ( @{ $result->{COL_NAMES} } );

        # calculate:
        for (
            my $block = 0;
            $block < ( my $len_b = @{ $self->{DATA}[$column] } );
            $block++
            ) {
            my $self_temp = $self->copy();
            push(
                @{ $result->{DATA}[$column][$block] },
                map { $_ - $value }
                    ( @{ $self_temp->{DATA}[$column][$block] } )
            );
        }
    }

    return $result;

}

sub multiply {
    my $self   = shift;
    my $value  = shift;
    my $column = shift;
    my $result;

    $result = $self->copy();
    @{ $result->{DATA} }       = ();
    @{ $result->{EXP_PARTS} }  = ();
    @{ $result->{EVAL_PARTS} } = ();

    if ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $value = $value->copy();
        map { $_ = $_ . " * " . @{ $value->{COL_NAMES} }[0]; }
            ( @{ $result->{COL_NAMES} } );
        for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0][$block] },
                map { $_ * shift( @{ $value->{DATA}[0][$block] } ); }
                    ( @{ $self->{DATA}[$column][$block] } )
            );
        }

    }
    else {
        map { $_ = $_ . " * " . "$value"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $block = 0;
            $block < ( my $len_b = @{ $self->{DATA}[$column] } );
            $block++
            ) {
            my $self_temp = $self->copy();
            push(
                @{ $result->{DATA}[$column][$block] },
                map { $_ * $value }
                    ( @{ $self_temp->{DATA}[$column][$block] } )
            );
        }
    }

    return $result;

}

sub divide {
    my $self   = shift;
    my $value  = shift;
    my $column = shift;
    my $result;

    $result = $self->copy();
    @{ $result->{DATA} }       = ();
    @{ $result->{EXP_PARTS} }  = ();
    @{ $result->{EVAL_PARTS} } = ();

    my $temp;
    if ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $value = $value->copy();
        map { $_ = $_ . " / " . @{ $value->{COL_NAMES} }[0]; }
            ( @{ $result->{COL_NAMES} } );
        for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {

            #print "value\n";
            #$value->print();
            my @temp = @{ $value->{DATA}[0][$block] };
            push(
                @{ $result->{DATA}[0][$block] },
                map { ( ( $temp = shift(@temp) ) != 0 ) ? $_ / $temp : '?' }
                    ( @{ $self->{DATA}[$column][$block] } )
            );

            #push (@{$result->{DATA}[0][$block]}, map { $_ / shift(@{$value->{DATA}[0][$block]});  } (@{$self->{DATA}[$column][$block]}));
        }

    }
    else {
        map { $_ = $_ . " / " . "$value"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $block = 0;
            $block < ( my $len_b = @{ $self->{DATA}[$column] } );
            $block++
            ) {
            my $self_temp = $self->copy();
            push(
                @{ $result->{DATA}[$column][$block] },
                map { $_ / $value }
                    ( @{ $self_temp->{DATA}[$column][$block] } )
            );
        }
    }

    return $result;

}

sub sin {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map { sin( ( $_ / 180 ) * $pi ) } ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "sin(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { sin( ( $_ / 180 ) * $pi ) }
                        ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result = sin( ( $value / 180 ) * $pi );
    }

    return $result;
}

sub cos {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map { cos( ( $_ / 180 ) * $pi ) } ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "cos(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { cos( ( $_ / 180 ) * $pi ) }
                        ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result = cos( ( $value / 180 ) * $pi );
    }

    return $result;
}

sub tan {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map {
                    (           ( _modulo( $_, 90 ) == 0 )
                            and ( _modulo( $_, 180 ) != 0 ) )
                        ? 'nan'
                        : sin( ( $_ / 180 ) * $pi ) /
                        cos( ( $_ / 180 ) * $pi )
                } ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "tan(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map {
                        (           ( _modulo( $_, 90 ) == 0 )
                                and ( _modulo( $_, 180 ) != 0 ) )
                            ? 'nan'
                            : sin( ( $_ / 180 ) * $pi ) /
                            cos( ( $_ / 180 ) * $pi )
                    } ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result
            = (     ( _modulo( $value, 90 ) == 0 )
                and ( _modulo( $value, 180 ) != 0 ) )
            ? 'nan'
            : sin( ( $value / 180 ) * $pi ) / cos( ( $value / 180 ) * $pi );
    }

    return $result;
}

sub abs {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push( @{ $result->{DATA}[0] }, map { abs($_) } ( @{$value} ) );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "abs(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { abs($_) } ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result = abs($value);
    }

    return $result;

}

sub sgn {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map {
                    if    ( $_ > 0 )  { $_ = 1; }
                    elsif ( $_ == 0 ) { $_ = 0; }
                    elsif ( $_ < 0 )  { $_ = -1; }
                } ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "sgn(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map {
                        if    ( $_ > 0 )  { $_ = 1; }
                        elsif ( $_ == 0 ) { $_ = 0; }
                        elsif ( $_ < 0 )  { $_ = -1; }
                    } ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        if    ( $value > 0 )  { $result = 1; }
        elsif ( $value == 0 ) { $result = 0; }
        elsif ( $value < 0 )  { $result = -1; }
    }

    return $result;
}

sub exp {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push( @{ $result->{DATA}[0] }, map { exp($_) } ( @{$value} ) );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "exp(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { exp($_) } ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result = exp($value);
    }

    return $result;
}

sub ln {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map { ( $_ >= 0 ) ? log($_) / log( exp(1) ) : 'nan' }
                    ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "ln(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { ( $_ >= 0 ) ? log($_) / log( exp(1) ) : 'nan' }
                        ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        ( $value >= 0 ) ? $result = log($value) / log( exp(1) ) : 'nan';
    }

    return $result;
}

sub log {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map { ( $_ >= 0 ) ? log($_) / log(10) : 'nan' } ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "log10(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { ( $_ >= 0 ) ? log($_) / log(10) : 'nan' }
                        ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        ( $value >= 0 ) ? $result = log($value) / log(10) : 'nan';
    }

    return $result;
}

sub sqrt {
    my $self  = shift;
    my $value = shift;
    my $result;

    my $value = $self->expression($value);

    if ( ref($value) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push(
                @{ $result->{DATA}[0] },
                map { ( $_ >= 0 ) ? sqrt($_) : 'nan' } ( @{$value} )
            );
        }
    }
    elsif ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $result = $value->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "sqrt(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $value->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $value->{BLOCKS}; $block++ ) {
                my @temp = @{ $value->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { ( $_ >= 0 ) ? sqrt($_) : 'nan' }
                        ( @{ $value->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result = ( $value >= 0 ) ? sqrt($value) : 'nan';
    }

    return $result;
}

sub yEx {
    my $self = shift;
    my $y    = shift;
    my $x    = shift;
    my $result;

    my $y = $self->expression($y);

    if ( ref($y) eq 'ARRAY' ) {
        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            push( @{ $result->{DATA}[0] }, map { $_**$x } ( @{$y} ) );
        }
    }
    elsif ( ref($y) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $y->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $y = @{ $y->{EVAL_PARTS} }[$1];
        }
        $result = $y->copy();
        @{ $result->{DATA} }       = ();
        @{ $result->{EXP_PARTS} }  = ();
        @{ $result->{EVAL_PARTS} } = ();
        map { $_ = "yEx(" . $_ . ")"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $column = 0;
            $column < ( my $len_c = @{ $y->{DATA} } );
            $column++
            ) {
            for ( my $block = 0; $block < $y->{BLOCKS}; $block++ ) {
                my @temp = @{ $y->{DATA}[$column][$block] };
                push(
                    @{ $result->{DATA}[$column][$block] },
                    map { $_**$x } ( @{ $y->{DATA}[$column][$block] } )
                );
            }
        }
    }
    else {
        $result = $y**$x;
    }

    return $result;

}

sub modulo {
    my $self   = shift;
    my $value  = shift;
    my $column = shift;
    my $result;

    $result = $self->copy();
    @{ $result->{DATA} }       = ();
    @{ $result->{EXP_PARTS} }  = ();
    @{ $result->{EVAL_PARTS} } = ();

    if ( ref($value) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( $value->{EXPRESSION} =~ /EP([0-9]+)/ ) {
            $value = @{ $value->{EVAL_PARTS} }[$1];
        }
        $value = $value->copy();
        map { $_ = $_ . " % " . @{ $value->{COL_NAMES} }[0]; }
            ( @{ $result->{COL_NAMES} } );
        for (
            my $block = 0;
            $block < ( my $len_b = @{ $value->{DATA}[0] } );
            $block++
            ) {
            push(
                @{ $result->{DATA}[0][$block] },
                map {
                    _modulo( $_, shift( @{ $value->{DATA}[0][$block] } ) );
                } ( @{ $self->{DATA}[$column][$block] } )
            );
        }

    }
    else {
        map { $_ = $_ . " + " . "$value"; } ( @{ $result->{COL_NAMES} } );
        for (
            my $block = 0;
            $block < ( my $len_b = @{ $self->{DATA}[$column] } );
            $block++
            ) {
            my $self_temp = $self->copy();
            push(
                @{ $result->{DATA}[$column][$block] },
                map { _modulo( $_, $value ) }
                    ( @{ $self_temp->{DATA}[$column][$block] } )
            );
        }
    }

    return $result;

}

sub lineFit {
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    my @result;

    $x = $self->get_colnum($x);
    $y = $self->get_colnum($y);
    if ( $x == -1 or $y == -1 ) {
        warn "WARNING: in sub lineFit(x,y) invalid data given.";
    }

    my $lineFit = Statistics::LineFit->new();

    for (
        my $block = 0;
        $block < ( my $len_b = @{ $self->{DATA}[$x] } );
        $block++
        ) {
        $lineFit->setData(
            $self->{DATA}[$x][$block],
            $self->{DATA}[$y][$block]
        );
        my ( $intercept, $slope ) = $lineFit->coefficients();
        push( @result, $intercept );
    }

    return @result;
}

# sub copy {
# my $self = shift;

# if ( UNIVERSAL::isa( $self, 'SCALAR' ) ) {
# my $temp = deepcopy($$self);
# return \$temp;
# }
# elsif ( UNIVERSAL::isa( $self, 'HASH' ) )
# {
# my $copy = new Lab::XPRESS::Data::XPRESS_dataset ();
# foreach my $key ( keys %$self )
# {
# if ( !defined( $self->{$key} ) || !ref( $self->{$key} ) )
# {
# $copy->{$key} = $self->{$key};
# }
# else
# {
# $copy->{$key} = copy( $self->{$key} );
# }
# }
# return $copy;
# }
# elsif ( UNIVERSAL::isa( $self, 'ARRAY' ) ) {
# my $temp_array = [];
# foreach my $array_val (@$self) {
# if ( !defined($array_val) || !ref($array_val) ) {
# push ( @$temp_array, $array_val );
# }
# else {
# push ( @$temp_array, copy($array_val) );
# }
# }
# return $temp_array;
# }
# # ?? I am uncertain about this one
# elsif ( UNIVERSAL::isa( $self, 'REF' ) ) {
# my $temp = deepcopy($$self);
# return \$temp;
# }

# # I guess that it is either CODE, GLOB or LVALUE
# else {
# return $self;
# }

# }

sub copy {
    my $self = shift;

    my $copy = new Lab::XPRESS::Data::XPRESS_dataset();

    while ( my ( $key, $value ) = each %{$self} ) {
        if ( ref($value) eq "ARRAY" or ref($value) eq "HASH" ) {
            $copy->{$key} = deep_copy($value);
        }
        else {
            $copy->{$key} = $value;
        }
    }

    return $copy;

}

sub deep_copy {

    # if not defined then return it
    return undef if $#_ < 0 || !defined( $_[0] );

    # if not a reference then return the parameter
    return $_[0] if !ref( $_[0] );
    my $obj = shift;
    if ( UNIVERSAL::isa( $obj, 'SCALAR' ) ) {
        my $temp = deepcopy($$obj);
        return \$temp;
    }
    elsif ( UNIVERSAL::isa( $obj, 'HASH' ) ) {
        my $temp_hash = {};
        foreach my $key ( keys %$obj ) {
            if ( !defined( $obj->{$key} ) || !ref( $obj->{$key} ) ) {
                $temp_hash->{$key} = $obj->{$key};
            }
            else {
                $temp_hash->{$key} = deep_copy( $obj->{$key} );
            }
        }
        return $temp_hash;
    }
    elsif ( UNIVERSAL::isa( $obj, 'ARRAY' ) ) {
        my $temp_array = [];
        foreach my $array_val (@$obj) {
            if ( !defined($array_val) || !ref($array_val) ) {
                push( @$temp_array, $array_val );
            }
            else {
                push( @$temp_array, deep_copy($array_val) );
            }
        }
        return $temp_array;
    }

    # ?? I am uncertain about this one
    elsif ( UNIVERSAL::isa( $obj, 'REF' ) ) {
        my $temp = deepcopy($$obj);
        return \$temp;
    }

    # I guess that it is either CODE, GLOB or LVALUE
    else {
        return $obj;
    }
}

sub set {
    my $self   = shift;
    my $data   = shift;
    my $column = shift;
    my @column;
    my $blocks = shift;
    my @blocks;

    if ( not defined $blocks ) {
        @blocks = ( 0 .. $self->{BLOCKS} - 1 );
    }
    elsif ( ref($blocks) eq 'ARRAY' ) {
        @blocks = @$blocks;
    }
    else {
        $blocks[0] = $blocks;
    }

    if ( not defined $column ) {
        warn 'WARNING: in sub set no column index given. Ignor set column. ';
        return $self;
    }
    elsif ( ref($column) eq 'ARRAY' ) {
        @column = @$column;
    }
    else {
        $column[0] = $column;
    }

    my $i = 0;
    foreach $column (@column) {
        $column[$i] = $self->get_colnum($column);
        $i++;
    }

    my $i = 0;
    foreach my $column (@column) {
        if ( ref($data) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
            my $len_d;
            my $len_c;
            if (    ( $len_d = @{ $data->{COL_NAMES} } ) > 1
                and ( $len_c = @column )
                == ( $len_d = @{ $data->{COL_NAMES} } ) ) {
                @{ $self->{COL_NAMES} }[$column]
                    = @{ $data->{COL_NAMES} }[$i];
                map {
                    $self->{DATA}[$column][$_]
                        = shift( @{ $data->{DATA}[$i] } );
                } (@blocks);
                $i++;
            }
            elsif ( ( $len_d = @{ $data->{COL_NAMES} } ) == 1
                and ( $len_c = @column ) >= 1 ) {
                @{ $self->{COL_NAMES} }[$column]
                    = @{ $data->{COL_NAMES} }[$i];
                my @data_temp = @{ $data->{DATA}[$i] };
                map { $self->{DATA}[$column][$_] = shift(@data_temp); }
                    (@blocks);
            }
            else {
                warn
                    "WARNING: in sub set  given set-columns $len_d != given data-columns $len_c. Ignor set column. ";
                return $self;
            }
        }
        elsif ( ref($data) eq 'ARRAY' ) {
            if ( ref( @{$data}[0] ) eq 'ARRAY' ) {

                my @data_temp = @{$data};
                map { $self->{DATA}[$column][$_] = shift(@data_temp) }
                    (@blocks);
                return $self;
            }
            elsif ( ( my $length_data = @{$data} )
                == ( my $lenngth_blocks = @blocks ) ) {
                foreach my $block (@blocks) {
                    my $i = 0;
                    foreach ( @{ $self->{DATA}[0][$block] } ) {
                        $self->{DATA}[$column][$block][$i] = @{$data}[$block];
                        $i++;
                    }
                }
                return $self;
            }
            else {
                map { $self->{DATA}[$column][$_] = $data } (@blocks);
                return $self;
            }
        }
        else {
            map {
                @{ $self->{DATA}[$column][$_] }
                    = map { $_ = $data }
                    ( @{ $self->{DATA}[$column][$_] } )
            } (@blocks);
            return $self;
        }
    }

    return $self->extract_col($column);

}

sub delete_c {
    my $self   = shift;
    my $column = shift;

    my $deleted_column = $self->extract_col($column);
    splice @{ $self->{DATA} },      $column, 1;
    splice @{ $self->{COL_NAMES} }, $column, 1;
    $self->{COLUMNS} -= 1;
    return $deleted_column;

}

sub insert_c {
    my $self         = shift;
    my $col_name     = shift;
    my $col_position = shift;

    if ( not defined $col_name ) {

        # append Column with col_name = 'NN'
        warn
            "WARNING: sub 'insert_c' has been called with no arguments. Appending an empty column with the columnname 'NN'.";
        my @dummy_array;
        push( @{ $self->{DATA} }, \@dummy_array );
        map { my @dummy_array; push( @{ $self->{DATA}[-1] }, \@dummy_array ) }
            ( ( 0 .. $self->{BLOCKS} - 1 ) );
        push( @{ $self->{COL_NAMES} }, 'NN' );
    }
    elsif ( not defined $col_position and $col_name =~ /^[-]?[0-9]+$/ ) {

        # insert Column befor col = $col_name with col_name = 'NN'
        $col_position = $col_name;
        $col_name     = 'NN';

        #warn "WARNING: sub 'insert_c' has been called without columnname argument. Insert empty column with the columnname 'NN'.";
        if ( $col_position < 0 ) {
            my $len = @{ $self->{DATA} };
            $col_position += $len + 1;
            if ( $col_position < 0 ) {
                $col_position = 0;
            }
        }
        my @dummy_col;
        map { my @dummy_array; push( @dummy_col, \@dummy_array ) }
            ( ( 0 .. $self->{BLOCKS} - 1 ) );
        splice @{ $self->{DATA} },      $col_position, 0, \@dummy_col;
        splice @{ $self->{COL_NAMES} }, $col_position, 0, $col_name;
    }
    elsif ( not defined $col_position ) {

        # append Column with col_name = '$col_name'
        my @dummy_array;
        push( @{ $self->{DATA} }, \@dummy_array );
        map { my @dummy_array; push( @{ $self->{DATA}[-1] }, \@dummy_array ) }
            ( ( 0 .. $self->{BLOCKS} - 1 ) );
        push( @{ $self->{COL_NAMES} }, "$col_name" );
    }
    else {
        # insert Column befor col = $col_name with col_name = '$col_name'
        if ( $col_position < 0 ) {
            my $len = @{ $self->{DATA} };
            $col_position += $len + 1;
            if ( $col_position < 0 ) {
                $col_position = 0;
            }
        }
        my @dummy_col;
        map { my @dummy_array; push( @dummy_col, \@dummy_array ) }
            ( ( 0 .. $self->{BLOCKS} - 1 ) );
        splice @{ $self->{DATA} },      $col_position, 0, \@dummy_col;
        splice @{ $self->{COL_NAMES} }, $col_position, 0, $col_name;
    }

    $self->{COLUMNS} += 1;
    return $self;

}

sub move_c {
    my $self         = shift;
    my $col          = shift;
    my $new_position = shift;

    if ( not defined $new_position ) {
        warn
            "WARNING: in sub 'move_c' no argument for new_position given. ignore move_c command.";
    }
    else {
        # find col_index for col_name:
        my $index = 0;
        foreach ( @{ $self->{COL_NAMES} } ) {
            if ( $_ eq $col ) {
                $col = $index;
                last;
            }
            $index++;
        }

        # move col:
        if ( $col =~ /^[0-9]+$/ ) {

            # create new sequence of coumns:
            my $len          = @{ $self->{DATA} };
            my @new_sequence = ( 0 .. $len - 1 );
            splice @new_sequence, $col, 1;
            splice @new_sequence, $new_position, 0, $col;

            # get columns in the new order:
            my $self_temp = $self->extract_col(@new_sequence);

            # apply to $self:
            $self->{DATA}      = $self_temp->{DATA};
            $self->{COL_NAMES} = $self_temp->{COL_NAMES};
        }
        else {
            warn
                "WARNING: in sub 'move_c' column ($col) not found; ignore move_c command.";
        }
    }

    return $self;
}

sub sort {
    my $self      = shift;
    my $direction = shift
        ; # direction can be '+', '-' for  sorting 'rising' or 'falling' respectivly
    my @sort_cols = @_;

    if ( not $direction =~ /^[+-]$/ ) {
        unshift( @sort_cols, $direction );
        $direction = '+';
    }

    # find col_index for col_name:
    map { $_ = $self->get_colnum($_); } (@sort_cols);

    # convert column/block structure to row/block structure:
    my @temp;
    foreach my $block ( ( 0 .. $self->{BLOCKS} - 1 ) ) {
        foreach my $column ( 0 .. $self->{COLUMNS} ) {
            my $index = 0;
            map { push( @{ $temp[$block][$index] }, $_ ); $index++; }
                ( @{ $self->{DATA}[$column][$block] } );
        }
    }

    #print $temp[36]."\n";
    # sort rows:
    my @sorted_data;
    foreach my $block ( ( 0 .. $self->{BLOCKS} - 1 ) ) {

        # create sort string:
        my $sort;
        if ( $direction =~ /^[+]$/ ) {
            map { $sort .= "\$a->[" . $_ . "] <=> \$b->[" . $_ . "]||" }
                @sort_cols;
        }
        else {
            map { $sort .= "\$b->[" . $_ . "] <=> \$a->[" . $_ . "]||" }
                @sort_cols;
        }
        chop $sort;
        chop $sort;

        # sort:
        my @stemp = sort { eval $sort } ( @{ $temp[$block] } );
        push( @sorted_data, \@stemp );
    }

    #map {map {print $_."\t";} (@{$_}); print "\n";}(@sorted_data);
    #map {map {print $_."\t";} (@{$_}); print "\n";}(@{$sorted_data[0]});

    # convert row/block structure to column/block structure:
    my @temp;
    foreach my $block ( ( 0 .. $self->{BLOCKS} - 1 ) ) {
        my $rows = @{ $sorted_data[$block] };
        foreach my $row ( 0 .. $rows - 1 ) {
            my $column = 0;
            map { push( @{ $temp[$column][$block] }, $_ ); $column++; }
                ( @{ $sorted_data[$block][$row] } );
        }
    }

    # apply to $self:
    $self->{DATA} = \@temp;

    return $self;

}

sub block_sort {
    my $self      = shift;
    my $direction = shift
        ; # direction can be '+', '-' for  sorting 'rising' or 'falling' respectivly
    my @sort_cols = @_;

    if ( not $direction =~ /^[+-]$/ ) {
        unshift( @sort_cols, $direction );
        $direction = '+';
    }

    # find col_index for col_name:
    map { $_ = $self->get_colnum($_); } (@sort_cols);

    # check if the 'sort-columns' are block-index columns:
    my @unique;
    foreach my $block ( 0 .. $self->{BLOCKS} - 1 ) {
        my %count;
        map {
            push(
                @unique,
                grep { ++$count{$_} < 2 } ( @{ $self->{DATA}[$_][$block] } )
            );
        } (@sort_cols);
    }
    if ( ( my $len = @unique )
        > ( ( $self->{BLOCKS} + 1 ) * ( my $len_sort = @sort_cols ) ) ) {
        warn
            "WARNING: in sub 'block-sort' the given block-index-columns are not well defined.";
    }

    # convert column/block structure to row/block structure:
    my @temp;
    foreach my $block ( ( 0 .. $self->{BLOCKS} - 1 ) ) {
        foreach my $column ( 0 .. $self->{COLUMNS} ) {
            my $index = 0;
            map { push( @{ $temp[$block][$index] }, $_ ); $index++; }
                ( @{ $self->{DATA}[$column][$block] } );
        }
    }

    # sort blocks:
    my @sorted_data;

    # create sort string:
    my $sort;
    if ( $direction =~ /^[+]$/ ) {
        map { $sort .= "\$a->[0][" . $_ . "] <=> \$b->[0][" . $_ . "]||" }
            @sort_cols;
    }
    else {
        map { $sort .= "\$b->[0][" . $_ . "] <=> \$a->[0]" . $_ . "]||" }
            @sort_cols;
    }
    chop $sort;
    chop $sort;

    # sort:
    @sorted_data = sort { eval $sort } (@temp);

    # convert row/block structure to column/block structure:
    my @temp;
    my $b = 0;
    foreach my $block (@sorted_data) {
        my $rows = @{$block};
        foreach my $row ( 0 .. $rows - 1 ) {
            my $column = 0;

            #map {push(@{$temp[$column][$block]}, $_); $column+=1;} (@{$block->[$row]});
            map { push( @{ $temp[$column][$b] }, $_ ); $column += 1; }
                ( @{ $block->[$row] } );

            #map {print $_."\t";} (@{$block->[$row]});
            #print "\n";
        }
        $b++;
    }

    # apply to $self:
    $self->{DATA} = \@temp;

    return $self;

}

sub global_sort {
    my $self      = shift;
    my $direction = shift
        ; # direction can be '+', '-' for  sorting 'rising' or 'falling' respectivly
    my @sort_cols = @_;

    if ( not $direction =~ /^[+-]$/ ) {
        unshift( @sort_cols, $direction );
        $direction = '+';
    }

    # find col_index for col_name:
    map { $_ = $self->get_colnum($_); } (@sort_cols);

    # convert column/block structure to row/block structure:
    my @temp;
    my $index_0 = 0;
    foreach my $block ( ( 0 .. $self->{BLOCKS} - 1 ) ) {
        my $index;
        foreach my $column ( 0 .. $self->{COLUMNS} ) {
            $index = $index_0;
            map { push( @{ $temp[$index] }, $_ ); $index++; }
                ( @{ $self->{DATA}[$column][$block] } );
        }
        $index_0 = $index;
    }

    # sort rows:
    my @sorted_data;

    # create sort string:
    my $sort;
    if ( $direction =~ /^[+]$/ ) {
        map { $sort .= "\$a->[" . $_ . "] <=> \$b->[" . $_ . "]||" }
            @sort_cols;
    }
    else {
        map { $sort .= "\$b->[" . $_ . "] <=> \$a->[" . $_ . "]||" }
            @sort_cols;
    }
    chop $sort;
    chop $sort;

    # sort:
    @sorted_data = sort { eval $sort } (@temp);

    # convert row/block structure to column/block structure:
    my @temp;
    my $rows = @sorted_data;
    foreach my $row ( 0 .. $rows - 1 ) {
        my $column = 0;
        map { push( @{ $temp[$column][0] }, $_ ); $column++; }
            ( @{ $sorted_data[$row] } );
    }

    # apply to $self:
    $self->{DATA}   = \@temp;
    $self->{BLOCKS} = 0;

    return $self;

}

sub block_generator {
    my $self      = shift;
    my $block_col = shift;

    # find col_index for col_name:
    $block_col = $self->get_colnum($block_col);

    # sort data:
    $self->global_sort($block_col);

    # convert column/block structure to row/block structure:
    my @temp;
    my $index_0 = 0;
    foreach my $block ( ( 0 .. $self->{BLOCKS} - 1 ) ) {
        my $index;
        foreach my $column ( 0 .. $self->{COLUMNS} ) {
            $index = $index_0;
            map { push( @{ $temp[$index] }, $_ ); $index++; }
                ( @{ $self->{DATA}[$column][$block] } );
        }
        $index_0 = $index;
    }

    # generate blocks:
    my @block_data;
    my $block = 0;
    my $index = 0;
    my $ref   = $temp[$index][$block_col];
    foreach my $row (@temp) {
        if ( $ref == $row->[$block_col] ) {
            push( @{ $block_data[$block] }, $row );
            $index++;
        }
        else {
            $block++;
            push( @{ $block_data[$block] }, $row );
            $ref = $temp[$index][$block_col];
            $index++;
        }
    }

    # convert row/block structure to column/block structure:
    my @temp;
    my $b = 0;
    foreach my $block (@block_data) {
        my $rows = @{$block};
        foreach my $row ( 0 .. $rows - 1 ) {
            my $column = 0;
            map { push( @{ $temp[$column][$b] }, $_ ); $column += 1; }
                ( @{ $block->[$row] } );
        }
        $b++;
    }

    # apply to $self:
    $self->{DATA} = \@temp;

    return $self;

}

sub find {
    my $self      = shift;
    my $condition = shift;

    if ( defined $condition ) {
        $self->{EXPRESSION} = $condition;
        $self->{EXP_PARTS};
        $self->{EVAL_PARTS};

        # interpreter for EXPRESSION:
        $self->expression();
    }

    # final evaluation of expression:
    if ( ( my $len = @{ $self->{EXP_PARTS} } ) == 1 ) {
        warn
            "WARNING: in sub 'find' no well defined condtion given. Ignor find command. Return all.";
        my @selection;
        map {
            my $rows = @{ $self->{DATA}[0][$_] };
            my @rows = ( 0 .. $rows - 1 );
            push( @{ $selection[$_] }, @rows );
        } ( ( 0 .. $self->{BLOCKS} - 1 ) );
        return @selection;
    }
    elsif ( ( my $len = @{ $self->{EXP_PARTS} } ) == 3 ) {
        if ( @{ $self->{EXP_PARTS} }[1] =~ /(>|>=|==|<=|<|!=)/ ) {
            if ( @{ $self->{EXP_PARTS} }[0] =~ /EP([0-9]+)/ ) {
                @{ $self->{EXP_PARTS} }[0] = @{ $self->{EVAL_PARTS} }[$1];
            }

            if ( @{ $self->{EXP_PARTS} }[2] =~ /EP([0-9]+)/ ) {
                @{ $self->{EXP_PARTS} }[2] = @{ $self->{EVAL_PARTS} }[$1];
            }

            if (
                ref( @{ $self->{EXP_PARTS} }[0] ) ne
                'Lab::XPRESS::Data::XPRESS_dataset' ) {
                warn
                    "WARNING: in sub 'find' no well defined condtion given. Ignor find command. Return all.";
                my @selection;
                map {
                    my $rows = @{ $self->{DATA}[0][$_] };
                    my @rows = ( 0 .. $rows - 1 );
                    push( @{ $selection[$_] }, @rows );
                } ( ( 0 .. $self->{BLOCKS} - 1 ) );
                return @selection;
            }

            if (
                ref( @{ $self->{EXP_PARTS} }[2] ) eq
                'Lab::XPRESS::Data::XPRESS_dataset' ) {
                map {
                    if (
                        (
                            my $len_0
                            = @{ @{ $self->{EXP_PARTS} }[0]->{DATA}[0][$_] }
                        ) != (
                            my $len_2
                                = @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0][$_]
                                }
                        )
                        ) {
                        warn
                            'WARNING: unexpected values sub eval within the expression given. Ignore, return self.';
                        return $self;
                    }
                    } (
                    ( 0 .. @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0] } - 1 ) );
            }

            my @selection;
            my $exp = @{ $self->{EXP_PARTS} }[1] . @{ $self->{EXP_PARTS} }[2];
            my $selected_elements = $self->copy();
            @{ $selected_elements->{DATA} } = ();

            for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
                my $index = 0;
                my @indices;
                my $temp;
                print @{ $self->{EXP_PARTS} }[0]->{0};
                exit;
                my @block
                    = @{ @{ $self->{EXP_PARTS} }[0]->{DATA}[0][$block] };
                if (
                    ref( @{ $self->{EXP_PARTS} }[2] ) eq
                    'Lab::XPRESS::Data::XPRESS_dataset' ) {
                    @indices = grep {
                        $temp = $_;
                        $_    = $index;
                        $index++;
                        eval $temp
                            . @{ $self->{EXP_PARTS} }[1]
                            . @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0][$block]
                            }[$index]
                    } (@block);
                }
                else {
                    @indices = grep {
                        $temp = $_;
                        $_    = $index;
                        $index++;
                        eval $temp
                            . @{ $self->{EXP_PARTS} }[1]
                            . @{ $self->{EXP_PARTS} }[2]
                    } (@block);
                }
                push( @{ $selection[$block] }, @indices );
            }

            # map {print $_."\n";} (@selection);
            # map {map {print $_."\n";} (@{$_}); print "end\n";} (@selection);
            # exit;
            return @selection;
        }
        else {
            warn
                "WARNING: in sub 'find' no well defined condtion given. Ignor find command. Return all.";
            my @selection;
            map {
                my $rows = @{ $self->{DATA}[0][$_] };
                my @rows = ( 0 .. $rows - 1 );
                push( @{ $selection[$_] }, @rows );
            } ( ( 0 .. $self->{BLOCKS} - 1 ) );
            return @selection;
        }
    }
    elsif ( ( my $len = @{ $self->{EXP_PARTS} } ) == 5 ) {
        if ( @{ $self->{EXP_PARTS} }[0] =~ /EP([0-9]+)/ ) {
            @{ $self->{EXP_PARTS} }[0] = @{ $self->{EVAL_PARTS} }[$1];
        }

        if ( @{ $self->{EXP_PARTS} }[2] =~ /EP([0-9]+)/ ) {
            @{ $self->{EXP_PARTS} }[2] = @{ $self->{EVAL_PARTS} }[$1];
        }

        if ( @{ $self->{EXP_PARTS} }[4] =~ /EP([0-9]+)/ ) {
            @{ $self->{EXP_PARTS} }[4] = @{ $self->{EVAL_PARTS} }[$1];
        }

        if (
            ref( @{ $self->{EXP_PARTS} }[2] ) ne
            'Lab::XPRESS::Data::XPRESS_dataset' ) {
            warn
                "WARNING: in sub 'find' no well defined condtion given. Ignor find command. Return all.";
            my @selection;
            map {
                my $rows = @{ $self->{DATA}[0][$_] };
                my @rows = ( 0 .. $rows - 1 );
                push( @{ $selection[$_] }, @rows );
            } ( ( 0 .. $self->{BLOCKS} - 1 ) );
            return @selection;
        }

        if (
            ref( @{ $self->{EXP_PARTS} }[0] ) eq
            'Lab::XPRESS::Data::XPRESS_dataset' ) {
            map {
                if (
                    (
                        my $len_0
                        = @{ @{ $self->{EXP_PARTS} }[0]->{DATA}[0][$_] }
                    ) != (
                        my $len_2
                            = @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0][$_] }
                    )
                    ) {
                    warn
                        'WARNING: unexpected values sub eval within the expression given. Ignore, return self.';
                    return $self;
                }
            } ( ( 0 .. @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0] } - 1 ) );
        }

        if (
            ref( @{ $self->{EXP_PARTS} }[4] ) eq
            'Lab::XPRESS::Data::XPRESS_dataset' ) {
            map {
                if (
                    (
                        my $len_4
                        = @{ @{ $self->{EXP_PARTS} }[4]->{DATA}[0][$_] }
                    ) != (
                        my $len_2
                            = @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0][$_] }
                    )
                    ) {
                    warn
                        'WARNING: unexpected values sub eval within the expression given. Ignore, return self.';
                    return $self;
                }
            } ( ( 0 .. @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0] } - 1 ) );
        }

        my @selection;
        my $selected_elements = $self->copy();
        @{ $selected_elements->{DATA} } = ();

        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
            my $index = 0;
            my @indices;
            my $temp;
            my @block = @{ @{ $self->{EXP_PARTS} }[2]->{DATA}[0][$block] };

            if (
                ref( @{ $self->{EXP_PARTS} }[0] ) eq
                'Lab::XPRESS::Data::XPRESS_dataset'
                and ref( @{ $self->{EXP_PARTS} }[4] ) eq
                'Lab::XPRESS::Data::XPRESS_dataset' ) {
                @indices = grep {
                    $temp = $_;
                    $_    = $index;
                    $index++;
                    eval @{ @{ $self->{EXP_PARTS} }[0]->{DATA}[0][$block] }
                        [$index]
                        . @{ $self->{EXP_PARTS} }[1]
                        . $temp
                        and eval $temp
                        . @{ $self->{EXP_PARTS} }[3]
                        . @{ @{ $self->{EXP_PARTS} }[4]->{DATA}[0][$block] }
                        [$index];
                } (@block);
            }
            elsif (
                ref( @{ $self->{EXP_PARTS} }[0] ) eq
                'Lab::XPRESS::Data::XPRESS_dataset' ) {
                @indices = grep {
                    $temp = $_;
                    $_    = $index;
                    $index++;
                    eval @{ @{ $self->{EXP_PARTS} }[0]->{DATA}[0][$block] }
                        [$index]
                        . @{ $self->{EXP_PARTS} }[1]
                        . $temp
                        and eval $temp
                        . @{ $self->{EXP_PARTS} }[3]
                        . @{ $self->{EXP_PARTS} }[4];
                } (@block);
            }
            elsif (
                ref( @{ $self->{EXP_PARTS} }[4] ) eq
                'Lab::XPRESS::Data::XPRESS_dataset' ) {
                @indices = grep {
                    $temp = $_;
                    $_    = $index;
                    $index++;
                    eval @{ $self->{EXP_PARTS} }[0]
                        . @{ $self->{EXP_PARTS} }[1]
                        . $temp
                        and eval $temp
                        . @{ $self->{EXP_PARTS} }[3]
                        . @{ @{ $self->{EXP_PARTS} }[4]->{DATA}[0][$block] }
                        [$index];
                } (@block);
            }
            else {
                @indices = grep {
                    $temp = $_;
                    $_    = $index;
                    $index++;
                    eval @{ $self->{EXP_PARTS} }[0]
                        . @{ $self->{EXP_PARTS} }[1]
                        . $temp
                        and eval $temp
                        . @{ $self->{EXP_PARTS} }[3]
                        . @{ $self->{EXP_PARTS} }[4];
                } (@block);
            }

            push( @{ $selection[$block] }, @indices );

        }

        return @selection;
    }

}

sub replace {
    my $self    = shift;
    my $select  = shift;
    my $replace = shift;

    $self->{EXPRESSION} = $select;
    $self->{EXP_PARTS};
    $self->{EVAL_PARTS};

    my $self_re = $self->copy();
    $self_re->{EXPRESSION} = $replace;
    $self_re->{EXP_PARTS};
    $self_re->{EVAL_PARTS};

    # interpreter for EXPRESSION:
    $self->expression();
    $self_re = $self_re->expression();

    # prepare replace data:
    if ( ref($self_re) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
        if ( not( my $len = @{ $self_re->{EXP_PARTS} } ) == 1 ) {
            warn
                "WARNING: in sub 'replace' no well defined replace-data given. Ignor replace command.";
            return $self;
        }

        elsif ( @{ $self_re->{EXP_PARTS} }[2] =~ /EP([0-9]+)/ ) {
            @{ $self_re->{EXP_PARTS} }[2] = @{ $self_re->{EVAL_PARTS} }[$1];
        }
    }

    # evaluate data selection:
    my @selection = $self->find();

    # replace selected data:

    for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
        for ( my $c = 0; $c < ( my $len = @{ $self->{DATA} } ); $c++ ) {

            # replace data are of type Lab::XPRESS::Data::XPRESS_dataset:
            if ( ref($self_re) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
                map {
                    print $_. "\n";
                    $self->{DATA}[$c][$block][$_]
                        = $self_re->{DATA}[$c][$block][$_];
                } ( @{ $selection[$block] } );
            }

            # replace data is a single value or string;
            else {
                map {
                    print $_. "\n";
                    $self->{DATA}[$c][$block][$_] = $self_re;
                } ( @{ $selection[$block] } );
            }
        }
    }

    return $self;

}

sub expression {
    my $self       = shift;
    my $expression = shift;

    if ( not defined $expression ) {
        if ( defined $self->{EXPRESSION} ) {
            $expression = $self->{EXPRESSION};
        }
        else {
            warn
                "WARNING in sub expression: No expression given. Ignor and return self";
            return $self;
        }
    }
    else {
        $self = $self->copy();
        $self->{EXPRESSION} = $expression;
        @{ $self->{EXP_PARTS} } = ();
    }
    $expression
        =~ s/\s+//g;    #removes all whitespaces within $self->{EXPRESSION}
    $self->{EXPRESSION} = $expression;

    if ( $expression =~ /(^[+-]?[0-9.eE\(\{\[\)\]\}]+$)/ ) {
        $expression = $1;
        if ( $expression =~ /(.+)?([\(\[\{]((EP)?[0-9]+)[\)\]\}])(.+)?/ ) {
            $expression = $1 . $5 . $3;
        }
        return $expression;
    }

    # check for expression type:
    if ( $expression =~ /(.+)(>=|<=|<|>|==|!=)(.+)/ ) {
        push( @{ $self->{EXP_PARTS} }, $1 );
        push( @{ $self->{EXP_PARTS} }, $2 );
        push( @{ $self->{EXP_PARTS} }, $3 );

        # repeat for expressions like 0 <= x < 10
        my $i = 0;
        for (
            my $part = @{ $self->{EXP_PARTS} }[$i];
            $i < ( my $len = @{ $self->{EXP_PARTS} } );
            $i++
            ) {
            $part = @{ $self->{EXP_PARTS} }[$i];
            if ( $part =~ /(.+)(>=|<=|<|>|==|!=)(.+)/ ) {
                @{ $self->{EXP_PARTS} }[$i] = $1;
                splice @{ $self->{EXP_PARTS} }, $i + 1, 0, $2;
                splice @{ $self->{EXP_PARTS} }, $i + 2, 0, $3;
            }
        }
    }
    elsif ( $expression =~ /(.+)(=)(.+)/ ) {
        push( @{ $self->{EXP_PARTS} }, $1 );
        push( @{ $self->{EXP_PARTS} }, $2 );
        push( @{ $self->{EXP_PARTS} }, $3 );
    }
    else {
        push( @{ $self->{EXP_PARTS} }, $expression );
    }

    # check if there are any code words in the expression parts:
    #my @{$self->{EVAL_PARTS}};
    my $i = 0;

    my $n = 0;
    for (
        my $part = @{ $self->{EXP_PARTS} }[$i];
        $i < ( my $len = @{ $self->{EXP_PARTS} } );
        $i++
        ) {
        $part = @{ $self->{EXP_PARTS} }[$i];

        if ( $part
            =~ /(.*[^0-9-+.])?([+-]?([0-9]+)(\.[0-9]+)?(e|E)([+-]?[0-9]+))([^0-9].*)?/
            ) {
            my $r1 = $1;
            my $r2 = $2;
            my $r7 = $7;
            if ( not $1 =~ /[-+\*\/]$/ ) {
                $r2 = reverse($r2);
                $r1 .= chop $r2;
                $r2 = reverse($r2);
            }
            push( @{ $self->{EVAL_PARTS} }, $r2 );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $r1 . "EP$len_EP" . $r7;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(1\/col\[([^\(\[\{\)\]\}]+)\]|1\/col\(([^\(\[\{\)\]\}]+)\)|1\/col\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $x = -1;
            my $y;
            if    ( defined $3 ) { $y = $3; }
            elsif ( defined $5 ) { $y = $4; }
            elsif ( defined $7 ) { $y = $5; }
            $y = $self->extract_col($y);
            push( @{ $self->{EVAL_PARTS} }, $y->yEx( $y, $x ) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $9;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(col\[([^\(\[\{\)\]\}]+)\]|col\(([^\(\[\{\)\]\}]+)\)|col\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            else                 { next; }
            push( @{ $self->{EVAL_PARTS} }, $self->extract_col($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(sin\[([^\(\[\{\)\]\}]+)\]|sin\(([^\(\[\{\)\]\}]+)\)|sin\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->sin($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(cos\[([^\(\[\{\)\]\}]+)\]|cos\(([^\(\[\{\)\]\}]+)\)|cos\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->cos($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(tan\[([^\(\[\{\)\]\}]+)\]|tan\(([^\(\[\{\)\]\}]+)\)|tan\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->tan($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(abs\[([^\(\[\{\)\]\}]+)\]|abs\(([^\(\[\{\)\]\}]+)\)|abs\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->abs($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(sgn\[([^\(\[\{\)\]\}]+)\]|sgn\(([^\(\[\{\)\]\}]+)\)|sgn\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->sgn($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(exp\[([^\(\[\{\)\]\}]+)\]|exp\(([^\(\[\{\)\]\}]+)\)|exp\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->exp($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(ln\[([^\(\[\{\)\]\}]+)\]|ln\(([^\(\[\{\)\]\}]+)\)|ln\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->ln($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(log\[([^\(\[\{\)\]\}]+)\]|log\(([^\(\[\{\)\]\}]+)\)|log\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->log($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(sqrt\[([^\(\[\{\)\]\}]+)\]|sqrt\(([^\(\[\{\)\]\}]+)\)|sqrt\{([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $parameter;
            if    ( defined $3 ) { $parameter = $3; }
            elsif ( defined $4 ) { $parameter = $4; }
            elsif ( defined $5 ) { $parameter = $5; }
            push( @{ $self->{EVAL_PARTS} }, $self->sqrt($parameter) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $6;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part
            =~ /(.+)?(yEx\[([^\(\[\{\)\]\}]+)\,([^\(\[\{\)\]\}]+)\]|yEx\(([^\(\[\{\)\]\}]+)\,([^\(\[\{\)\]\}]+)\)|yEx\{([^\(\[\{\)\]\}]+)\,([^\(\[\{\)\]\}]+)\})(.+)?/
            ) {
            my $x;
            my $y;
            if    ( defined $3 ) { $y = $3; $x = $4; }
            elsif ( defined $5 ) { $y = $5; $x = $6; }
            elsif ( defined $7 ) { $y = $7; $x = $8; }
            push( @{ $self->{EVAL_PARTS} }, $self->yEx( $y, $x ) );
            my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
            $part = $1 . "EP$len_EP" . $9;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }
        elsif ( $part =~ /(.+)?([\(\[\{]((EP)?[0-9]+)[\)\]\}])(.+)?/ ) {
            print "1 = $1\n";
            print "2 = $2\n";
            print "3 = $3\n";
            print "4 = $4\n";
            print "5 = $5\n";
            print "6 = $6\n";
            print "7 = $7\n";
            $part = $1 . $5 . $3;
            @{ $self->{EXP_PARTS} }[$i] = $part;
            $i -= 1;
        }

    }

    # look for brackets:
    my $i = 0;
    for (
        my $part = @{ $self->{EXP_PARTS} }[$i];
        $i < ( my $len = @{ $self->{EXP_PARTS} } );
        $i++
        ) {
        $part = @{ $self->{EXP_PARTS} }[$i];
        if ( $part =~ /(.+)?(\(.+\))(.+)?/ ) {
            if ( defined $1 ) {
                @{ $self->{EXP_PARTS} }[$i] = $1;
                splice @{ $self->{EXP_PARTS} }, $i, 0, $2;
            }
            else {
                @{ $self->{EXP_PARTS} }[$i] = $2;
            }

            if ( defined $3 ) {
                splice @{ $self->{EXP_PARTS} }, $i + 1, 0, $3;
            }
        }
    }

    # evaluate parts:
    $self->calc();

    # join parts and evaluate again:
    my $i = 0;
    my $j = 0;
    for (
        my $part = @{ $self->{EXP_PARTS} }[$i];
        $i < ( my $len = @{ $self->{EXP_PARTS} } - 1 );
        $i++
        ) {
        $part = @{ $self->{EXP_PARTS} }[$i];
        if ( $part =~ /^(>=|<=|<|>|==|!=|=)$/ ) {
            splice @{ $self->{EXP_PARTS} }, $j, 0,
                join( '', splice @{ $self->{EXP_PARTS} }, $j, ( $i - $j ) );
            $j += 2;
        }
    }
    splice @{ $self->{EXP_PARTS} }, $j, 0,
        join( '', splice @{ $self->{EXP_PARTS} }, $j, ( $i - $j + 1 ) );

    # the evaluated EXPRESSION can be found in @{$self->{EXP_PARTS}}[0..4];

    return $self;

}

sub eval {
    my $self       = shift;
    my $expression = shift;

    $self->{EXPRESSION} = $expression;
    $self->{EXP_PARTS}  = [];
    $self->{EVAL_PARTS} = [];

    # interpreter for EXPRESSION:
    $self->expression();

    # final evaluation of expression:
    if ( ( my $len = @{ $self->{EXP_PARTS} } ) == 1 ) {
        if ( @{ $self->{EXP_PARTS} }[0] =~ /EP([0-9]+)/ ) {
            return @{ $self->{EVAL_PARTS} }[$1];
        }
        else {
            return @{ $self->{EXP_PARTS} }[0];
        }
    }
    elsif ( ( my $len = @{ $self->{EXP_PARTS} } ) == 3 ) {
        if ( @{ $self->{EXP_PARTS} }[1] eq '=' ) {
            $self->{EXPRESSION} =~ /(.+)(=)(.+)/;
            if ( $1
                =~ /(.+)?(col\[([^\(\[\{\)\]\}]+)\]|col\(([^\(\[\{\)\]\}]+)\)|col\{([^\(\[\{\)\]\}]+)\})(.+)?/
                ) {
                # get columnnumber for result column:
                my $result_column;
                if    ( defined $3 ) { $result_column = $3; }
                elsif ( defined $4 ) { $result_column = $4; }
                elsif ( defined $5 ) { $result_column = $5; }
                my $i = $self->get_colnum($result_column);

                # append empty column for result if not existing:
                if ( $i == -1 ) {
                    $self->insert_c($result_column);
                }

                # set result data to self:
                if ( @{ $self->{EXP_PARTS} }[2] =~ /EP([0-9]+)/ ) {
                    @{ $self->{EXP_PARTS} }[0]
                        = $self->set( @{ $self->{EVAL_PARTS} }[$1], $i );
                    @{ $self->{COL_NAMES} }[$i] = $result_column;
                }
                else {
                    @{ $self->{EXP_PARTS} }[0]
                        = $self->set( @{ $self->{EXP_PARTS} }[2], $i );
                    @{ $self->{COL_NAMES} }[$i] = $result_column;
                }

                # return only the result of calculation:
                return @{ $self->{EXP_PARTS} }[0];
            }
            else {
                if ( @{ $self->{EXP_PARTS} }[2] =~ /EP([0-9]+)/ ) {
                    @{ $self->{EXP_PARTS} }[2] = @{ $self->{EVAL_PARTS} }[$1];
                }
                else {
                    warn "WARNING: cannot set '"
                        . ( @{ $self->{EXP_PARTS} }[0] )
                        . "' with '"
                        . ( @{ $self->{EXP_PARTS} }[2] ) . "'!\t";
                }
                return @{ $self->{EVAL_PARTS} }[2];
            }
        }
        elsif ( @{ $self->{EXP_PARTS} }[1] =~ /(>|>=|==|<=|<|!=)/ ) {
            my $exp = @{ $self->{EXP_PARTS} }[1] . @{ $self->{EXP_PARTS} }[2];
            my $selected_elements = $self->copy();
            @{ $selected_elements->{DATA} } = ();

            my @indices = $self->find();

            #map {map {print $_."\t";} (@{$_}); print "\n";} (@indices);
            for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {
                for (
                    my $c = 0;
                    $c < ( my $len = @{ $self->{DATA} } );
                    $c++
                    ) {
                    if ( ( my $len = @{ $indices[$block] } ) == 0 ) {
                        @{ $selected_elements->{DATA}[$c][$block] } = ();
                    }
                    else {
                        map {
                            push(
                                @{
                                    $selected_elements->{DATA}[$c][$block]
                                },
                                @{ $self->{DATA}[$c][$block] }[$_]
                            );
                        } ( @{ $indices[$block] } );
                    }

                    #map {print $_."\t"} (@{$selected_elements->{DATA}[$c][$block]});
                }
            }

            return $selected_elements;
        }
        else {
            warn
                'WARNING: unexpected values sub eval within the expression given. Ignore, return self.';
            return $self;
        }
    }
    elsif ( ( my $len = @{ $self->{EXP_PARTS} } ) == 5 ) {

        my $selected_elements = $self->copy();
        @{ $selected_elements->{DATA} } = ();

        my @indices = $self->find();

        for ( my $block = 0; $block <= $self->{BLOCKS}; $block++ ) {

            #my @indices =  grep{ $temp = $_; $_ = $index; $index++; eval @{@{$self->{EXP_PARTS}}[0]->{DATA}[0][$block]}[$index].@{$self->{EXP_PARTS}}[1].$temp and eval $temp.@{$self->{EXP_PARTS}}[3].@{@{$self->{EXP_PARTS}}[4]->{DATA}[0][$block]}[$index]; } (@block);
            #map {print "index = ".$_."\n";} (@indices);
            for ( my $c = 0; $c < ( my $len = @{ $self->{DATA} } ); $c++ ) {
                if ( ( my $len = @{ $indices[$block] } ) == 0 ) {
                    @{ $selected_elements->{DATA}[$c][$block] } = ();
                }
                else {
                    map {
                        push(
                            @{ $selected_elements->{DATA}[$c][$block] },
                            @{ $self->{DATA}[$c][$block] }[$_]
                        );
                    } ( @{ $indices[$block] } );
                }

                #map {print $_."\t"} (@{$selected_elements->{DATA}[$c][$block]});
            }
        }

        return $selected_elements;
    }

}

sub calc {
    my $self = shift;

    if ( not @{ $self->{EXP_PARTS} }[0] ) {
        warn
            "WARNING in sub calc: No expression to calculate given. Ignor and return self.";
        return $self;
    }

    # map {print $_."_";} (@{$evaluated_parts});
    # print @{$evaluated_parts}[1]+@{$evaluated_parts}[2];
    # exit;

    # evaluate parts:
    my $i = 0;
    for (
        my $part = @{ $self->{EXP_PARTS} }[$i];
        $i < ( my $len = @{ $self->{EXP_PARTS} } );
        $i++
        ) {
        $part = @{ $self->{EXP_PARTS} }[$i];
        while ( $part =~ /(.+)(\+|-|\*|\/|\%)(.+)/ ) {
            $part = @{ $self->{EXP_PARTS} }[$i];

            # CASE *:
            if ( $part =~ /((.+)(\+|-|\*|\/))?(.+)\*(.+)((\+|-|\*|\/)(.+))?/ )
            {

                # replace $4 and $5 by evaluated expression if defined.
                my $ep4 = $4;
                my $ep5 = $5;
                if ( $ep4 =~ /EP([0-9]+)/ ) {
                    $ep4 = @{ $self->{EVAL_PARTS} }[$1];
                }

                if ( $ep5 =~ /EP([0-9]+)/ ) {
                    $ep5 = @{ $self->{EVAL_PARTS} }[$1];
                }

                #print $ep4." * ".$ep5." = ";

                # calculate:
                if ( ref($ep4) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
                    $ep4 = $ep4->multiply( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                elsif ( ref($ep4) eq "ARRAY" ) {
                    my $temp = new Lab::XPRESS::Data::XPRESS_dataset();
                    $temp->set( $ep4, 0 );
                    $ep4 = $temp;
                    $ep4 = $ep4->multiply( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                else {
                    $ep4 = $ep4 * $ep5;
                }

                #print $ep4."\n";
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\*(.+)((\+|-|\*|\/)(.+))?/;
                @{ $self->{EXP_PARTS} }[$i]
                    = $1 . $2 . $3 . $ep4 . $6 . $7 . $8;
            }

            # CASE /:
            elsif (
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\/(.+)((\+|-|\*|\/)(.+))?/ )
            {
                # replace $4 and $5 by evaluated expression if defined.
                my $ep4 = $4;
                my $ep5 = $5;
                if ( $ep4 =~ /EP([0-9]+)/ ) {
                    $ep4 = @{ $self->{EVAL_PARTS} }[$1];
                }

                if ( $ep5 =~ /EP([0-9]+)/ ) {
                    $ep5 = @{ $self->{EVAL_PARTS} }[$1];
                }

                #print $ep4." / ".$ep5." = ";

                # calculate:
                if ( ref($ep4) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
                    $ep4 = $ep4->divide( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                elsif ( ref($ep4) eq "ARRAY" ) {
                    my $temp = new Lab::XPRESS::Data::XPRESS_dataset();
                    $temp->set( $ep4, 0 );
                    $ep4 = $temp;
                    $ep4 = $ep4->divide( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                else {
                    $ep4 = ( $ep5 != 0 ) ? $ep4 / $ep5 : 'nan';
                }

                #print $ep4."\n";
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\/(.+)((\+|-|\*|\/)(.+))?/;
                @{ $self->{EXP_PARTS} }[$i]
                    = $1 . $2 . $3 . $ep4 . $6 . $7 . $8;
            }

            # CASE +:
            elsif (
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\+(.+)((\+|-|\*|\/)(.+))?/ )
            {
                # replace $4 and $5 by evaluated expression if defined.
                my $ep4 = $4;
                my $ep5 = $5;
                if ( $ep4 =~ /EP([0-9]+)/ ) {
                    $ep4 = @{ $self->{EVAL_PARTS} }[$1];
                }

                if ( $ep5 =~ /EP([0-9]+)/ ) {
                    $ep5 = @{ $self->{EVAL_PARTS} }[$1];
                }

                #print $ep4." + ".$ep5." = ";

                # calculate:
                if ( ref($ep4) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
                    $ep4 = $ep4->add( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                elsif ( ref($ep4) eq "ARRAY" ) {
                    my $temp = new Lab::XPRESS::Data::XPRESS_dataset();
                    $temp->set( $ep4, 0 );
                    $ep4 = $temp;
                    $ep4 = $ep4->add( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                else {
                    $ep4 = $ep4 + $ep5;
                }

                #print $ep4."\n";
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\+(.+)((\+|-|\*|\/)(.+))?/;
                @{ $self->{EXP_PARTS} }[$i]
                    = $1 . $2 . $3 . $ep4 . $6 . $7 . $8;
            }

            # CASE -:
            elsif (
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\-(.+)((\+|-|\*|\/)(.+))?/ )
            {
                # replace $4 and $5 by evaluated expression if defined.
                my $ep4 = $4;
                my $ep5 = $5;
                if ( $ep4 =~ /EP([0-9]+)/ ) {
                    $ep4 = @{ $self->{EVAL_PARTS} }[$1];
                }

                if ( $ep5 =~ /EP([0-9]+)/ ) {
                    $ep5 = @{ $self->{EVAL_PARTS} }[$1];
                }

                #print $ep4." - ".$ep5." = ";

                # calculate:
                if ( ref($ep4) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
                    $ep4 = $ep4->subtract( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                elsif ( ref($ep4) eq "ARRAY" ) {
                    my $temp = new Lab::XPRESS::Data::XPRESS_dataset();
                    $temp->set( $ep4, 0 );
                    $ep4 = $temp;
                    $ep4 = $ep4->subtract( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                else {
                    $ep4 = $ep4 - $ep5;
                }

                #print $ep4."\n";
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\-(.+)((\+|-|\*|\/)(.+))?/;
                @{ $self->{EXP_PARTS} }[$i]
                    = $1 . $2 . $3 . $ep4 . $6 . $7 . $8;
            }
            elsif (
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\%(.+)((\+|-|\*|\/)(.+))?/ )
            {
                # replace $4 and $5 by evaluated expression if defined.
                my $ep4 = $4;
                my $ep5 = $5;
                if ( $ep4 =~ /EP([0-9]+)/ ) {
                    $ep4 = @{ $self->{EVAL_PARTS} }[$1];
                }

                if ( $ep5 =~ /EP([0-9]+)/ ) {
                    $ep5 = @{ $self->{EVAL_PARTS} }[$1];
                }

                #print $ep4." % ".$ep5." = ";

                # calculate:
                if ( ref($ep4) eq 'Lab::XPRESS::Data::XPRESS_dataset' ) {
                    $ep4 = $ep4->modulo( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                elsif ( ref($ep4) eq "ARRAY" ) {
                    my $temp = new Lab::XPRESS::Data::XPRESS_dataset();
                    $temp->set( $ep4, 0 );
                    $ep4 = $temp;
                    $ep4 = $ep4->modulo( $ep5, 0 );
                    push( @{ $self->{EVAL_PARTS} }, $ep4 );
                    my $len_EP = @{ $self->{EVAL_PARTS} } - 1;
                    $ep4 = "EP$len_EP";
                }
                else {
                    $ep4 = _modulo( $ep4, $ep5 );
                }

                #print $ep4."\n";
                $part =~ /((.+)(\+|-|\*|\/))?(.+)\%(.+)((\+|-|\*|\/)(.+))?/;
                @{ $self->{EXP_PARTS} }[$i]
                    = $1 . $2 . $3 . $ep4 . $6 . $7 . $8;
            }
        }
    }

    return $self;

}

sub _modulo {
    my $n1 = shift;
    my $n2 = shift;

    print $n1. " % " . $n2 . " = ";

    my $res = $n1 / $n2;
    my $t   = int($res);

    $res = $res - $t;
    $res = $res * $n2;
    print $res. "\n";
    return $res;
}

sub offset_correction_idc {
    my $self    = shift;
    my $v       = shift;
    my $i       = shift;
    my @v_range = ( shift, shift );
    my $name    = shift;

    if ( not defined $name ) {
        $name = "Idc_offset_corrected";
    }

    $v = $self->get_colnum($v);
    $i = $self->get_colnum($i);
    if ( $v == -1 or $i == -1 ) {
        warn
            "WARNING: invalid parameters given for sub offset_correction_idc(). ";
        return $self;
    }

    # find relevant datapoints around V_sd == 0:
    my $selection = $self->eval("$v_range[0] <= col[V_sd] <= $v_range[1]");

    # linear fit for selected data:
    my @offset = $selection->lineFit( $v, $i );

    # subtract offset:
    my $I_dc = $self->subtract( \@offset, $i );
    my $i = $self->get_colnum($name);
    $self->set( $I_dc, $i );
    $self->rename_col( $self->get_colname($i), $name );

    return @offset;

}

sub offset_correction_idc_v2 {
    my $self = shift;
    my $v    = shift;
    my $i    = shift;
    my $name = shift;

    if ( not defined $name ) {
        $name = "Idc_offset_corrected";
    }

    $v = $self->get_colnum($v);
    $i = $self->get_colnum($i);
    if ( $v == -1 or $i == -1 ) {
        warn
            "WARNING: invalid parameters given for sub offset_correction_idc(). ";
        return $self;
    }

    # sort data:
    $self->sort( '+', $v );

    my @offset;
    foreach ( 0 .. $self->{BLOCKS} - 1 ) {

        # select data:
        my $x = $self->{DATA}->[$v][$_];
        my $y = $self->{DATA}->[$i][$_];

        # interpolate data:
        my ( $i_y, $i_dy ) = robust_interpolate( 0, $x, $y );
        push( @offset, $i_y );
    }

    # subtract offset:
    my $I_dc = $self->subtract( \@offset, $i );
    $I_dc->rename_col( $I_dc->get_colname(0), $name );
    $self->set( $I_dc, -1 );

    return @offset;

}

sub my_smoothing {
    my $self = shift;
    my $col  = shift;
    my $nn   = shift;
    my $name = shift;

    if ( not defined $name ) {
        $name = $col . "_smooth_$nn";
    }

    $col = $self->get_colnum($col);
    $self->eval("col[$name] = col[$col]");
    $col = $self->get_colnum("$name");

    my $stat = Statistics::Descriptive::Full->new();

    foreach my $block ( 0 .. $self->{BLOCKS} - 1 ) {
        my @values;
        foreach my $i (
            0 .. ( my $lines = @{ $self->{DATA}[$col][$block] } ) - 1 ) {
            if ( $i < $nn and $i < ( $lines - $nn - 1 ) ) {
                push( @values, $self->{DATA}[$col][$block][$i] );
            }
            elsif ( $i == $nn and $i <= ( $lines - $nn - 1 ) ) {
                foreach my $j ( 0 .. $nn ) {
                    push( @values, $self->{DATA}[$col][$block][ $i + $j ] );
                }
                $stat->clear();
                $stat->add_data(@values);
                $self->{DATA}[$col][$block][$i] = $stat->mean();
                shift @values;
            }
            elsif ( $i <= ( $lines - $nn - 1 ) ) {
                push( @values, $self->{DATA}[$col][$block][ $i + $nn ] );
                $stat->clear();
                $stat->add_data(@values);
                $self->{DATA}[$col][$block][$i] = $stat->mean();
                shift @values;
            }
        }
    }

    return $self;
}

sub differentiate_numerical {
    my $self = shift;
    my $v    = shift;
    my $i    = shift;
    my $name = shift;

    if ( not defined $name ) {
        $name = "Idc_diff_num";
    }

    $self->insert_c($name);
    my $di = $self->get_colnum("$name");

    $v = $self->get_colnum($v);
    $i = $self->get_colnum($i);
    if ( $v == -1 or $i == -1 ) {
        warn
            "WARNING: invalid parameters given for sub differentiate_numerical(). ";
        return $self;
    }

    # sort data:
    $self->sort( '+', $v );

    my @di;
    foreach my $block ( 0 .. $self->{BLOCKS} - 1 ) {

        # select data:
        my $x = $self->{DATA}->[$v][$block];
        my $y = $self->{DATA}->[$i][$block];

        # interpolate data:
        my $i = 0;
        foreach ( @{$x} ) {
            my ( $i_y, $i_dy ) = robust_interpolate( $_, $x, $y );
            $self->{DATA}->[$di][$block][$i] = $i_dy;
            $i++;
        }
    }

    return $self;

}

sub diff_num {
    my $self        = shift;
    my $x           = shift;
    my $y           = shift;
    my $N_smoothing = shift;

    if ( not defined $N_smoothing ) {
        $N_smoothing = 0;
    }

    my @x = @{$x};
    my @y = @{$y};

    # sort data:
    my @x_index = sort { $x[$a] <=> $x[$b] } ( 0 .. $#x );

    my @x_sorted = ();
    my @y_sorted = ();
    foreach my $index (@x_index) {
        $x_sorted[$index] = shift(@x);
        $y_sorted[$index] = shift(@y);
    }

    # do a weak smoothing:
    my $N = $N_smoothing;
    my @y_s;
    foreach my $i ( 0 .. ( my $length = @y_sorted ) - 1 ) {
        my $y_s = 0;
        for ( my $n = $i - $N; $n <= $i + $N; $n++ ) {
            if ( $n >= 0 and $n <= ( my $length = @y_sorted ) - 1 ) {
                $y_s += $y_sorted[$n];
            }
            elsif ( $n < 0 ) {
                $y_s += $y_sorted[0];
            }
            elsif ( $n > ( my $length = @y ) - 1 ) {
                $y_s += $y_sorted[-1];
            }
        }
        $y_s /= ( 2 * $N + 1 );
        push( @y_s, $y_s );
    }
    my $y  = @y;
    my $ys = @y_s;

    # interpolate data:
    my (@di) = derivatives( \@x_sorted, \@y_sorted );

    # sort data:
    my @x_index = sort { $x[$b] <=> $x[$a] } ( 0 .. $#x_sorted );

    my @x = ();
    my @y = ();
    my @y_smoothed;
    my @y_differentiated;
    foreach my $index (@x_index) {
        $x[$index]                = shift(@x_sorted);
        $y[$index]                = shift(@y_sorted);
        $y_smoothed[$index]       = shift(@y_s);
        $y_differentiated[$index] = shift(@di);
    }

    return @y_differentiated;
}

sub offset_correction_vdc {
    my $self    = shift;
    my $v       = shift;
    my $i       = shift;
    my @v_range = ( shift, shift );
    my $name    = shift;

    if ( not defined $name ) {
        $name = "Vdc_offset_corrected";
    }

    $v = $self->get_colnum($v);
    $i = $self->get_colnum($i);
    if ( $v == -1 or $i == -1 ) {
        warn
            "WARNING: invalid parameters given for sub offset_correction_vdc(). ";
        return $self;
    }

    # find relevant datapoints around V_sd == 0:
    my $selection = $self->eval("$v_range[0] <= col[V_sd] <= $v_range[1]");

    # extract minimum for each linetrace:
    my @Vdc_min;
    my $stat             = Statistics::Descriptive::Full->new();
    my $number_of_blocks = @{ $self->{DATA}[$i] };
    foreach my $block ( 0 .. $number_of_blocks - 1 ) {
        $stat->clear();
        $stat->add_data( $self->{DATA}[$i][$block] );
        push( @Vdc_min, $self->{DATA}[$v][$block][ $stat->mindex() ] );
    }

    # take median value of the minimas as the Vdc-offset:
    $stat->clear();
    $stat->add_data(@Vdc_min);
    my $vdc_offset = $stat->median();

    # subtract offset:
    $self->eval("col[$name] = col[$v]-$vdc_offset");

    return $vdc_offset;

}

sub mask_bad_datapoints_around_zero {
    my $self = shift;
    my $x    = shift;

    $x = $self->get_colnum($x);
    if ( $x == -1 ) {
        warn
            "WARNING: invalid parameters given for sub offset_correction_vdc(). ";
        return $self;
    }
    $self->eval("col[temp] = abs(col[$x])");
    my $temp              = $self->get_colnum("temp");
    my $stat              = Statistics::Descriptive::Full->new();
    my $number_of_blocks  = @{ $self->{DATA}[$x] };
    my $number_of_columns = @{ $self->{DATA} };
    foreach my $block ( 0 .. $number_of_blocks - 1 ) {
        $stat->clear();
        $stat->add_data( $self->{DATA}[$temp][$block] );
        my $mindex = $stat->mindex();
        foreach my $column ( "R_dc", "G_dc" ) {
            splice(
                @{ $self->{DATA}[ $self->get_colnum($column) ][$block] },
                $mindex, 1, '?'
            );
        }
    }
    $self->delete_c($temp);
    return $self;

}

1;
