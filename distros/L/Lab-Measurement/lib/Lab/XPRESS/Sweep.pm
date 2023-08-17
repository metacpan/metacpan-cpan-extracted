package Lab::XPRESS::Sweep;
$Lab::XPRESS::Sweep::VERSION = '3.881';
#ABSTRACT: Base sweep class

use v5.20;

use Role::Tiny::With;

use Time::HiRes qw/usleep/, qw/time/;
use POSIX qw(ceil);
use Term::ReadKey;
use Storable qw(dclone);
use Lab::Generic;
use Lab::XPRESS::Sweep::Dummy;
use Lab::XPRESS::Utilities::Utilities;
use Lab::Exception;
use Carp;
use strict;

use Storable qw(dclone);
$Storable::forgive_me = 1;

use Carp qw(cluck croak);

our @ISA = ('Lab::Generic');

our $PAUSE         = 0;
our $ACTIVE_SWEEPS = ();

our $AUTOLOAD;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);

    $self->{default_config} = {
        instrument          => undef,
        allowed_instruments => [undef],

        interval          => 0,
        mode              => 'dummy',
        delay_before_loop => 0,
        delay_in_loop     => 0,
        delay_after_loop  => 0,
        before_loop       => undef,

        points => [ undef, undef ],

        rate     => [undef],
        duration => [undef],

        stepwidth        => [undef],
        number_of_points => [undef],

        backsweep   => 0,
        repetitions => 1,

        separate_files => 0,
        folders        => 1,

        filename_extension => '#'
    };

    $self->{LOG} = ();
    @{ $self->{LOG} }[0] = {};

    # deep copy $default_config:
    while ( my ( $k, $v ) = each %{ $self->{default_config} } ) {
        if ( ref($v) eq 'ARRAY' ) {
            $self->{config}->{$k} = ();
            foreach ( @{$v} ) {
                push( @{ $self->{config}->{$k} }, $_ );
            }
        }
        else {
            $self->{config}->{$k} = $v;
        }
    }

    my $type = ref $_[0];

    if ( $type =~ /HASH/ ) {
        %{ $self->{config} }
            = ( %{ $self->{config} }, %{ shift @_ }, %{ shift @_ } );
    }

    #for debugging: print config parameters:
    # while ( my ($k,$v) = each %{$self->{config}} )
    #  {
    #  print "$k => $v\n";
    #  }
    # print "\n\n";

    # print "\n\n";

    $self->prepaire_config();

    $self->{master}        = undef;
    $self->{slaves}        = ();
    $self->{slave_counter} = 0;

    $self->{DataFile_counter} = 0;
    $self->{DataFiles}        = ();

    $self->{filenamebase}        = ();
    $self->{filename_extensions} = [];

    $self->{pause}      = 0;
    $self->{active}     = 0;
    $self->{repetition} = 0;

    return bless $self, $class;
}

