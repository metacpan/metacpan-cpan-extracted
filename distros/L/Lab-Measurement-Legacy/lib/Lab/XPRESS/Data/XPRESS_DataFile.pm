package Lab::XPRESS::Data::XPRESS_DataFile;
$Lab::XPRESS::Data::XPRESS_DataFile::VERSION = '3.899';
#ABSTRACT: XPRESS data file module

use v5.20;

use strict;
use Time::HiRes qw/usleep/, qw/time/;
use Storable qw(dclone);
use File::Copy;
use Lab::XPRESS::Data::XPRESS_logger;
use Lab::XPRESS::Sweep;

our $counter        = 0;
our $GLOBAL_PATH    = "./";
our $GLOBAL_FOLDER  = undef;
our $DEFAULT_FOLDER = "MEAS";
our $DEFAULT_HEADER = "#";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->{COLUMN_NAMES};
    $self->{NUMBER_OF_COLUMNS} = 0;
    $self->{COLUMNS}           = ();
    $self->{BLOCK_NUM}         = 0;
    $self->{LOG_STARTED}       = 0;
    $self->{loop}->{interval}  = 1;
    $self->{loop}->{overtime}  = 0;

    $self->{autolog} = 1;
    $self->{skiplog} = 0;

    my $filenamebase = shift;

    if ( not $filenamebase =~ /(.+)(\..+)\b/ ) {
        $filenamebase .= ".dat";
    }

    my $foldername = $DEFAULT_FOLDER;
    $foldername = shift if @_;

    $self->{filenamebase} = $filenamebase;

    my @plots = @_;
    $self->{plots} = [];
    foreach my $plot (@plots) {
        $self->add_plot($plot);
    }

    $self->{plot_count} = @plots;

    # create file-handle:
    $self->{filenamebase}
        = $self->create_folder( $self->{filenamebase}, $foldername );

    $self->open_logger( $self->{filenamebase}, $self->{plots} );
    $self->{file} = $self->{filenamebase};

    return $self;

}

