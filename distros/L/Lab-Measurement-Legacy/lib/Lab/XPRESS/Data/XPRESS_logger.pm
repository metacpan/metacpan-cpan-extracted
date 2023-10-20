package Lab::XPRESS::Data::XPRESS_logger;
#ABSTRACT: XPRESS logging module
$Lab::XPRESS::Data::XPRESS_logger::VERSION = '3.899';
use v5.20;


use Time::HiRes qw/usleep/, qw/time/;
use strict;

use Lab::XPRESS::Data::XPRESS_plotter;
use Carp;
use File::Path 'make_path';

sub new {
    my $proto        = shift;
    my $class        = ref($proto) || $proto;
    my $filenamebase = shift;
    my $plots        = shift;

    my $self = {};
    bless( $self, $class );

    ( $self->{filehandle}, $self->{filename}, $self->{directory} )
        = $self->open_file($filenamebase);
    $self->{block_num} = 0;
    $self->{line_num}  = 0;

    # check if $plots is an ARRAY-REF or just a single plot
    my $num_of_plots;
    if ( not defined $plots ) {
        $num_of_plots = 0;
    }
    elsif ( ref($plots) eq 'ARRAY' ) {
        $self->{plots} = $plots;
        $num_of_plots = @{ $self->{plots} };
    }
    else {
        $self->{plots} = [$plots];
        $num_of_plots = @{ $self->{plots} };
    }

    # create gnuplot-pipes for each plot:
    for ( my $i = 0; $i < $num_of_plots; $i++ ) {
        $self->{plots}->[$i]->{plotter}
            = new Lab::XPRESS::Data::XPRESS_plotter(
            $self->{filename},
            $self->{plots}->[$i]
            );
        $self->{plots}->[$i]->{plotter}->{ID}       = $i;
        $self->{plots}->[$i]->{plotter}->{FILENAME} = $self->{filename};
        $self->{plots}->[$i]->{plotter}->{COLUMN_NAMES}
            = $self->{COLUMN_NAMES};
        $self->{plots}->[$i]->{plotter}->{BLOCK_NUM} = $self->{block_num};
        $self->{plots}->[$i]->{plotter}->{LINE_NUM}  = $self->{line_num};
        $self->{plots}->[$i]->{plotter}->init_gnuplot();
    }

    return $self;

}

sub open_file {
    my $self         = shift;
    my $filenamebase = shift;

    # split directory/filname ..
    if ( $filenamebase =~ /(.+)(\/|\/\/|\\|\\\\)(.+)\b/ ) {
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
            carp "directory given by $filenamebase doesn't exist."
		. "Creating directory $directory";
            make_path $directory
		or croak "cannot create path $directory: $!";
        }

        # look for existing files:
        opendir( DIR, $directory );
        my @files     = readdir(DIR);
        my $max_index = 0;
        foreach my $file (@files) {

            my $temp_filename = $filename;
            $temp_filename =~ s/\(/\\\(/g;
            $temp_filename =~ s/\)/\\\)/g;

            #print $temp_filename."\n";
            if ( $file =~ /($temp_filename)(_(\d+))?($filenameextension)\b/ )
            {
                if ( $3 > $max_index ) {
                    $max_index = $3;
                }
                elsif ( not defined $3 ) {
                    $max_index = 1;
                }
            }

        }
        closedir(DIR);
        $max_index++;

        my $file_data;

        # open new file:
        if ( $max_index > 1 ) {
            $file_data = sprintf(
                "%s/%s_%03d%s",
                $directory, $filename, $max_index, $filenameextension
            );
        }
        else {
            $file_data = sprintf(
                "%s/%s%s", $directory, $filename,
                $filenameextension
            );
        }

        open( my $LOG, ">" . $file_data ) or die "cannot open $file_data";
        my $old_fh = select($LOG);
        $| = 1;
        select($old_fh);
        print "Output file is \"$file_data\"\n";

        return ( $LOG, $file_data, $directory );
    }

}

sub close_file {
    my $self = shift;

    my $file = $self->{filehandle};
    close $file;
    delete $self->{filehandle};

    return $self;
}