sub prepaire_config {
    my $self = shift;

    # deep Copy original Config Data:

    # correct typing errors:
    $self->{config}->{mode} =~ s/\s+//g;    #remove all whitespaces
    $self->{config}->{mode} =~ "\L$self->{config}->{mode}"
        ;    # transform all uppercase letters to lowercase letters
    if ( $self->{config}->{mode}
        =~ /continuous|contious|cont|continuouse|continouse|coninuos|continuose/
        ) {
        $self->{config}->{mode} = 'continuous';
    }

    # make an Array out of single values if necessary:
    if ( ref( $self->{config}->{points} ) ne 'ARRAY' ) {
        $self->{config}->{points} = [ $self->{config}->{points} ];
    }
    if ( ref( $self->{config}->{rate} ) ne 'ARRAY' ) {
        $self->{config}->{rate} = [ $self->{config}->{rate} ];
    }
    if ( ref( $self->{config}->{duration} ) ne 'ARRAY' ) {
        $self->{config}->{duration} = [ $self->{config}->{duration} ];
    }
    if ( ref( $self->{config}->{stepwidth} ) ne 'ARRAY' ) {
        $self->{config}->{stepwidth} = [ $self->{config}->{stepwidth} ];
    }
    if ( ref( $self->{config}->{number_of_points} ) ne 'ARRAY' ) {
        $self->{config}->{number_of_points}
            = [ $self->{config}->{number_of_points} ];
    }
    if ( ref( $self->{config}->{interval} ) ne 'ARRAY' ) {
        $self->{config}->{interval} = [ $self->{config}->{interval} ];
    }

    $self->{config_original} = dclone( $self->{config} );

    # calculate the length of each Array:
    my $length_points           = @{ $self->{config}->{points} };
    my $length_rate             = @{ $self->{config}->{rate} };
    my $length_duration         = @{ $self->{config}->{duration} };
    my $length_stepwidth        = @{ $self->{config}->{stepwidth} };
    my $length_number_of_points = @{ $self->{config}->{number_of_points} };
    my $length_interval         = @{ $self->{config}->{interval} };

    # Look for inconsistent sweep parameters:
    if ( $length_points < 2 and $self->{config}->{mode} ne 'list' ) {
        die
            "inconsistent definition of sweep_config_data: less than two elements defined in 'points'. You need at least a 'start' and a 'stop' point.";
    }

    if ( $length_rate > $length_points ) {
        die
            "inconsistent definition of sweep_config_data: number of elements in 'rate' larger than number of elements in 'points'.";
    }
    if ( $length_duration > $length_points ) {
        die
            "inconsistent definition of sweep_config_data: number of elements in 'duration' larger than number of elements in 'points'.";
    }
    if (    $length_stepwidth > $length_points - 1
        and $self->{config}->{mode} ne 'list' ) {
        die
            "inconsistent definition of sweep_config_data: number of elements in 'stepwidth' larger than number of sweep sequences.";
    }
    if (    $length_number_of_points > $length_points - 1
        and $self->{config}->{mode} ne 'list' ) {
        die
            "inconsistent definition of sweep_config_data: number of elements in 'number_of_points' larger than number of sweep sequences.";
    }    #
    if (    $length_interval > $length_points
        and $self->{config}->{mode} ne 'list' ) {
        die
            "inconsistent definition of sweep_config_data: number of elements in 'interval' larger than number of sweep sequences.";
    }

    # fill up Arrays to fit with given Points:
    while ( ( $length_rate = @{ $self->{config}->{rate} } ) < $length_points )
    {
        push(
            @{ $self->{config}->{rate} },
            @{ $self->{config}->{rate} }[-1]
        );
    }

    while ( ( $length_duration = @{ $self->{config}->{duration} } )
        < $length_points ) {
        push(
            @{ $self->{config}->{duration} },
            @{ $self->{config}->{duration} }[-1]
        );
    }

    while ( ( $length_stepwidth = @{ $self->{config}->{stepwidth} } )
        < $length_points ) {
        push(
            @{ $self->{config}->{stepwidth} },
            @{ $self->{config}->{stepwidth} }[-1]
        );
    }

    while (
        (
            $length_number_of_points
            = @{ $self->{config}->{number_of_points} }
        ) < $length_points
        ) {
        push(
            @{ $self->{config}->{number_of_points} },
            @{ $self->{config}->{number_of_points} }[-1]
        );
    }

    while ( ( $length_interval = @{ $self->{config}->{interval} } )
        < $length_points ) {
        push(
            @{ $self->{config}->{interval} },
            @{ $self->{config}->{interval} }[-1]
        );
    }

    # calculate the length of each Array again:
    my $length_points           = @{ $self->{config}->{points} };
    my $length_rate             = @{ $self->{config}->{rate} };
    my $length_duration         = @{ $self->{config}->{duration} };
    my $length_stepwidth        = @{ $self->{config}->{stepwidth} };
    my $length_number_of_points = @{ $self->{config}->{number_of_points} };

    # evaluate sweep sign:
    foreach my $i ( 0 .. $length_points - 2 ) {
        if (  @{ $self->{config}->{points} }[$i]
            - @{ $self->{config}->{points} }[ $i + 1 ] < 0 ) {
            @{ $self->{config}->{sweepsigns} }[$i] = 1;
        }
        elsif ( @{ $self->{config}->{points} }[$i]
            - @{ $self->{config}->{points} }[ $i + 1 ] > 0 ) {
            @{ $self->{config}->{sweepsigns} }[$i] = -1;
        }
        else {
            @{ $self->{config}->{sweepsigns} }[$i] = 0;
        }
    }

    # add current position to Points-Array:
    unshift( @{ $self->{config}->{points} }, $self->get_value() );

    # calculate duration from rate and vise versa:
    if (    defined @{ $self->{config}->{rate} }[0]
        and defined @{ $self->{config}->{duration} }[0] ) {
        die
            'inconsistent definition of sweep_config_data: rate as well as duration defined. Use only one of both.';
    }
    elsif ( defined @{ $self->{config}->{duration} }[0]
        and @{ $self->{config}->{duration} }[0] == 0 ) {
        die 'bad definition of sweep parameters: duration == 0 not allowed';
    }
    elsif ( defined @{ $self->{config}->{rate} }[0]
        and @{ $self->{config}->{rate} }[0] == 0 ) {
        die 'bad definition of sweep parameters: rate == 0 not allowed';
    }
    elsif ( defined @{ $self->{config}->{duration} }[0] ) {
        foreach my $i ( 0 .. $length_points - 1 ) {
            @{ $self->{config}->{rate} }[$i]
                = abs(@{ $self->{config}->{points} }[ $i + 1 ]
                    - @{ $self->{config}->{points} }[$i] )
                / @{ $self->{config}->{duration} }[$i];
        }
    }
    elsif ( defined @{ $self->{config}->{rate} }[0] ) {
        foreach my $i ( 0 .. $length_points - 1 ) {
            @{ $self->{config}->{duration} }[$i]
                = abs(@{ $self->{config}->{points} }[ $i + 1 ]
                    - @{ $self->{config}->{points} }[$i] )
                / @{ $self->{config}->{rate} }[$i];
        }
    }

    # calculate stepwidth from Number_of_Points and vise versa:
    if (    defined @{ $self->{config}->{stepwidth} }[0]
        and defined @{ $self->{config}->{number_of_points} }[0] ) {
        die
            'inconsistent definition of sweep_config_data: step as well as number_of_points defined. Use only one of both.';
    }
    elsif ( defined @{ $self->{config}->{number_of_points} }[0] ) {
        unshift( @{ $self->{config}->{number_of_points} }, 1 );
        foreach my $i ( 1 .. $length_points - 1 ) {
            @{ $self->{config}->{stepwidth} }[ $i - 1 ]
                = abs(@{ $self->{config}->{points} }[ $i + 1 ]
                    - @{ $self->{config}->{points} }[$i] )
                / @{ $self->{config}->{number_of_points} }[$i];
        }
    }
    elsif ( defined @{ $self->{config}->{stepwidth} }[0] ) {
        foreach my $i ( 1 .. $length_points - 1 ) {
            @{ $self->{config}->{number_of_points} }[ $i - 1 ]
                = abs(@{ $self->{config}->{points} }[ $i + 1 ]
                    - @{ $self->{config}->{points} }[$i] )
                / @{ $self->{config}->{stepwidth} }[$i];
        }
    }
    shift @{ $self->{config}->{points} };

    # Calculations and checks depending on the selected sweep mode:
    if ( $self->{config}->{mode} eq 'continuous' ) {
        if (   not defined @{ $self->{config}->{rate} }[0]
            or not defined @{ $self->{config}->{duration} }[0] ) {
            die
                "inconsistent definition of sweep_config_data: for sweep_mode 'continuous' you have to define the rate or the duration for the sweep.";
        }
    }
    elsif ( $self->{config}->{mode} eq 'step' ) {
        $self->{config}->{interval} = [0];
        if (   not defined @{ $self->{config}->{stepwidth} }[0]
            or not defined @{ $self->{config}->{number_of_points} }[0] ) {
            die
                "inconsistent definition of sweep_config_data: for sweep_mode 'step' you have to define the setp-size or the number_of_points.";
        }

        # calculate each point/rate/stepsign/duration in step-sweep:
        my $temp_points     = ();
        my $temp_rate       = ();
        my $temp_sweepsigns = ();
        my $temp_duration   = ();

        foreach my $i ( 0 .. $length_points - 2 ) {
            my $nop = abs(
                (
                          @{ $self->{config}->{points} }[ $i + 1 ]
                        - @{ $self->{config}->{points} }[$i]
                ) / @{ $self->{config}->{stepwidth} }[$i]
            );
            $nop = ceil($nop);

            my $point = @{ $self->{config}->{points} }[$i];
            for ( my $j = 0; $j <= $nop; $j++ ) {
                if ( $point != @{$temp_points}[-1]
                    or not defined @{$temp_points}[-1] ) {
                    push( @{$temp_points}, $point );
                    push(
                        @{$temp_rate},
                        @{ $self->{config}->{rate} }[ $i + 1 ]
                    );
                    push(
                        @{$temp_duration},
                        @{ $self->{config}->{duration} }[ $i + 1 ]
                            / @{ $self->{config}->{number_of_points} }[$i]
                    );
                    push(
                        @{$temp_sweepsigns},
                        @{ $self->{config}->{sweepsigns} }[$i]
                    );
                }
                $point += @{ $self->{config}->{stepwidth} }[$i]
                    * @{ $self->{config}->{sweepsigns} }[$i];
            }
            @{$temp_points}[-1] = @{ $self->{config}->{points} }[ $i + 1 ];
        }
        pop @{$temp_rate};
        pop @{$temp_duration};
        pop @{$temp_sweepsigns};
        unshift( @{$temp_rate},     @{ $self->{config}->{rate} }[0] );
        unshift( @{$temp_duration}, @{ $self->{config}->{duration} }[0] );

        #unshift ( @{$temp_sweepsigns}, @{$self->{config}->{sweepsigns}}[0]);

        $self->{config}->{points}     = $temp_points;
        $self->{config}->{rate}       = $temp_rate;
        $self->{config}->{duration}   = $temp_duration;
        $self->{config}->{sweepsigns} = $temp_sweepsigns;
    }
    elsif ( $self->{config}->{mode} eq 'list' ) {
        $self->{config}->{interval} = [0];
        if ( not defined @{ $self->{config}->{rate} }[0] ) {
            die
                "inconsistent definition of sweep_config_data: 'rate' needs to be defined in sweep mode 'list'";
        }
    }

    # check if instrument is supported:
    if (
        defined @{ $self->{config}->{allowed_instruments} }[0]
        and not( grep { $_ eq ref( $self->{config}->{instrument} ) }
            @{ $self->{config}->{allowed_instruments} } )
        ) {
        die
            "inconsistent definition of sweep_config_data: Instrument (ref($self->{config}->{instrument})) is not supported by Sweep.";
    }

    # check if sweep-mode is supported:
    if (
        defined @{ $self->{config}->{allowed_sweep_modes} }[0]
        and not( grep { $_ eq $self->{config}->{mode} }
            @{ $self->{config}->{allowed_sweep_modes} } )
        ) {
        die
            "inconsistent definition of sweep_config_data: Sweep mode $self->{config}->{mode} is not supported by Sweep.";
    }

    # adjust repetitions in case of Backsweep selected:

    if ( $self->{config}->{backsweep} == 1 ) {
        $self->{config}->{repetitions} *= 2;
    }

}

