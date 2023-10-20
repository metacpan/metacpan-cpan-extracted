package Lab::XPRESS::Sweep::Temperature;
#ABSTRACT: Temperature sweep
$Lab::XPRESS::Sweep::Temperature::VERSION = '3.899';
use v5.20;

use Lab::XPRESS::Sweep;
use Statistics::Descriptive;
use Time::HiRes qw/usleep/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto = shift;
    my @args  = @_;
    my $class = ref($proto) || $proto;

    # define default values for the config parameters:
    my $self->{default_config} = {
        id                  => 'Temperature_sweep',
        filename_extension  => 'T=',
        interval            => 1,
        points              => [ 0, 10 ],
        duration            => [1],
        stepwidth           => 1,
        pid                 => undef,
        mode                => 'continuous',
        allowed_instruments => [
            qw/Lab::Instrument::ITC Lab::Instrument::TCD
                Lab::Instrument::OI_ITC503 Lab::Instrument::OI_Triton
                Lab::Instrument::Lakeshore340 Lab::Instrument::TRMC2/,
        ],
        allowed_sweep_modes => [ 'continuous', 'step', 'list' ],

        sensor                         => undef,
        stabilize_measurement_interval => 1,
        stabilize_observation_time     => 3 * 60,
        tolerance_setpoint             => 0.2,
        std_dev_instrument             => 0.15,
        std_dev_sensor                 => 0.15,

        max_stabilization_time => undef,
        setter_args            => [],
        getter_args            => [],

    };

    # create self from Sweep basic class:
    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );

    # check and adjust config values if necessary:
    $self->check_config_paramters();

    # init mandatory parameters:
    $self->{DataFile_counter} = 0;
    $self->{DataFiles}        = ();

    return $self;
}

sub check_config_paramters {
    my $self = shift;

    # No Backsweep allowed; adjust number of Repetitions if Backsweep is 1:
    if ( $self->{config}->{mode} eq 'continuous' ) {
        if ( $self->{config}->{backsweep} == 1 ) {
            $self->{config}->{repetitions} /= 2;
            $self->{config}->{backsweep} = 0;
        }
    }

    if ( defined $self->{config}->{pid} ) {
        if ( ref( $self->{config}->{pid} ) eq 'ARRAY' ) {
            if ( ref( @{ $self->{config}->{pid} }[0] ) ne 'ARRAY' ) {
                $self->{config}->{pid} = [ $self->{config}->{pid} ];
            }
        }
        else {
            $self->{config}->{pid} = [ [ $self->{config}->{pid} ] ];
        }
    }
    else {
        $self->{config}->{pid} = [undef];
    }

    # Set loop-Interval to Measurement-Interval:
    $self->{loop}->{interval} = $self->{config}->{interval};

}

sub start_continuous_sweep {
    my $self = shift;

    print
        "Stabilize Temperature at upper limit (@{$self->{config}->{points}}[1] K) \n";
    $self->stabilize( @{ $self->{config}->{points} }[1] );

    print "Reached upper limit -> start cooling ... \n";
    $self->{config}->{instrument}->set_heatercontrol('MAN');
    $self->{config}->{instrument}->set_heateroutput(0);
}

sub go_to_next_step {
    my $self = shift;

    $self->stabilize( @{ $self->{config}->{points} }[ $self->{iterator} ] );

}

sub exit_loop {
    my $self = shift;

    my $TEMPERATURE;

    if ( $self->{config}->{mode} =~ /step|list/ ) {
        if (
            not
            defined @{ $self->{config}->{points} }[ $self->{iterator} + 1 ] )
        {
            return 1;
        }
    }
    elsif ( $self->{config}->{mode} =~ /continuous/ ) {
        if ( defined $self->{config}->{sensor} ) {
            $TEMPERATURE = $self->{config}->{sensor}->get_value();
        }
        else {
            $TEMPERATURE = $self->get_value();
        }
        if ( $TEMPERATURE < @{ $self->{config}->{points} }[0] ) {
            return 1;
        }
        else {
            return 0;
        }

    }

    return 0;

}