sub add_plots {
    my $self  = shift;
    my $plots = shift;

    # check if $plots is an ARRAY-REF or just a single plot
    #print "$self->{plots}";
    my $num_of_plots            = @{ $self->{plots} };
    my $allready_existing_plots = $num_of_plots;

    if ( not defined $plots ) {
        return $num_of_plots;
    }
    elsif ( ref($plots) eq 'ARRAY' ) {
        foreach ( @{$plots} ) {
            push( @{ $self->{plots} }, $_ );
        }
        $num_of_plots = @{ $self->{plots} };
    }
    else {
        push( @{ $self->{plots} }, $plots );
        $num_of_plots = @{ $self->{plots} };
    }

    # foreach my $plot (@{$self->{plots}})
    # {
    # foreach (@{$plot->{'y-axis'}})
    # {
    # print  "y-axis = ".$_."\n";
    # }
    # }

    # create gnuplot-pipes for each plot:
    for ( my $i = $allready_existing_plots; $i < $num_of_plots; $i++ ) {
        $self->{plots}->[$i]->{plotter}
            = new Lab::XPRESS::Data::XPRESS_plotter(
            $self->{filename},
            $self->{plots}->[$i]
            );
        $self->{plots}->[$i]->{plotter}->{ID}       = $i;
        $self->{plots}->[$i]->{plotter}->{FILENAME} = $self->{filename};
        $self->{plots}->[$i]->{plotter}->{COLUMN_NAMES}
            = $self->{COLUMN_NAMES};
        $self->{plots}->[$i]->{plotter}->{NUMBER_OF_COLUMNS}
            = $self->{NUMBER_OF_COLUMNS};
        $self->{plots}->[$i]->{plotter}->{BLOCK_NUM} = $self->{block_num};
        $self->{plots}->[$i]->{plotter}->{LINE_NUM}  = $self->{line_num};
        $self->{plots}->[$i]->{plotter}->init_gnuplot();
    }

    return $self;
}

sub _log_start_block {
    my $self  = shift;
    my @plots = @{ $self->{plots} };

    my $fh = $self->{filehandle};
    if ( $self->{block_num} ) {
        $self->LOG('NEW_BLOCK');
    }
    $self->{block_num}++;
    $self->{line_num} = 0;

    #my $num_of_plots = @plots;
    #for( my $i = 0; $i < $num_of_plots; $i++)
    #	{

    #if ( $self->{plots}->[$i]->{'type'} =~/\b(linetrace|LINETRACE|trace|TRACE)\b/ )
    #	{
    #	my $filename = $self->{filename};
    #	if ( defined $self->{plots}->[$i]->{plotter}->{'started'})
    #		{
    #		$self->{plots}->[$i]->{plotter}->{linetrace_logger}->close_file();
    #		delete $self->{plots}->[$i]->{plotter};
    #		print "delete plotter\n";
    #		}
    #	my $block_num = $self->{'block_num'};
    #	$filename =~ /\b(.+)\.(.+)\b/;
    #	my $linetrace = sprintf("%s_linetrace", $1);
    #	$self->{plots}->[$i]->{plotter} = new Lab::Data::SG_plotter($linetrace,$self->{plots}->[$i]);
    #	$self->{plots}->[$i]->{plotter}->{linetrace_logger} = new Lab::Data::SG_logger($linetrace, $self->{plots}->[$i]);
    #	}

    #	}

    if ( $self->{block_num} == 1 ) {
        foreach my $plot ( @{ $self->{plots} } ) {
            $plot->{plotter}->init_gnuplot_bindings();
        }
    }
    elsif ( $self->{block_num} > 1 ) {
        foreach my $plot ( @{ $self->{plots} } ) {
            $plot->{plotter}->start_plot( $self->{block_num} );
        }
    }

    return $self->{block_num};
}