sub prepare_backsweep {
    my $self      = shift;
    my $points    = ();
    my $rates     = ();
    my $durations = ();
    foreach my $point ( @{ $self->{config}->{points} } ) {
        unshift( @{$points}, $point );
    }
    foreach my $rate ( @{ $self->{config}->{rate} } ) {
        unshift( @{$rates}, $rate );
    }
    foreach my $duration ( @{ $self->{config}->{duration} } ) {
        unshift( @{$durations}, $duration );
    }

    unshift( @{$rates},     pop( @{$rates} ) );
    unshift( @{$durations}, 0 );
    pop( @{$durations} );

    #print "Points @{$points} \n";
    #print "rate @{$rate} \n";
    #print "duration @{$duration} \n";
    $self->{config}->{points}   = $points;
    $self->{config}->{rate}     = $rates;
    $self->{config}->{duration} = $durations;

}

sub add_DataFile {
    my $self     = shift;
    my $DataFile = shift;

    push( @{ $self->{filenamebase} }, $DataFile->{filenamebase} );

    push( @{ $self->{DataFiles} }, $DataFile );
    $self->{DataFile_counter}++;

    @{ $self->{LOG} }[ $self->{DataFile_counter} ] = {};

    return $self;
}

sub start {
    my $self = shift;
    ReadMode('cbreak');

    unshift( @{$ACTIVE_SWEEPS}, $self );

    # calculate duration for the defined sweep:
    #$self->estimate_sweep_duration();
    foreach my $slave ( @{ $self->{slaves} } ) {

        #$slave->estimate_sweep_duration();
    }

    # show estimated sweep duration:
    #my $sweep_structure = $self->sweep_structure();

    # create header for each DataFile:
    foreach my $file ( @{ $self->{DataFiles} } ) {
        foreach my $instrument ( @{ ${Lab::Instrument::INSTRUMENTS} } ) {

            #print $instrument."\n";
            $file->add_header( $instrument->create_header() );
        }
    }

    if ( not defined @{ $self->{slaves} }[0] ) {
        if ( $self->{DataFile_counter} <= 0 ) {
            print new Lab::Exception::Warning( error => "Attention: "
                    . ref($self)
                    . " has no DataFile ! \n" );
        }
        if ( defined @{ $self->{filename_extensions} }[0] ) {
            foreach my $DataFile ( @{ $self->{DataFiles} } ) {
                my $filenamebase = $DataFile->{filenamebase};
                my $new_filenamebase
                    = $self->add_filename_extensions($filenamebase);
                if ( $new_filenamebase ne $DataFile->{file} ) {
                    $DataFile->change_filenamebase($new_filenamebase);
                }
            }
        }

        # elsif ($self->{config}->{separate_files} == 1) {
        # foreach my $DataFile (@{$self->{DataFiles}}) {
        # my $filenamebase = $DataFile->{filenamebase};
        # $DataFile->change_filenamebase($filenamebase);
        # }
        # }

    }

    # link break signals to default functions:
    $SIG{BREAK} = \&enable_pause;

    #$SIG{INT} = \&abort;

    for (
        my $i = 1;
        ( $i <= $self->{config}->{repetitions} )
            or ( $self->{config}->{repetitions} < 0 );
        $i++
        ) {
        $self->{repetition}++;
        foreach my $file ( @{ $self->{DataFiles} } ) {
            $file->start_block();
        }
        $self->{iterator} = 0;
        $self->{sequence} = 0;
        $self->before_loop();
        $self->go_to_sweep_start();
        $self->delay( $self->{config}->{delay_before_loop} );
        my $before_loop = $self->{config}{before_loop};

        if ($before_loop) {
            if ( ref $before_loop ne 'CODE' ) {
                croak "'before_loop' argument must be a coderef";
            }
            $self->$before_loop();
        }

        # continuous sweep:
        if ( $self->{config}->{mode} eq 'continuous' ) {
            $self->start_continuous_sweep();
        }
        $self->{Time_start} = time();
        $self->{Date_start}, $self->{TimeStamp_start} = timestamp();
        $self->{loop}->{t0} = $self->{Time_start};

        $self->{active} = 1;

        while (1) {
            $self->in_loop();

            # step mode:
            if ( $self->{config}->{mode} =~ /step|list/ ) {
                $self->go_to_next_step();
                $self->delay( $self->{config}->{delay_in_loop} );
            }
            $self->{Time} = time() - $self->{Time_start};
            $self->{Date}, $self->{TimeStamp} = timestamp();

            # Master mode: call slave measurements if defined
            if ( defined @{ $self->{slaves} }[0] ) {
                my $extension = $self->get_filename_extension();
                foreach my $slave ( @{ $self->{slaves} } ) {

                    my $extensions
                        = dclone( \@{ $self->{filename_extensions} } );
                    push( @{$extensions}, $extension );

                    $slave->{filename_extensions} = $extensions;

                    $slave->start($self);
                }
            }

            # Slave mode: do measurement
            else {
                my $i = 1;
                foreach my $DataFile ( @{ $self->{DataFiles} } ) {

                    $DataFile->{measurement}->($self);
                    if ( $DataFile->{autolog} == 1 ) {
                        $DataFile->LOG( $self->create_LOG_HASH($i) );
                    }

                    $i++;
                }
            }

            # exit loop:
            if ( $self->exit_loop() or $self->{last} ) {
                $self->{last} = 0;
                last;
            }

            # pause:
            if ( $self->{config}->{mode} =~ /step|list/ and $PAUSE ) {
                $self->pause();
                $PAUSE = 0;
            }

            # check loop duratioin:
            $self->{iterator}++;
            $self->check_loop_duration();
        }

        $self->{active} = 0;

        $self->after_loop();
        if ($PAUSE) {
            $self->pause();
            $PAUSE = 0;
        }
        $self->delay( $self->{config}->{delay_after_loop} );

        # prepare_backsweep:
        if ( $self->{config}->{backsweep} > 0 ) {
            $self->prepare_backsweep();
        }

    }

    # finish measurement:
    $self->finish();

    return $self;

}