sub create_folder {

    my $self         = shift;
    my $filenamebase = shift;
    my $foldername   = shift || $DEFAULT_FOLDER;

    $filenamebase =~ s/\\/\//g;
    $filenamebase =~ s/\.\///g;
    $filenamebase =~ s/\.\.\///g;
    $filenamebase =~ s/[a-zA-Z]\:\///g;

    my @filename = split( /\//, $filenamebase );
    my $filename = pop(@filename);

    my $folder = join( '/', @filename );

    if ( not defined $GLOBAL_FOLDER ) {
        if ( not -d $GLOBAL_PATH ) {
            mkdir $GLOBAL_PATH;
        }

        # look for existing files:
        opendir( DIR, $GLOBAL_PATH );
        my @files = readdir(DIR);

        my $max_index = 0;
        foreach my $file (@files) {

            if ( $file =~ /($foldername)_([0-9]+)\b/ ) {
                if ( $2 > $max_index ) {
                    $max_index = $2;
                }
                $max_index++;
            }
        }

        closedir(DIR);

        $GLOBAL_PATH =~ s/\/$//;
        $GLOBAL_FOLDER
            = sprintf( "%s/%s_%03d", $GLOBAL_PATH, $foldername, $max_index );

        mkdir($GLOBAL_FOLDER);

        copy( $0, $GLOBAL_FOLDER );

        $self->create_InfoFile();
    }

    my $folder = $GLOBAL_FOLDER . "/" . $folder;

    return $folder . "/" . $filename;

}

sub create_InfoFile {
    my $self = shift;

    open( my $LOG, ">" . $GLOBAL_FOLDER . "/Config.txt" )
        or die "cannot open Config.txt";
    print $LOG "Instrument Configuration\n";
    print $LOG "-" x 100, "\n\n";
    print $LOG $self->timestamp(), "\n";
    print $LOG "-" x 100, "\n\n";

    foreach my $instrument ( @{Lab::Instrument::REGISTERED_INSTRUMENTS} ) {
        print $LOG $instrument->get_id() . " ( "
            . $instrument->get_name()
            . " )", "\n\n";
        print $LOG $instrument->sprint_config(), "\n";
        print $LOG "-" x 100, "\n\n";
    }

}

# ------------------------------- CONFIG ---------------------------------------------------------
sub add_measurement {
    my $self    = shift;
    my $methode = shift;

    my $name = "measurement";
    $self->{measurement} = $methode;

    my $package = ref($self) . "_" . $counter++;

    no strict 'refs';
    *{ $package . "::" . $name } = $methode;
    @{ $package . '::ISA' } = ( ref($self) );
    bless $self, $package;

    return $self;
}

sub add_header {
    my $self   = shift;
    my $header = shift;

    if ( not defined $header ) {
        return $self->{HEADER};
    }

    my @header = split( /\n/, $header );
    foreach (@header) {
        $self->{HEADER} .= "#HEADER#\t" . $_ . "\n";
    }

    return $self;
}

sub add_config {
    my $self   = shift;
    my $config = shift;

    if ( not defined $config ) {
        return $self->{CONFIG};
    }

    my @config = split( /\n/, $config );
    foreach (@config) {
        $self->{HEADER} .= "#CONFIG#\t" . $_ . "\n";
    }

    return $self;
}

sub add_column {
    my $self = shift;
    my $col  = shift;

    if ( eval "return exists &Lab::XPRESS::Sweep::$col;" ) {
        Lab::Exception::Warning->throw(
            "$col is not an alowed column name. Sorry. \n");
    }

    if ( not defined $col ) {
        return $self->{COLUMNS};
    }

    $self->{COLUMN_NAMES}{$col}
        = scalar( keys %{ $self->{COLUMN_NAMES} } ) + 1;
    push( @{ $self->{COLUMNS} }, $col );
    $self->{NUMBER_OF_COLUMNS} += 1;
    $self->{logger}->{COLUMN_NAMES}      = $self->{COLUMN_NAMES};
    $self->{logger}->{NUMBER_OF_COLUMNS} = $self->{NUMBER_OF_COLUMNS};
    return $self;
}

sub add_plot {
    my $self = shift;
    my $plot;

    if ( ref( @_[0] ) eq 'HASH' ) {
        $plot = @_[0];
    }
    else {
        $plot = shift;
    }

    if ( not defined $plot->{'autosave'} ) {
        $plot->{'autosave'} = 'last';
    }
    push( @{ $self->{plots} }, $plot );
    $self->{logger}->{COLUMN_NAMES}
        = $self->{COLUMN_NAMES};    # refresh logger->column_names
    my $plot_copy = dclone( \%{$plot} );
    $self->{logger}->add_plots($plot_copy);
    $self->{plot_count}++;

    return $self;
}

sub open_logger {
    my $self         = shift;
    my $filenamebase = shift;
    my $plots        = shift;

    my $plots_copy = [];

    if ( defined $plots ) {
        my $plots_copy = dclone($plots);
    }

    $self->{logger}
        = new Lab::XPRESS::Data::XPRESS_logger( $filenamebase, $plots_copy );
    $self->{logger}->{COLUMN_NAMES} = $self->{COLUMN_NAMES};
}

sub change_filenamebase {
    my $self         = shift;
    my $filenamebase = shift;
    if ( not $filenamebase =~ /\// ) {
        $filenamebase = "./" . $filenamebase;
    }

    #$self->{filenamebase} = $filenamebase;

    my $old_file      = $self->{logger}->{filename};
    my $old_directory = $self->{logger}->{directory};

    delete $self->{logger};
    $self->{LOG_STARTED} = 0;

    if ( -z $old_file ) {
        unlink $old_file;
    }

    $self->open_logger($filenamebase);
    $self->{file} = $self->{logger}->{filename};

    $self->{logger}->{COLUMN_NAMES}      = $self->{COLUMN_NAMES};
    $self->{logger}->{NUMBER_OF_COLUMNS} = $self->{NUMBER_OF_COLUMNS};

    my $plots_copy = dclone( $self->{plots} );
    $self->{logger}->add_plots($plots_copy);

}

sub start_log {
    my $self = shift;

    if ( defined $self->{HEADER} ) {
        chomp $self->{HEADER};
        $self->{logger}->LOG( $self->{HEADER} );
    }
    if ( defined $self->{CONFIG} ) {
        $self->{logger}->LOG( $self->{CONFIG} );
    }
    if ( defined @{ $self->{COLUMNS} }[0] ) {
        my $columns = $DEFAULT_HEADER;
        $columns .= join( "\t", @{ $self->{COLUMNS} } );

        $self->{logger}->LOG($columns);
    }
    $self->{LOG_STARTED} = 1;
    return $self;
}

sub start_block {
    my $self = shift;

    if ( not $self->{LOG_STARTED} ) {
        $self->start_log();
    }

    $self->{BLOCK_NUM} = $self->{logger}->_log_start_block();
    print "Data block $self->{BLOCK_NUM}\n";

    $self->{loop}->{overtime} = 0;
    undef $self->{loop}->{t0};

    return 1;

}

sub set_loop_interval {
    my $self     = shift;
    my $interval = shift;

    $self->{loop}->{interval} = $interval;

    return $self;

}

sub end_loop {

    my $self = shift;

    $self->{loop}->{t1} = time();

    if ( not defined $self->{loop}->{t0} ) {
        $self->{loop}->{t0} = time();
        return 0;
    }

    my $delta_time = ( $self->{loop}->{t1} - $self->{loop}->{t0} )
        ;    # + $self->{loop}->{overtime};
    if ( $delta_time > $self->{loop}->{interval} ) {
        $self->{loop}->{overtime} = $delta_time - $self->{loop}->{interval};
        $delta_time = $self->{loop}->{interval};
        warn
            "WARNING: Measurement Loop takes more time ($self->{loop}->{overtime}) than specified by measurement interval ($self->{loop}->{interval}).\n";
    }
    else {
        $self->{loop}->{overtime} = 0;
    }
    usleep( ( $self->{loop}->{interval} - $delta_time ) * 1e6 );
    $self->{loop}->{t0} = time();
    return $delta_time;

}

sub timestamp {

    my $self = shift;
    my (
        $Sekunden, $Minuten,   $Stunden,   $Monatstag, $Monat,
        $Jahr,     $Wochentag, $Jahrestag, $Sommerzeit
    ) = localtime(time);

    $Monat     += 1;
    $Jahrestag += 1;
    $Monat     = $Monat < 10     ? $Monat     = "0" . $Monat     : $Monat;
    $Monatstag = $Monatstag < 10 ? $Monatstag = "0" . $Monatstag : $Monatstag;
    $Stunden   = $Stunden < 10   ? $Stunden   = "0" . $Stunden   : $Stunden;
    $Minuten   = $Minuten < 10   ? $Minuten   = "0" . $Minuten   : $Minuten;
    $Sekunden  = $Sekunden < 10  ? $Sekunden  = "0" . $Sekunden  : $Sekunden;
    $Jahr += 1900;

    return "$Stunden:$Minuten:$Sekunden  $Monatstag.$Monat.$Jahr\n";

}

sub finish_measurement {
    my $self = shift;

    my $num_of_plots = @{ $self->{logger}->{plots} };
    for ( my $i = 0; $i < $num_of_plots; $i++ ) {

        # close gnuplot-pipe:
        $self->{logger}->{plots}->[$i]->{plotter}->_stop_live_plot();
    }

    $self = $self->{logger}->close_file();

    delete $self->{logger};
    return $self;
}

sub save_plot {
    my $self       = shift;
    my $plot_index = shift;
    my $type       = shift;
    my $filename   = shift;

    if ( not defined $plot_index ) {
        $plot_index = 0;
    }
    elsif ( $plot_index > ( my $num_plots = @{ $self->{logger}->{plots} } ) )
    {
        warn "defined plotnumber $plot_index doesn't exist.";
    }

    if ( not defined $filename ) {

        # create filename for saving plot as eps-file:
        $filename = $self->{logger}->{filename};
        $filename =~ /(.+)\.(.+)\b/;
        $filename = sprintf( "%s_%02d", $1, $plot_index + 1 );
    }

    if ( not defined $type ) {
        $type = 'png';
    }

    $self->{logger}->{plots}->[$plot_index]->{plotter}->replot();
    $self->{logger}->{plots}->[$plot_index]->{plotter}
        ->save_plot( $type, $filename );

    return $self;

}

sub LOG {
    my $self = shift;

    if ( $self->{skiplog} == 1 ) {
        $self->{skiplog} = 0;
        return $self;
    }

    if ( not $self->{LOG_STARTED} ) {
        $self->start_log();
    }

    if ( ref( $_[0] ) eq "HASH" ) {
        $self->{logger}->LOG(@_);
    }
    else {
        $self->{logger}->LOG( \@_ );
    }

    return $self;
}

sub set_autolog {
    my $self  = shift;
    my $value = shift;

    $self->{autolog} = $value;

    return $self;
}

sub skiplog {
    my $self = shift;

    $self->{skiplog} = 1;

    return $self;
}

sub gnuplot_cmd {
    my $self       = shift;
    my $plot_index = shift;
    my $cmd        = shift;

    if ( not defined $cmd ) {
        $cmd        = $plot_index;
        $plot_index = 0;
    }

    if ( $plot_index > ( my $num_plots = @{ $self->{logger}->{plots} } ) ) {
        warn "defined plotnumber $plot_index doesn't exist.";
    }

    $self->{logger}->{plots}->[$plot_index]->{plotter}->gnuplot_cmd($cmd);

    return $self;

}

sub gnuplot_init_bindings {
    my $self = shift;

    foreach my $plot ( @{ $self->{logger}->{plots} } ) {
        $plot->{plotter}->init_gnuplot_bindings();
    }

    return 1;
}

sub gnuplot_restart {
    my $self = shift;

    my $i = 0;
    foreach my $plot ( @{ $self->{logger}->{plots} } ) {
        if ( $plot->{plotter}->{PAUSE} < 0 ) {
            $self->gnuplot_pause();
        }

        my $gpipe = $plot->{plotter}->{gpipe};
        if ( not defined $gpipe ) {
            $plot->{plotter} = new Lab::XPRESS::Data::XPRESS_plotter(
                $self->{logger}->{filename}, $plot );
            $plot->{plotter}->{ID}       = $i;
            $plot->{plotter}->{FILENAME} = $self->{logger}->{filename};
            $plot->{plotter}->{COLUMN_NAMES}
                = $self->{logger}->{COLUMN_NAMES};
        }
        elsif ( not( my $result = print $gpipe "" ) ) {
            $plot->{plotter} = new Lab::XPRESS::Data::XPRESS_plotter(
                $self->{logger}->{filename}, $plot );
            $plot->{plotter}->{ID}       = $i;
            $plot->{plotter}->{FILENAME} = $self->{logger}->{filename};
            $plot->{plotter}->{COLUMN_NAMES}
                = $self->{logger}->{COLUMN_NAMES};
        }

        $plot->{plotter}->init_gnuplot();
        $plot->{plotter}->init_gnuplot_bindings();
        $plot->{plotter}->start_plot( $self->{BLOCK_NUM} );

        if ( $plot->{plotter}->{PAUSE} > 0 ) {
            $self->gnuplot_pause();
        }

        $i++;
    }

    return 1;
}

sub gnuplot_pause {
    my $self = shift;

    foreach my $plot ( @{ $self->{logger}->{plots} } ) {
        $plot->{plotter}->toggle_pause();
    }

    return 1;
}

sub datazone {
    my $self       = shift;
    my $plot_index = shift;
    my $left       = shift;
    my $center     = shift;
    my $right      = shift;

    my $x_min;
    my $x_max;
    my $y_min;
    my $y_max;

    my %plot
        = %{ $self->{logger}->{plots}->[$plot_index]->{plotter}->{plot} };
    if ( not defined $plot{'x-min'} ) {
        $x_min = $self->{logger}->{DATA}[ $plot{'x-axis'} - 1 ][0];
    }
    else {
        $x_min = $plot{'x-min'};
    }
    if ( not defined $plot{'x-max'} ) {
        $x_max = $self->{logger}->{DATA}[ $plot{'x-axis'} - 1 ][1];
    }
    else {
        $x_max = $plot{'x-max'};
    }
    if ( not defined $plot{'y-min'} ) {
        $y_min = $self->{logger}->{DATA}[ $plot{'y-axis'} - 1 ][0];
    }
    else {
        $y_min = $plot{'y-min'};
    }
    if ( not defined $plot{'y-max'} ) {
        $y_max = $self->{logger}->{DATA}[ $plot{'y-axis'} - 1 ][1];
    }
    else {
        $y_max = $plot{'y-max'};
    }
    $self->{logger}->{plots}->[$plot_index]->{plotter}
        ->datazone( $x_min, $x_max, $y_min, $y_max, $left, $center, $right );

    return $self;

}

sub DESTROY {
    my $self = shift;
    if ( $self->{writer} ) {
        $self->finish_measurement();
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Data::XPRESS_DataFile - XPRESS data file module (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