sub LOG {
    my $self = shift;
    my $data = shift;

    my $filehandle = $self->{filehandle};
    $self->{line_num}++;

    if ( $data =~ /^#/ ) {
        print $filehandle $data . "\n";
        return 1;
    }
    elsif ( $data eq 'NEW_BLOCK' ) {
        print $filehandle "\n";
        return 1;
    }

    # log data:
    if ( ref($data) eq 'ARRAY' ) {
        my @data = @$data;

        my $number_of_columns = 0;
        foreach my $item (@data) {
            if ( ref($item) eq 'ARRAY' ) {
                $number_of_columns++;
            }
            else {
                last;
            }
        }

        if ( $number_of_columns >= 1 ) {
            my $j = 0;
            while ( defined $data[0][$j] ) {
                for ( my $i = 0; $i < $number_of_columns; $i++ ) {

                    # if ($data[$i][$j] =~ /[[:alpha:]]/ or  not $data[$i][$j] =~ /[[:alnum:]]/)
                    # {
                    # print $filehandle $data[$i][$j]."\t";
                    # #print $data[$i][$j]."\t";
                    # }
                    # else
                    # {
                    # print $filehandle sprintf("%.6e\t",$data[$i][$j]);
                    # #print sprintf("%.6e\t",$data[$i][$j]);
                    # }
                    if ( $data[$i][$j]
                        =~ /(^[-+]?[0-9]+)\.?([0-9]+)?([eE][-+]?[0-9]+)?$/ ) {
                        print $filehandle sprintf( "%+.6e\t", $data[$i][$j] );
                        if ( $data[$i][$j] < $self->{DATA}[$i][0]
                            or not defined $self->{DATA}[$i][0] ) {
                            $self->{DATA}[$i][0] = $data[$i][$j];
                        }
                        elsif ( $data[$i][$j] > $self->{DATA}[$i][1]
                            or not defined $self->{DATA}[$i][0] ) {
                            $self->{DATA}[$i][1] = $data[$i][$j];
                        }

                        #print sprintf("%.6e\t",$data[$i][$j]);
                    }
                    else {
                        print $filehandle $data[$i][$j] . "\t";

                        #print $data[$i][$j]."\t";
                    }
                }
                print $filehandle "\n";

                #print "\n";
                $j++;
            }

        }
        else {
            my $i = 0;
            foreach my $value (@data) {

                # if ($value =~ /[[:alpha:]]/ or  not $value =~ /[[:alnum:]]/)
                # {
                # print $filehandle $value."\t";
                # #print $value."\t";
                # }
                # else
                # {
                # print $filehandle sprintf("%.6e\t",$value);
                # #print sprintf("%.6e\t",$value);
                # }
                if ( $value
                    =~ /(^[-+]?[0-9]+)\.?([0-9]+)?([eE][-+]?[0-9]+)?$/ ) {
                    print $filehandle sprintf( "%+.6e\t", $value );
                    if ( $value < $self->{DATA}[$i][0]
                        or not defined $self->{DATA}[$i][0] ) {
                        $self->{DATA}[$i][0] = $value;
                    }
                    elsif ( $value > $self->{DATA}[$i][1]
                        or not defined $self->{DATA}[$i][0] ) {
                        $self->{DATA}[$i][1] = $value;
                    }

                    #print sprintf("%.6e\t",$value);
                }
                else {
                    print $filehandle $value . "\t";

                    #print $value."\t";
                }
                $i++;
            }
            print $filehandle "\n";

            #print "\n";
        }
    }

    elsif ( ref($data) eq 'HASH' ) {
        my @logline;
        while ( my ( $key, $value ) = each %{ $self->{COLUMN_NAMES} } ) {
            $logline[$value] = $data->{$key};
        }
        shift @logline;
        my $logline = join( "\t", @logline );
        print $filehandle $logline . "\n";

    }
    else {
        # if ($data =~ /[[:alpha:]]/ or  not $data =~ /[[:alnum:]]/)
        # {
        # print $filehandle $data."\t";
        # #print $value."\t";
        # }
        # else
        # {
        # print $filehandle sprintf("%.6e\t",$data);
        # #print sprintf("%.6e\t",$value);
        # }
        if ( $data =~ /(^[-+]?[0-9]+)\.?([0-9]+)?([eE][-+]?[0-9]+)?$/ ) {
            print $filehandle sprintf( "%+.6e\t", $data );
            if ( $data < $self->{DATA}[0][0]
                or not defined $self->{DATA}[0][0] ) {
                $self->{DATA}[0][0] = $data;
            }
            elsif ( $data > $self->{DATA}[0][1]
                or not defined $self->{DATA}[0][0] ) {
                $self->{DATA}[0][1] = $data;
            }

            #print sprintf("%.6e\t",$value);
        }
        else {
            print $filehandle $data . "\t";

            #print $value."\t";
        }
        print $filehandle "\n";

        #print "\n";
    }

    #		foreach my $item (@data)
    #			{
    #			if ( ref($item) eq 'ARRAY')
    #				{
    #				my @item = @$item;
    #
    #				foreach my $value (@item)
    #					{
    #					if ($value =~ /[[:alpha:]]/ or  not $value =~ /[[:alnum:]]/)
    #						{
    #						print $filehandle $value."\t";
    #						#print $value."\t";
    #						}
    #					else
    #						{
    #						print $filehandle sprintf("%.6e\t",$value);
    #						#print sprintf("%.6e\t",$value);
    #						}
    #					}
    #				print $filehandle "\n";
    #				#print "\n";
    #				}
    #			else
    #				{
    #				if ( $item =~ /[[:alpha:]]/ or not $item =~ /[[:alnum:]]/)
    #					{
    #					print $filehandle $item."\t";
    #					#print $item."\t";
    #					}
    #				else
    #					{
    #					print $filehandle sprintf("%.6e\t",$item);
    #					#print sprintf("%.6e\t",$item);
    #					}
    #				}
    #			}
    #			print $filehandle "\n";
    #			#print "\n";
    #		}
    #	else
    #		{
    #		if ( $data =~ /[[:alpha:]]/ or not $data =~ /[[:alnum:]]/)
    #			{
    #			print $filehandle $data."\n";
    #			#print $data."\n";
    #			}
    #		else
    #			{
    #			print $filehandle sprintf("%.6e\n",$data);
    #			#print sprintf("%.6e\n",$data);
    #			}
    #		}

    # update plots:
    if ( not defined $self->{plots} ) {
        return 1;
    }
    my $number_of_plots = @{ $self->{plots} };
    for ( my $i = 0; $i < $number_of_plots; $i++ ) {

        # log data for linetrace-plots:

        #if ( $self->{plots}->[$i]->{plotter}->{plot}->{'type'} =~ /\b(linetrace|LINETRACE|trace|TRACE)\b/ )
        #	{
        #	$self->{plots}->[$i]->{plotter}->{linetrace_logger}->LOG_linetrace($data);
        #	}

        if ( not defined $self->{plots}->[$i]->{plotter}->{plot}->{started} )
        {

            # start plot:
            if ( $self->{plots}->[$i]->{plotter}->{plot}->{'type'} eq 'pm3d'
                and $self->{block_num} <= 1 ) {

                # start plot later
            }
            else {
                $self->{plots}->[$i]->{plotter}
                    ->start_plot( $self->{block_num} );
            }
        }
        else {
            # replot:
            $self->{plots}->[$i]->{plotter}->replot();
        }

    }

    return 1;

}