sub delay {
    my $self  = shift;
    my $delay = shift;

    if ( $delay <= 0 ) {
        return;
    }
    elsif ( $delay > 1 ) {
        my_sleep( $delay, $self, \&user_command );
    }
    else {
        my_usleep( $delay * 1e6, $self, \&user_command );
    }

}

sub estimate_sweep_duration {
    my $self     = shift;
    my $duration = 0;

    $duration += $self->{config}->{delay_before_loop};

    if ( $self->{config}->{mode} =~ /conti/ ) {
        foreach ( @{ $self->{config}->{duration} } ) {
            $duration += $_;
        }
    }
    elsif ( $self->{config}->{mode} =~ /step|list/ ) {
        foreach ( @{ $self->{config}->{duration} } ) {
            $duration += $_;
            $duration += $self->{config}->{delay_in_loop};
        }
    }

    $duration += $self->{config}->{delay_after_loop};
    $duration *= $self->{config}->{repetitions};

    $self->{config}->{estimated_sweep_duration} = $duration;
    return $duration;

}

sub estimate_total_sweep_duration {
    my $self = shift;

    if ( not defined $self->{master} ) {
        my $duration_total = 0;
        foreach my $slave ( @{ $self->{slaves} } ) {
            $duration_total += $slave->{config}->{estimated_sweep_duration};
        }

        #print "duration_total_1: $duration_total\n";
        my $number_of_steps = @{ $self->{config}->{duration} } - 1;
        $duration_total *= $number_of_steps;

        #print "duration_total_2: $duration_total\n";
        $duration_total += $self->{config}->{estimated_sweep_duration};

        #print "duration_total_3: $duration_total\n";
        $duration_total *= $self->{config}->{repetitions};

        #print "duration_total_4: $duration_total\n";
        $self->{config}->{estimated_sweep_duration_total} = $duration_total;
    }

}

