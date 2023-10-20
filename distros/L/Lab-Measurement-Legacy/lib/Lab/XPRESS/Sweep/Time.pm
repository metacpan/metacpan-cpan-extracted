package Lab::XPRESS::Sweep::Time;
#ABSTRACT: Simple time-controlled repeater
$Lab::XPRESS::Sweep::Time::VERSION = '3.899';
use v5.20;

use Lab::XPRESS::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use Statistics::Descriptive;
use Carp;
use strict;

our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto = shift;
    my @args  = @_;
    my $class = ref($proto) || $proto;

    # define default values for the config parameters:
    my $self->{default_config} = {
        id                  => 'Time_sweep',
        interval            => 1,
        points              => [0],              #[0,10],
        duration            => undef,
        stepwidth           => 1,
        mode                => 'continuous',
        allowed_instruments => [undef],
        allowed_sweep_modes => ['continuous'],

        stabilize                  => 0,
        sensor                     => undef,
        sensor_args                => [],
        std_dev_sensor             => 1e-6,
        stabilize_observation_time => 3 * 60,
    };

    if ( ref( @args[0]->{duration} ) ne "ARRAY" ) {
        @args[0]->{duration} = [ @args[0]->{duration} ];
    }

    foreach my $d ( @{ @args[0]->{duration} } ) {
        push( @{ $self->{default_config}->{points} }, $d );
    }

    # create self from Sweep basic class:
    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );

    # check and adjust config values if necessary:
    $self->check_config_paramters();

    # init mandatory parameters:
    $self->{DataFile_counter} = 0;
    $self->{DataFiles}        = ();

    $self->{stabilize}->{data} = ();

    return $self;
}

sub check_config_paramters {
    my $self = shift;

    # No Backsweep allowed; adjust number of Repetitions if Backsweep is 1:
    if ( $self->{config}->{backsweep} == 1 ) {
        $self->{config}->{repetitions} /= 2;
        $self->{config}->{backsweep} = 0;
    }

    # Set loop-Interval to Measurement-Interval:
    $self->{loop}->{interval} = $self->{config}->{interval};

    # check correct initialization of stabilize
    if ( $self->{config}->{stabilize} == 1 ) {
        if ( not defined $self->{config}->{sensor} ) {
            croak('Stabilization activated, but no sensor defined!');
        }

    }

}

sub exit_loop {
    my $self = shift;

    if (
        @{ $self->{config}->{points} }[ $self->{sequence} ] > 0
        and $self->{iterator} >= (
                  @{ $self->{config}->{points} }[ $self->{sequence} ]
                / @{ $self->{config}->{interval} }[ $self->{sequence} ]
        )
        ) {
        if (
            not
            defined @{ $self->{config}->{points} }[ $self->{sequence} + 1 ] )
        {
            if ( $self->{config}->{stabilize} == 1 ) {
                carp('Reached maximum stabilization time.');
            }
            return 1;
        }

        $self->{iterator} = 0;
        $self->{sequence}++;
        return 0;
    }
    elsif ( $self->{config}->{stabilize} == 1 ) {
        my @sensor_args = @{ $self->{config}->{sensor_args} };
        push(
            @{ $self->{stabilize}->{data} },
            $self->{config}->{sensor}->get_value(@sensor_args)
        );

        my $SENSOR_STD_DEV_PRINT = '-' x 10;
        say "ELAPSED: " . sprintf( '%.2f', $self->{Time} );

        if ( $self->{Time} >= $self->{config}->{stabilize_observation_time} )
        {
            shift( @{ $self->{stabilize}->{data} } );

            my $stat = Statistics::Descriptive::Full->new();
            $stat->add_data( $self->{stabilize}->{data} );
            my $SENSOR_STD_DEV = $stat->standard_deviation();
            $SENSOR_STD_DEV_PRINT = sprintf( '%.3e', $SENSOR_STD_DEV );

            say "CURRENT_STDD: "
                . $SENSOR_STD_DEV_PRINT
                . " / TARGET_STDD: "
                . sprintf( '%.3e', $self->{config}->{std_dev_sensor} );

            if ( $SENSOR_STD_DEV <= $self->{config}->{std_dev_sensor} ) {
                carp('Reached stabilization criterion.');
                return 1;
            }
        }

        return 0;
    }
    else {
        return 0;
    }
}

sub get_value {
    my $self = shift;
    return $self->{Time};
}

sub go_to_sweep_start {
    my $self = shift;

    $self->{sequence}++;
}

sub halt {
    return shift;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::Time - Simple time-controlled repeater (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

	use Lab::Measurement::Legacy;
	
	my $time_sweep = Sweep('Time',
		{
		duration => 5
		});

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::Time class implements a simple time controlled repeater module in the Lab::XPRESS::Sweep framework.

=head1 CONSTRUCTOR

	my $time_sweep = Sweep('Time',
		{
		duration => 5,
		interval => 0.5
		});

Instantiates a new Time-Sweep with a duration of 5 seconds and a Measurement interval of 5 seconds.
To operate in the stabilization mode make an instant like the following:

	my $time_sweep = Sweep('Time',
		{
		stabilize => 1,		
		sensor => $DIGITAL_MULTIMETER,
		std_dev_sensor => 1e-6,
		stabilize_observation_time => 3*60,

		duration => 20*60,
		interval => 0.5
		});

=head1 PARAMETERS

=head2 duration [float] (default = 1)

duration for the time controlled repeater. Default value is 1, negative values indicate a infinit number of repetitions.
In stabilization mode, the duration gives the maximum duration which is waited before the sweep gets interrupted even though the stabilization criterion hasn't been reached yet.

=head2 interval [float] (default = 1)

interval in seconds for taking measurement points.

=head2 id [string] (default = 'Repeater')

Just an ID.

=head2 delay_before_loop [float] (default = 0)

defines the time in seconds to wait after the starting point has been reached.

=head2 delay_after_loop [float] (default = 0)

Defines the time in seconds to wait after the sweep has been finished. This delay will be executed before an optional backsweep or optional repetitions of the sweep.

=head2 stabilize [int] (default = 0)

1 = Activate stabilization mode. In this mode the sweep will be interrupted when a stabilization criterion is reached or when the duration expires, whatever is reached first.
The variable to stabilize on is the value which is returned by the get_value function corresponding to the instrument handle given to the parameter 'sensor'. The stabilization criterion can be set in 'std_dev_sensor' as a number which has the same unit as the variable, that is supposed to stabilize.
When the standard deviation of a time series of the stabilization variable falls below 'std_dev_sensor', the sweep ends. The length of the time window, which is used to calculate the standard deviation is given by 'stabilize_observation_time'. The standarad deviation is not being calculated by the sweep, before the time window isn't filled with data completely.
Therefore, the sweep will never last less than 'stabilize_observation_time', unless 'duration' < 'stabilize_observation_time'.

0 = Deactivate stabilization mode.

=head2 sensor [Lab::Instrument] (default = undef)

See 'stabilize'.

=head2 std_dev_sensor [float] (default = 1e-6),

See 'stabilize'.

=head2 stabilize_observation_time [float] (default = 3*60)

See 'stabilize'.

=head1 CAVEATS/BUGS

probably none

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2015       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