sub LOG_linetrace {
    my $self = shift;
    my $data = shift;

    my $filehandle = $self->{filehandle};

    # log data:
    if ( ref($data) eq 'ARRAY' ) {
        my @data = @$data;

        my $number_of_columns = 0;
        foreach my $item (@data) {
            if ( ref($item) eq 'ARRAY' ) {
                $number_of_columns++;
            }
            else {
                last;
            }
        }

        if ( $number_of_columns >= 1 ) {
            my $j = 0;
            while ( defined $data[0][$j] ) {
                for ( my $i = 0; $i < $number_of_columns; $i++ ) {
                    if ( $data[$i][$j] =~ /[[:alpha:]]/
                        or not $data[$i][$j] =~ /[[:alnum:]]/ ) {
                        print $filehandle $data[$i][$j] . "\t";

                        #print $data[$i][$j]."\t";
                    }
                    else {
                        print $filehandle sprintf( "%.6e\t", $data[$i][$j] );

                        #print sprintf("%.6e\t",$data[$i][$j]);
                    }
                }
                print $filehandle "\n";

                #print "\n";
                $j++;
            }

        }
        else {
            foreach my $value (@data) {
                if ( $value =~ /[[:alpha:]]/ or not $value =~ /[[:alnum:]]/ )
                {
                    print $filehandle $value . "\t";

                    #print $value."\t";
                }
                else {
                    print $filehandle sprintf( "%.6e\t", $value );

                    #print sprintf("%.6e\t",$value);
                }
            }
            print $filehandle "\n";

            #print "\n";
        }
    }
    else {
        if ( $data =~ /[[:alpha:]]/ or not $data =~ /[[:alnum:]]/ ) {
            print $filehandle $data . "\t";

            #print $value."\t";
        }
        else {
            print $filehandle sprintf( "%.6e\t", $data );

            #print sprintf("%.6e\t",$value);
        }
        print $filehandle "\n";

        #print "\n";
    }

    return 1;

}

sub DESTROY {

    my $self = shift;

    foreach my $plot ( @{ $self->{plots} } ) {
        $plot->{plotter}->_stop_live_plot();
        $plot->{plotter};
    }
    $self->close_file();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Data::XPRESS_logger - XPRESS logging module (deprecated)

=head1 VERSION

version 3.899

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