sub sweep_structure {
    my $self = shift;
    my $text = "";

    if ( not defined $self->{master} ) {
        $self->estimate_total_sweep_duration();

        $text
            .= "\n\n\n=====================================================================\n";
        $text
            .= "===================  Master/Slave Sweep  ============================\n";
        $text
            .= "=====================================================================\n\n\n";
        $text .= "=========================\n";
        $text .= " Master = $self->{config}->{id}\n";
        $text .= "=========================\n";
        $text .= "\t|\n";
        $text .= "\t|\n";
        $text .= "\t|--> Instrument = "
            . ref( $self->{config}->{instrument} ) . "\n";

        # while ( my ($key,$value) = each %{$self->{config}} )
        # {
        # if ( ref($value) eq "ARRAY" )
        # {
        # $text .=  "\t|--> $key = @{$value}\n";
        # }
        # elsif ( ref($value) eq "HASH" )
        # {
        # $text .=  "\t|--> $key = %{$value}\n";
        # }
        # else
        # {
        # $text .=  "\t|--> $key = $value\n";
        # }
        # }
        $text .= "\t|--> Mode = $self->{config}->{mode}\n";
        if ( $self->{config}->{mode} =~ /conti/ ) {
            $text .= "\t|--> Interval = $self->{config}->{interval}\n";
        }
        $text .= "\t|--> Points = @{$self->{config_original}->{points}}\n";
        if ( $self->{config}->{mode} =~ /step/ ) {
            $text .= "\t|--> stepwidth = @{$self->{config}->{stepwidth}}\n";
        }
        $text .= "\t|--> rate = @{$self->{config_original}->{rate}}\n";
        $text
            .= "\t|--> duration = @{$self->{config_original}->{duration}}\n";
        $text
            .= "\t|--> Delays (before, in, after) loop = $self->{config}->{delay_before_loop}, $self->{config}->{delay_in_loop}, $self->{config}->{delay_after_loop}\n";
        $text .= "\t|--> Backsweep = $self->{config}->{backsweep}\n";
        $text
            .= "\t|--> Repetitions = $self->{config_original}->{repetitions}\n";
        $text
            .= "\t|--> Estimated Duration = "
            . seconds2time( $self->{config}->{estimated_sweep_duration} )
            . "\n";
        $text .= "\t|----------------------------------------------------\n";

        foreach my $slave ( @{ $self->{slaves} } ) {
            $text .= "\t\t|\n";
            $text .= "\t\t|\n";
            $text .= "\t=========================\n";
            $text .= "\t  Slave = $slave->{config}->{id}\n";
            $text .= "\t=========================\n";
            $text .= "\t\t|\n";
            $text .= "\t\t|\n";
            $text .= "\t\t|--> Instrument = "
                . ref( $slave->{config}->{instrument} ) . "\n";
            $text .= "\t\t|--> Mode = $slave->{config}->{mode}\n";

            if ( $slave->{config}->{mode} =~ /conti/ ) {
                $text .= "\t\t|--> Interval = $slave->{config}->{interval}\n";
            }
            $text
                .= "\t\t|--> Points = @{$slave->{config_original}->{points}}\n";
            if ( $slave->{config}->{mode} =~ /step/ ) {
                $text
                    .= "\t\t|--> stepwidth = @{$slave->{config}->{stepwidth}}\n";
            }
            $text .= "\t\t|--> rate = @{$slave->{config_original}->{rate}}\n";
            $text
                .= "\t\t|--> duration = @{$slave->{config_original}->{duration}}\n";
            $text
                .= "\t\t|--> Delays (before, in, after) loop = $slave->{config}->{delay_before_loop}, $slave->{config}->{delay_in_loop}, $slave->{config}->{delay_after_loop}\n";
            $text .= "\t\t|--> Backsweep = $slave->{config}->{backsweep}\n";
            $text
                .= "\t\t|--> Repetitions = $slave->{config_original}->{repetitions}\n";
            $text
                .= "\t\t|--> Estimated Duration = "
                . seconds2time( $slave->{config}->{estimated_sweep_duration} )
                . "\n";
            $text
                .= "\t\t|----------------------------------------------------\n";
        }
        $text .= "\n\n";
        $text
            .= "Estimated Duration for Master/Slave-Sweep: "
            . seconds2time(
            $self->{config}->{estimated_sweep_duration_total} )
            . "\n\n\n";
        $text
            .= "=====================================================================\n";
        $text
            .= "=====================================================================\n\n";

        foreach my $slave ( @{ $self->{slaves} } ) {
            foreach my $file ( @{ $slave->{DataFiles} } ) {
                $file->add_header($text);
            }
        }
        print $text;
    }
    else {
        return undef;
    }

}

sub add_filename_extensions {
    my $self = shift;

    my $filenamebase = shift;

    $filenamebase =~ /(.+)(\/|\/\/|\\|\\\\)(.+)\b/;

    my $directory = $1;
    my $filename  = $3;
    my $filetype  = ".dat";
    if ( $filename =~ /(.+)(\..+)\b/ ) {
        $filename = $1;
        $filetype = $2;
    }

    my $extension_length = @{ $self->{filename_extensions} };

    if ( $self->{config}->{separate_files} == 0 ) {

        for ( my $i = 0; $i < $extension_length - 2; $i++ ) {
            $directory .= "/" . @{ $self->{filename_extensions} }[$i];
        }

        for ( my $i = 0; $i < $extension_length - 1; $i++ ) {
            $filename .= "_" . @{ $self->{filename_extensions} }[$i];
        }
    }
    elsif ( $self->{config}->{separate_files} == 1 ) {

        for ( my $i = 0; $i < $extension_length - 1; $i++ ) {
            $directory .= "/" . @{ $self->{filename_extensions} }[$i];
        }
        for ( my $i = 0; $i < $extension_length; $i++ ) {
            $filename .= "_" . @{ $self->{filename_extensions} }[$i];
        }
    }

    if ( $self->{config}->{folders} == 0 ) {
        $directory = $1;    #do not create folder
    }

    return $directory . "/" . $filename . $filetype;
}

sub get_value {
    my $self = shift;
    return @{ $self->{config}->{points} }[ $self->{iterator} ];
}

sub enable_pause {
    print "Sweep will be paused after finishing this sweep. \n";
    $PAUSE = 1;
}

sub pause {
    my $self = shift;
    print "\n\nPAUSE: continue with <ENTER>\n";
    ReadMode('normal');
    <>;
    ReadMode('cbreak');
    $PAUSE = 0;
}