sub get_value {
    my $self = shift;
    return $self->{config}->{instrument}
        ->get_value( @{ $self->{config}->{getter_args} } );
}

sub halt {
    return shift;
}

sub stabilize {

    use Term::ReadKey;

    my $self     = shift;
    my $setpoint = shift;

    my $time0 = time();

    my @T_INSTR;
    my @T_SENSOR;

    my @MEDIAN_INSTR;
    my @MEDIAN_SENSOR;

    my $MEDIAN_INSTR_MEDIAN = undef;
    my $INSTR_STD_DEV       = undef;
    my $SENSOR_STD_DEV      = undef;

    my $criterion_setpoint       = 0;
    my $criterion_std_dev_INSTR  = 0;
    my $criterion_std_dev_SENSOR = 1;

    my $pid = shift @{ $self->{config}->{pid} };
    if ( defined $pid ) {

        my $p = shift @{$pid};
        my $i = shift @{$pid};
        my $d = shift @{$pid};

        $self->{config}->{instrument}->set_PID( $p, $i, $d );

    }

    $self->{config}->{instrument}->set_heatercontrol('AUTO');
    $self->{config}->{instrument}
        ->set_T( $setpoint, @{ $self->{config}->{setter_args} } );

    local $| = 1;

    my $time0 = time();

    print "Stabilize Temperature at $setpoint K ... (Press 'c' to skip)\n\n";

    #my $line1  = "\rElapsed: $elapsed_time \n Current Temp INSTR: @T_INSTR[-1] \n Current Temp SENSOR: @T_SENSOR[-1] \n ";
    #my $line2 = "Current Median: @MEDIAN_INSTR[-1] \n Std. Dev. T Instr. : $INSTR_STD_DEV \n Std. Dev. T Sensor : $SENSOR_STD_DEV \n ";
    #my $line3 = "CRIT SETPOINT: $criterion_setpoint \n CRIT Std. Dev. T Instr. : $criterion_std_dev_INSTR \n CRIT Std. Dev. T Sensor : $criterion_std_dev_SENSOR \n ";
    print " Time    " . " | "
        . " TEMP " . " | " . "SENS " . " | " . "MED_I" . " | " . "ISD "
        . " | " . "SSD " . " | " . "C1" . " | " . "C2" . " | " . "C3" . " \n";

    ReadMode('cbreak');
    while (1) {

        #----------COLLECT DATA--------------------
        my $T_INSTR = $self->get_value();
        push( @T_INSTR, $T_INSTR );

        if (
            scalar @T_INSTR > int(
                      $self->{config}->{stabilize_observation_time}
                    / $self->{config}->{stabilize_measurement_interval}
            )
            ) {
            shift(@T_INSTR);

            my $stat = Statistics::Descriptive::Full->new();
            $stat->add_data( \@T_INSTR );
            my $MEDIAN_INSTR = $stat->median();

            push( @MEDIAN_INSTR, $MEDIAN_INSTR );

            if (
                scalar @MEDIAN_INSTR > int(
                          $self->{config}->{stabilize_observation_time}
                        / $self->{config}->{stabilize_measurement_interval}
                )
                ) {
                shift(@MEDIAN_INSTR);
            }
        }

        if ( defined $self->{config}->{sensor} ) {
            my $T_SENSOR = $self->{config}->{sensor}->get_value();
            push( @T_SENSOR, $T_SENSOR );

            if (
                scalar @T_SENSOR > int(
                          $self->{config}->{stabilize_observation_time}
                        / $self->{config}->{stabilize_measurement_interval}
                )
                ) {
                shift(@T_SENSOR);

                my $stat = Statistics::Descriptive::Full->new();
                $stat->add_data( \@T_SENSOR );
                my $MEDIAN_SENSOR = $stat->median();

                push( @MEDIAN_SENSOR, $MEDIAN_SENSOR );

                if (
                    scalar @MEDIAN_SENSOR > int(
                              $self->{config}->{stabilize_observation_time}
                            / $self->{config}
                            ->{stabilize_measurement_interval}
                    )
                    ) {
                    shift(@MEDIAN_SENSOR);
                }
            }
        }

        #--------CHECK THE CRITERIONS--------------

        if ( defined @MEDIAN_INSTR[-1] ) {
            if (
                abs( $setpoint - @MEDIAN_INSTR[-1] )
                < $self->{config}->{tolerance_setpoint} ) {
                $criterion_setpoint = 1;
            }
            else {
                $criterion_setpoint = 0;
            }
        }

        # if (scalar @MEDIAN_INSTR >= int($self->{config}->{stabilize_observation_time}/$self->{config}->{stabilize_measurement_interval}) - 1) {

        # my $stat = Statistics::Descriptive::Full->new();
        # $stat->add_data(\@MEDIAN_INSTR);
        # $MEDIAN_INSTR_MEDIAN = $stat->median();

        # if (abs($setpoint - $MEDIAN_INSTR_MEDIAN) < $self->{config}->{tolerance_setpoint}) {
        # $criterion_setpoint = 1;
        # }
        # else {
        # $criterion_setpoint = 0;
        # }
        # }

        if (
            scalar @T_INSTR >= int(
                      $self->{config}->{stabilize_observation_time}
                    / $self->{config}->{stabilize_measurement_interval}
            ) - 1
            ) {
            my $stat = Statistics::Descriptive::Full->new();
            $stat->add_data( \@T_INSTR );
            $INSTR_STD_DEV = $stat->standard_deviation();

            if ( $INSTR_STD_DEV < $self->{config}->{std_dev_instrument} ) {
                $criterion_std_dev_INSTR = 1;
            }
            else {
                $criterion_std_dev_INSTR = 0;
            }
        }

        if ( defined $self->{config}->{sensor} ) {
            if (
                scalar @T_SENSOR >= int(
                          $self->{config}->{stabilize_observation_time}
                        / $self->{config}->{stabilize_measurement_interval}
                ) - 1
                ) {
                my $stat = Statistics::Descriptive::Full->new();
                $stat->add_data( \@T_SENSOR );
                $SENSOR_STD_DEV = $stat->standard_deviation();

                if ( $SENSOR_STD_DEV < $self->{config}->{std_dev_sensor} ) {
                    $criterion_std_dev_SENSOR = 1;
                }
                else {
                    $criterion_std_dev_SENSOR = 0;
                }
            }
        }

        my $elapsed_time = $self->convert_time( time() - $time0 );

        my $output
            = $elapsed_time . " | " . sprintf( "%3.4f", @T_INSTR[-1] ) . " | "

            #            . sprintf( "%3.3f", @T_SENSOR[-1] ) . " | "
            #            . sprintf( "%3.3f", @MEDIAN_INSTR[-1] ) . " | "
            . sprintf( "%2.4f", $INSTR_STD_DEV ) . " | "

            #            . sprintf( "%2.3f", $SENSOR_STD_DEV ) . " | "
            . $criterion_setpoint . " | "
            . $criterion_std_dev_INSTR . " | "
            . $criterion_std_dev_SENSOR;

        print $output;

        if (  $criterion_std_dev_INSTR
            * $criterion_std_dev_SENSOR
            * $criterion_setpoint ) {
            last;
        }
        elsif (
            defined $self->{config}->{max_stabilization_time}
            and ( ( time() - $time0 )
                >= $self->{config}->{max_stabilization_time} )
            ) {
            last;
            print "\n";
        }

        else {

        }

        my $char = ReadKey(1e-5);
        if ( defined $char and $char eq 'c' ) {
            last;
        }
        sleep( $self->{config}->{stabilize_measurement_interval} );

        print "\r";

    }
    ReadMode('normal');
    $| = 0;

    print "\nTemperature stabilized at $setpoint K \n";
}

sub convert_time {
    my $self = shift;

    my $time = shift;
    my $days = int( $time / 86400 );
    $time -= ( $days * 86400 );
    my $hours = int( $time / 3600 );
    $time -= ( $hours * 3600 );
    my $minutes = int( $time / 60 );
    my $seconds = $time % 60;

    $time
        = sprintf( "%02dh", $hours )
        . sprintf( "%02dm", $minutes )
        . sprintf( "%02ds", $seconds );
    return $time;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::Temperature - Temperature sweep (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	
	my $tsensor = $hub->Instrument('ITC', 
		{
		connection_type => 'VISA_RS232',
		gpib_address => 2
		});
	
	my $sweep_temperature = $hub->Sweep('Temperature',
		{
		instrument => $tsensor,
		points => [90,4],
		mode => 'list'
		});

.

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::Temperature class implements a module for temperature sweeps in the Lab::XPRESS::Sweep framework.

.

=head1 CONSTRUCTOR

	my $sweep_temperature = $hub->Sweep('Temperature',
		{
		instrument => $tsensor,
		points => [90,4],
		mode => 'list'
		});

Instantiates a new temperature sweep

.

=head1 PARAMETERS

=head2 instrument [Lab::Instrument] (mandatory)

Instrument, conducting the sweep. Must be of type Lab:Instrument. 
Supported instruments: Lab::Instrument::ITC

.

=head2 mode [string] (default = 'continuous' | 'step' | 'list')

continuous: perform a continuous temperature sweep. After the starting temperature has been stabalized by the temperature controller, the heater will be switched off in order to cool down to the final value. Measurements will be performed constantly at the time-interval defined in interval.

step: measurements will be performed at discrete values between start and end points defined in parameter points, seperated by a step defined in parameter stepwidth

list: measurements will be performed at a list of values defined in parameter points

.

=head2 points [float array] (mandatory)

array of values (in deg) that defines the characteristic points of the sweep.
First value is appraoched before measurement begins. 

Case mode => 'continuous' :
List of exactly 2 values, that define start and end point of the sweep. The starting point has to be higher value than the endpont. 
	 	points => [180, 4]	# Start: 180 K / Stop: 4 K

Case mode => 'step' :
Same as in 'continuous' but the temperature controller will stabalize the temperature at the defined setpoints.  A measurement is performed, when the motor is idle.

Case mode => 'list' :
Array of values, with minimum length 1, that are approached in sequence to perform a measurment.

.

=head2 stepwidth [float array]

This parameter is relevant only if mode = 'step' has been selected. 
Stepwidth has to be an array of length '1' or greater. The values define the width for each step within the corresponding sweep sequence. 
If the length of the defined sweep sequence devided by the stepwidth is not an integer number, the last step will be smaller in order to reach the defined points-value.

	points = [0, 90, 180]
	stepwidth = [10, 25]
	
	==> steps: 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 115, 140, 165, 180

.

=head2 number_of_points [int array]

can be used instead of 'stepwidth'. Attention: Use only the 'number_of_points' or the 'stepwidth' parameter. Using both will cause an Error!
This parameter is relevant only if mode = 'step' has been selected. 
Number_of_points has to be an array of length '1' or greater. The values defines the number of steps within the corresponding sweep sequence.

	points = [0, 90, 180]
	number_of_points = [5, 2]
	
	==> steps: 0, 18, 36, 54, 72, 90, 135, 180

.

=head2 interval [float] (default = 1)

interval in seconds for taking measurement points. Only relevant in mode 'continuous'.

.

=head2 id [string] (default = 'Temperature_sweep')

Just an ID.

.

=head2 filename_extention [string] (default = 'T=')

Defines a postfix, that will be appended to the filenames if necessary.

.

=head2 delay_before_loop [int] (default = 0)

defines the time in seconds to wait after the starting point has been reached.

.

=head2 delay_in_loop [int] (default = 0)

This parameter is relevant only if mode = 'step' or 'list' has been selected. 
Defines the time in seconds to wait after the value for the next step has been reached.

.

=head2 delay_after_loop [int] (default = 0)

Defines the time in seconds to wait after the sweep has been finished. This delay will be executed before an optional backsweep or optional repetitions of the sweep.

=head2 getter_args

Setting C<getter_args => [@args]>, the C<get_value> method will be called as

 $instrument->get_value(@args);

=head2 setter_args

Setting C<setter_args => [@args]>, the C<set_T> method will be called as

 $instrument->set_T($setpoint, @args);

=head1 CAVEATS/BUGS

probably none

.

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Christian Butschkow
            2015       Alois Dirnaichner
            2016-2017  Andreas K. Huettel, Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