sub finish {
    my $self = shift;

    # delete entry in ACTIVE_SWEEPS:
    foreach my $i ( 0 .. ( my $length = @{$ACTIVE_SWEEPS} ) - 1 ) {

        #print "$i FINISH: ".$self."\t".@{$ACTIVE_SWEEPS}[$i]."\n";
        #print "active array before: {@{$ACTIVE_SWEEPS}}\n";
        if ( $self eq @{$ACTIVE_SWEEPS}[$i] ) {

            #@LIST = splice(@ARRAY, OFFSET, LENGTH, @REPLACE_WITH);
            @{$ACTIVE_SWEEPS} = splice( @{$ACTIVE_SWEEPS}, $i + 1, 1 );

            #print "active array after: {@{$ACTIVE_SWEEPS}}\n";
        }
    }

    # save plot image for all defined measurements:
    foreach my $file ( @{ $self->{DataFiles} } ) {
        foreach ( 0 .. $file->{plot_count} - 1 ) {
            if ( $file->{logger}->{plots}->[$_]->{autosave} eq 'always' ) {
                $file->save_plot($_);
            }
        }
    }

    # close DataFiles for all defined slaves:
    foreach my $slave ( @{ $self->{slaves} } ) {
        foreach my $file ( @{ $slave->{DataFiles} } ) {
            foreach ( 0 .. $file->{plot_count} - 1 ) {

                if ( $file->{logger}->{plots}->[$_]->{autosave} eq 'last' ) {
                    $file->save_plot($_);
                }
            }
        }
    }

    # close DataFiles of Master:
    if ( not defined $self->{master} ) {
        foreach my $file ( @{ $self->{DataFiles} } ) {
            foreach ( 0 .. $file->{plot_count} - 1 ) {
                if ( $file->{logger}->{plots}->[$_]->{autosave} eq 'last' ) {
                    $file->save_plot($_);
                }
            }
        }
    }

    ReadMode('normal');
}

sub active {
    my $self = shift;
    return $self->{active};
}

sub abort {

    foreach my $sweep ( @{$ACTIVE_SWEEPS} ) {
        $sweep->exit();
    }

    while ( @{$ACTIVE_SWEEPS}[0] ) {
        my $sweep = @{$ACTIVE_SWEEPS}[0];
        $sweep->finish();
    }

    exit;
}

sub stop {

    print "Sweep stopped by User!\n";
    foreach my $sweep ( @{$ACTIVE_SWEEPS} ) {
        $sweep->exit();
    }

}

sub exit {
    return shift;
}

sub last {
    my $self = shift;
    $self->{last} = 1;
    return;
}

sub before_loop {
    return shift;
}

sub go_to_sweep_start {
    return shift;
}

sub start_continuous_sweep {
    return shift;
}

sub in_loop {
    return shift;
}

sub go_to_next_step {
    return shift;
}

sub after_loop {
    return shift;
}

sub exit_loop {
    return shift;
}

sub check_loop_duration {

    my $self = shift;

    my $char = ReadKey(1e-5);
    if ( defined $char ) {
        $self->user_command($char);
    }

    if ( @{ $self->{config}->{interval} }[ $self->{sequence} ] == 0 ) {
        return 0;
    }

    if ( $self->{config}->{mode} =~ /step|list/ ) {
        return 0;
    }

    $self->{loop}->{t1} = time();

    if ( not defined $self->{loop}->{t0} ) {
        $self->{loop}->{t0} = time();
        return 0;
    }

    if ( ( $self->{loop}->{t1} - $self->{loop}->{t0} )
        > @{ $self->{config}->{interval} }[ $self->{sequence} ] ) {
        carp(     "WARNING: Measurement Loop takes more time ("
                . ( $self->{loop}->{t1} - $self->{loop}->{t0} )
                . ") than specified by measurement intervall (@{$self->{config}->{sequence}}[$self->{iterator}]).\n"
        );
    }
    my $delta_time = ( $self->{loop}->{t1} - $self->{loop}->{t0} )
        + $self->{loop}->{overtime};

    if ( defined $self->{config}->{instrument}
        and $self->{config}->{instrument}->can("active") ) {
        while (
            (
                @{ $self->{config}->{interval} }[ $self->{sequence} ]
                - $delta_time
            ) > 0.2
            ) {
            my $time0 = time();
            $self->{config}->{instrument}->active();
            $delta_time = $delta_time + ( ( time() - $time0 ) );
        }
    }

    if ( $delta_time > @{ $self->{config}->{interval} }[ $self->{sequence} ] )
    {
        $self->{loop}->{overtime} = $delta_time
            - @{ $self->{config}->{interval} }[ $self->{sequence} ];
        $delta_time = @{ $self->{config}->{interval} }[ $self->{sequence} ];

        #warn "WARNING: Measurement Loop takes more time ($self->{loop}->{overtime}) than specified by measurement intervall (@{$self->{config}->{sequence}}[$self->{iterator}]).\n";
    }
    else {
        $self->{loop}->{overtime} = 0;
    }

    usleep(
        (
            @{ $self->{config}->{interval} }[ $self->{sequence} ]
                - $delta_time
        ) * 1e6
    );

    $self->{loop}->{t0} = time();
    return $delta_time;

}

sub user_command {
    my $self = shift;
    my $cmd  = shift;

    print "user_command = " . $cmd . "\n";

    if ( $cmd eq "g" ) {
        foreach my $datafile ( @{ $self->{DataFiles} } ) {
            $datafile->gnuplot_restart();
        }
    }
    elsif ( $cmd eq "p" ) {

        #foreach my $datafile (@{$self->{DataFiles}})
        #	{
        @{ $self->{DataFiles} }[0]->gnuplot_pause();

        #	}
    }

    return 1;

}

sub LOG {

    my $self = shift;
    my @args = @_;

    if ( ref( $args[0] ) eq "HASH" ) {
        my $file = ( defined $args[1] ) ? $args[1] : 0;
        if ( not defined @{ $self->{DataFiles} }[ $args[1] - 1 ] ) {
            Lab::Exception::Warning->throw(
                "DataFile $file is not defined! \n");
        }
        while ( my ( $key, $value ) = each %{ $args[0] } ) {
            @{ $self->{LOG} }[$file]->{$key} = $value;
        }
    }
    else {
        # for old style: LOG("column_name", "value", "File")
        my $file = ( defined $args[2] ) ? $args[2] : 0;
        if ( not defined @{ $self->{DataFiles} }[ $args[2] - 1 ] ) {
            Lab::Exception::Warning->throw(
                "DataFile $file is not defined! \n");
        }
        @{ $self->{LOG} }[$file]->{ $args[0] } = $args[1];
    }
}

sub set_autolog {
    my $self  = shift;
    my $value = shift;
    my $file  = shift;

    if ( not defined $file or $file == 0 ) {
        foreach my $DataFile ( @{ $self->{DataFiles} } ) {
            $DataFile->set_autolog($value);
        }
    }
    elsif ( defined @{ $self->{DataFiles} }[ $file - 1 ] ) {
        @{ $self->{DataFiles} }[ $file - 1 ]->set_autolog($value);
    }
    else {
        print new Lab::Exception::Warning(
            "DataFile $file is not defined! \n");
    }

    return $self;
}

sub skip_LOG {
    my $self = shift;
    my $file = shift;

    if ( not defined $file or $file == 0 ) {
        foreach my $DataFile ( @{ $self->{DataFiles} } ) {
            $DataFile->skiplog();
        }
    }
    elsif ( defined @{ $self->{DataFiles} }[ $file - 1 ] ) {
        @{ $self->{DataFiles} }[ $file - 1 ]->skiplog();
    }
    else {
        print new Lab::Exception::Warning(
            "DataFile $file is not defined! \n");
    }

    return $self;
}

sub write_LOG {
    my $self = shift;
    my $file = shift;

    if ( not defined $file or $file == 0 ) {
        my $i = 1;
        foreach my $DataFile ( @{ $self->{DataFiles} } ) {
            $DataFile->LOG( $self->create_LOG_HASH($i) );
            $i++;
        }
    }
    elsif ( defined @{ $self->{DataFiles} }[ $file - 1 ] ) {
        @{ $self->{DataFiles} }[ $file - 1 ]
            ->LOG( $self->create_LOG_HASH($file) );
    }
    else {
        print new Lab::Exception::Warning(
            "DataFile $file is not defined! \n");
    }

    return $self;

}

sub create_LOG_HASH {
    my $self = shift;
    my $file = shift;

    my $LOG_HASH = {};

    foreach
        my $column ( @{ @{ $self->{DataFiles} }[ $file - 1 ]->{COLUMNS} } ) {
        if ( defined @{ $self->{LOG} }[$file]->{$column} ) {
            $LOG_HASH->{$column} = @{ $self->{LOG} }[$file]->{$column};
        }
        elsif ( defined @{ $self->{LOG} }[0]->{$column} ) {
            $LOG_HASH->{$column} = @{ $self->{LOG} }[0]->{$column};
        }
        else {
            if (   exists @{ $self->{LOG} }[$file]->{$column}
                or exists @{ $self->{LOG} }[0]->{$column} ) {
                print new Lab::Exception::Warning(
                    "Value for Paramter $column undefined\n");
            }
            else {
                print new Lab::Exception::Warning(
                    "Paramter $column not found. Maybe a typing error??\n");
            }
            $LOG_HASH->{$column} = '?';
        }
    }

    return $LOG_HASH;

}

sub add_slave {
    my $self  = shift;
    my $slave = shift;

    if ( not $self->{config}->{mode} =~ /step|list/ ) {
        Lab::Exception::Warning->throw( error =>
                "Can't add slave to master-sweep which is not in mode list or step."
        );
    }

    my $type = ref($slave);
    if ( $type =~ /^Lab::XPRESS::Sweep::Frame/ ) {
        if ( not defined $slave->{master} ) {
            Lab::Exception::Warning->throw(
                error => 'No master defined in Frame.' );
        }
        elsif ( not defined @{ $slave->{master}->{slaves} }[0] ) {
            Lab::Exception::Warning->throw(
                error => 'No slave(s) defined in Frame.' );
        }

        push( @{ $self->{slaves} }, $slave->{master} );
        $slave = $slave->{master};

        $self->{slave_counter}++;

    }
    elsif ( $type =~ /^Lab::XPRESS::Sweep/ ) {
        if ( defined $slave->{master} ) {
            Lab::Exception::Warning->throw( error =>
                    "Cannot add slave sweep with an already defined master sweep ."
            );
        }

        if ( $slave->{DataFile_counter} <= 0
            and not defined @{ $slave->{slaves} }[-1] ) {
            while (1) {
                print
                    "\n XPRESS::FRAME: -- Added slave sweep has no DataFile! Continue anyway (y/n) ?\n";
                my $answer = <>;
                if ( $answer =~ /y|Y/ ) {
                    last;
                }
                elsif ( $answer =~ /n|N/ ) {
                    exit;
                }
            }
        }

        push( @{ $self->{slaves} }, $slave );
        $self->{slave_counter}++;
    }
    elsif ( $type eq 'CODE' ) {
        $slave = new Lab::XPRESS::Sweep::Dummy($slave);
        push( @{ $self->{slaves} }, $slave );
        $self->{slave_counter}++;
    }
    else {
        Lab::Exception::Warning->throw(
            error => "slave object is of type $type. Cannot add slave." );
    }

    $slave->{master}          = $self;
    $self->{DataFile_counter} = 0;
    $self->{DataFiles}        = ();

    return $self;
}

sub get_filename_extension {
    my $self = shift;
    return $self->{config}->{filename_extension} . $self->get_value();
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

# Need to provide this or AUTOLOAD cannot find it and will die on object destruction.
sub DESTROY {

    # do nothing
}

sub AUTOLOAD {

    my $self  = shift;
    my $type  = ref($self) or croak "\$self is not an object";
    my $value = undef;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully qualified portion

    if ( exists $self->{_permitted}->{$name} ) {
        if (@_) {
            return $self->{$name} = shift;
        }
        else {
            return $self->{$name};
        }
    }
    elsif ( $name =~ qr/^(set_)(.*)$/ ) {

        # There is a problem with deep copying of the instrument hash.
        # The elements of the hash could not be accessed correctly.
        # The workaround is to tempsave the hashref and put it back in
        # place. This should be only temporary though.

        # NOTE: changed the creation of config_original (in prepare_config function), so it is a copy
        # 		of {config} unsing dclone instead of deep_copy. I think this adresses the issue above.

        my $instrument = $self->{config}->{instrument};

        if ( exists $self->{config_original}->{$2} ) {
            if ( $self->active() ) {
                print Lab::Exception::Warning->new( error =>
                        "WARNING: Cannot set parameter while sweep is active \n"
                );
                return;
            }
            if ( @_ == 1 ) {
                $self->{config_original}->{$2} = @_[0];
            }
            else {
                $self->{config_original}->{$2} = deep_copy( \@_ );
            }

            $self->{config} = deep_copy( $self->{config_original} );

            #use Data::Dumper;

            #print Dumper $self->{config};

            $self->{config}->{instrument} = $instrument;
            $self->prepaire_config();
        }
        else {
            print Lab::Exception::Warning->new(
                error => "WARNING: Parameter $2 does not exist \n" );
        }
    }

    else {
        Lab::Exception::Warning->throw( error => "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
    }
}

with 'Lab::XPRESS::Sweep::LogBlock';

# sub timestamp {

# my $self = shift;
# my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat,
# $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(time);

# $Monat+=1;
# $Jahrestag+=1;
# $Monat = $Monat < 10 ? $Monat = "0".$Monat : $Monat;
# $Monatstag = $Monatstag < 10 ? $Monatstag = "0".$Monatstag : $Monatstag;
# $Stunden = $Stunden < 10 ? $Stunden = "0".$Stunden : $Stunden;
# $Minuten = $Minuten < 10 ? $Minuten = "0".$Minuten : $Minuten;
# $Sekunden = $Sekunden < 10 ? $Sekunden = "0".$Sekunden : $Sekunden;
# $Jahr+=1900;

# return   "$Monatstag.$Monat.$Jahr", "$Stunden:$Minuten:$Sekunden";

# }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep - Base sweep class

=head1 VERSION

version 3.881

=head1 SYNOPSIS

	Lab::XPRESS::Sweep is meant to be used as a base class for inheriting Sweeps.
	It should not be used directly. 

=head1 DESCRIPTION

The Lab::XPRESS::Sweep class implements major parts of the Lab::XPRESS framework, a modular way for easy scripting measurements in perl and Lab::Measurement.
Direct usage of this class would not result in any action. However it constitutes the fundament for more spezialized subclass Sweeps e.g. Lab::XPRESS::Sweep::Magnet. 

=head1 SWEEP PARAMETERS

The configuration parameters are described in the particular subclasses (e.g. Lab::XPRESS::Sweep::Magnet). 

=head1 METHODS

=head2 add_DataFile [Lab::XPRESS::Data::XPRESS_DataFile object]

use this method to assign a DataFile object with a sweep if it operates as a slave or as a individual sweep. The sweep will call the user-defined measurment routine assigned with the DataFile.
Sweeps accept multiple DataFile objects when add_DataFile is used repeatedly. 

=head2 start

use this method to execute the sweep.

=head2 get_value 

returns by default the current value of the points array or the current step. The method is intended to be overloaded by Sweep-Subclasses, in order to return the current value of the sweeping instrument.

=head2 LOG [hash, int (default = 0)]

use this method to store the data collected by user-defined measurment routine in the DataFile object.

The hash has to look like this: $column_name => $value
The column_name has to be one of the previously defined columnames in the DataFile object.

When using multiple DataFile objects within one sweep, you can direct the data hash one of the DataFiles by the second parameter (int). If this parameter is set to 0 (default) the data hash will be directed to all DataFile objects.

Examples:
	$sweep->LOG({
		'voltage' => 10,
		'current' => 1e-6,
		'reistance' => $R
	});

OR:

	$sweep->LOG({'voltage' => 10});
	$sweep->LOG({'current' => 1e-6});
	$sweep->LOG({'reistance' => $R});

for two DataFiles:

	# this value will be logged in both DataFiles
	$sweep->LOG({'voltage' => 10},0); 

	# this values will be logged in DataFile 1
	$sweep->LOG({
		'current' => 1e-6,
		'reistance' => $R1
	},1); 

	# this values will be logged in DataFile 2
	$sweep->LOG({
		'current' => 10e-6,
		'reistance' => $R2
	},2); 

.

=head2 last

use this method, in order to stop the current sweep. Example:

	# Stop a voltage Sweep if device current exeeds a critical limit.

	if ($current > $high_limit) {
		$voltage_sweep->last();
	}

.

=head1 HOW TO DEVELOP SUBCLASS OF Lab::XPRESS::Sweep

preefine the default_config hash values in method 'new':

	sub new {
	    my $proto = shift;
		my @args=@_;
	    my $class = ref($proto) || $proto; 
		my $self->{default_config} = {
			id => 'Magnet_sweep',
			filename_extension => 'B=',
			interval	=> 1,
			points	=>	[],
			duration	=> [],
			mode	=> 'continuous',
			allowed_instruments => ['Lab::Instrument::IPS', 'Lab::Instrument::IPSWeiss1', 'Lab::Instrument::IPSWeiss2', 'Lab::Instrument::IPSWeissDillFridge'],
			allowed_sweep_modes => ['continuous', 'list', 'step'],
			number_of_points => [undef]
			};
			
		$self = $class->SUPER::new($self->{default_config},@args);	
		bless ($self, $class);
		
	    return $self;
	}

the following methodes have to be overloaded in the subclass:

	sub go_to_sweep_start{}
	sub start_continuous_sweep{}
	sub go_to_next_step{}
	sub exit_loop{}
	sub get_value{}
	sub exit{}

additionally see one of the present Sweep-Subclasses.

=head1 CAVEATS/BUGS

probably some

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Alexei Iankilevitch, Christian Butschkow
            2015       Christian Butschkow
            2016-2017  Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
