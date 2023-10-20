package Lab::XPRESS::Sweep::Voltage;
$Lab::XPRESS::Sweep::Voltage::VERSION = '3.899';
#ABSTRACT: Voltage sweep

use v5.20;

use Lab::XPRESS::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use warnings;
use strict;
use Carp;
our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto                  = shift;
    my @args                   = @_;
    my $class                  = ref($proto) || $proto;
    my $self->{default_config} = {
        id                  => 'Voltage_sweep',
        filename_extension  => 'V=',
        interval            => 1,
        points              => [],
        duration            => [],
        mode                => 'continuous',
        jump                => 0,
        allowed_instruments => [
            qw/
                Lab::Instrument::Yokogawa7651 Lab::Instrument::Keithley2400
                Lab::Moose::Instrument::KeysightE3633E
                Lab::Instrument::YokogawaGS200 Lab::Instrument::DummySource
                Lab::Instrument::SR830::AuxOut Lab::Moose::Instrument::DummySource
                Lab::Moose::Instrument::YokogawaGS200 Lab::Moose::Instrument::ZI_MFLI Lab::Moose::Instrument::ZI_MFIA/
        ],
        allowed_sweep_modes => [ 'continuous', 'list', 'step' ],
        number_of_points    => [undef]
    };

    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );

    return $self;
}

sub go_to_sweep_start {
    my $self = shift;

    # go to start:
    print "Setting voltage to start value ... ";
    if (   $self->{config}->{mode} =~ /step|list/
        && $self->{config}->{jump} ) {
        my $target    = $self->{config}{points}[ $self->{iterator} ];
        my $rate      = $self->{config}{rate}[ $self->{iterator} ];
        my $current   = $self->{config}{instrument}->get_level();
        my $stepwidth = $self->{config}{stepwidth}[ $self->{iterator} ];
        if ( not defined $stepwidth ) {
            croak "no 'stepwidth' defined for sweep with mode 'step'";
        }
        my $time = abs( ( $target - $current ) / $rate );
        $self->{config}{instrument}
            ->sweep_to_level( $target, $time, $stepwidth );
    }
    else {
        $self->{config}->{instrument}->config_sweep(
            {
                'points' =>
                    @{ $self->{config}->{points} }[ $self->{iterator} ],
                'rate' => @{ $self->{config}->{rate} }[ $self->{iterator} ]
            }
        );
        $self->{config}->{instrument}->trg();
        $self->{config}->{instrument}->wait();
    }
    print "Done                                                     \n";

}

sub start_continuous_sweep {
    my $self = shift;

    $self->{config}->{instrument}->config_sweep(
        {
            'points' =>
                @{ $self->{config}->{points} }[ $self->{iterator} + 1 ],
            'rate' => @{ $self->{config}->{rate} }[ $self->{iterator} + 1 ]
        }
    );
    $self->{config}->{instrument}->trg();
}

sub go_to_next_step {
    my $self = shift;

    if ( $self->{config}->{jump} == 1 ) {
        $self->{config}->{instrument}->set_voltage(
            ${ $self->{config}->{points} }[ $self->{iterator} ] );
    }
    else {
        $self->{config}->{instrument}->config_sweep(
            {
                'points' =>
                    @{ $self->{config}->{points} }[ $self->{iterator} ],
                'rate' => @{ $self->{config}->{rate} }[ $self->{iterator} ]
            }
        );
        $self->{config}->{instrument}->trg();
        $self->{config}->{instrument}->wait();
    }
}

sub exit_loop {
    my $self = shift;

    #    if ( not $self->{config}->{instrument}->active() ) {
    if ( $self->{config}->{mode} =~ /step|list/ ) {
        if (
            not
            defined @{ $self->{config}->{points} }[ $self->{iterator} + 1 ] )
        {
            return 1;
        }
        return 0;
    }
    if ( not $self->{config}->{instrument}->active() ) {
        if ( $self->{config}->{mode} eq "continuous" ) {
            if (
                not defined @{ $self->{config}->{points} }
                [ $self->{sequence} + 2 ] ) {
                return 1;
            }
            $self->{sequence}++;
            $self->{config}->{instrument}->config_sweep(
                {
                    'points' => @{ $self->{config}->{points} }
                        [ $self->{sequence} + 1 ],
                    'rate' =>
                        @{ $self->{config}->{rate} }[ $self->{sequence} + 1 ]
                }
            );
            $self->{config}->{instrument}->trg();
        }
        return 0;
    }
    else {
        return 0;
    }
}

sub get_value {
    my $self = shift;
    return $self->{config}->{instrument}->get_level();
}

sub exit {
    my $self = shift;
    $self->{config}->{instrument}->abort();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::Voltage - Voltage sweep (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	
	my $Yoki = $hub->Instrument('Yokogawa7651', 
		{
		connection_type => 'VISA_GPIB',
		gpib_address => 2
		});
	
	my $sweep_voltage = $hub->Sweep('Voltage',
		{
		instrument => $Yoki,
		points => [-1,1],
		rate => [0.1,0.001],
		mode => 'continuous',		
		interval => 1,
		backsweep => 1 
		});

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::Voltage class implements a module for voltage Sweeps in the Lab::XPRESS::Sweep framework.

=head1 CONSTRUCTOR

	my $sweep_voltage = $hub->Sweep('Voltage',
		{
		instrument => $Yoki,
		points => [-1,1],
		rate => [0.1,0.001],
		mode => 'continuous',		
		interval => 1,
		backsweep => 1 
		});

Instantiates a new voltage-sweep.

=head1 PARAMETERS

=head2 instrument [Lab::Instrument] (mandatory)

Instrument, conducting the sweep. Must be of type Lab:Instrument. 
Allowed instruments: Lab::Instrument::Yokogawa7651

=head2 mode [string] (default = 'continuous' | 'step' | 'list')

continuous: perform a continuous voltage sweep. Measurements will be performed constantly at the time-interval defined in interval.

step: measurements will be performed at discrete values of the applied voltage between start and end points defined in parameter points, seperated by voltage steps defined in parameter stepwidth

list: measurements will be performed at a list voltage values defined in parameter points

=head2 points [float array] (mandatory)

array of voltage values (in volts) that defines the characteristic points of the sweep.
First value is appraoched before measurement begins. 

Case mode => 'continuous' :
List of at least 2 values, that define start and end point of the sweep or a sequence of consecutive sweep-sections (e.g. if changing the sweep-rate for different sections or reversing the sweep direction). 
	 	points => [-5, 5]	# Start: -5 / Stop: 5

		points => [-5, -1, 1, 5]

		points => [0, -5, 5]

Case mode => 'step' :
Same as in 'continuous' but voltage will be swept in stop and go mode. I.e. voltage source approaches values between start and stop at the interval defined in 'stepwidth'. A measurement is performed, when voltage source is idle.

Case mode => 'list' :
Array of voltages, with minimum length 1, that are approached in sequence to perform a measurment.

=head2 rate [float array] (mandatory if not defined duration)

array of rates, at which the voltage is swept (V / sec).
Has to be of length 1 or greater (Maximum length: length of points-array).
The first value defines the rate to approach the starting point. 
The following values define the rates to approach the voltages defined by the points-array.
If the number of values in the rates-array is less than the length of the points-array, the last defined rate will be used for the remaining sweep sections.

	points => [-5, -1, 1, 5],
	rates => [1, 0.005, 0.02]
	
	rate to approach -5 V (the starting point): 1 V/sec 
	rate to approach -1 V  : 0.005 V/sec 
	rate to approach 1 V   : 0.02 V/sec 
	rate to approach 5 V   : 0.02 V/sec (last defined rate)

=head2 duration [float array] (mandatory if not defined rate)

can be used instead of 'rate'. Attention: Use only the 'duration' or the 'rate' parameter. Using both will cause an Error!

The first value defines the duration to approach the starting point. 
The second value defines the duration to approach the voltage value defined by the second value of the points-array.
...
If the number of values in the duration-array is less than the length of the points-array, last defined duration will be used for the remaining sweep sections.

=head2 stepwidth [float array]

This parameter is relevant only if mode = 'step' has been selected. 
Stepwidth has to be an array of length '1' or greater. The values define the width for each step within the corresponding sweep sequence. 
If the length of the defined sweep sequence devided by the stepwidth is not an integer number, the last step will be smaller in order to reach the defined points-value.

	points = [0, 0.5, 3]
	stepwidth = [0.2, 0.5]
	
	==> steps: 0, 0.2, 0.4, 0.5, 1.0, 1.5, 2.0, 2.5, 3

=head2 number_of_points [int array]

can be used instead of 'stepwidth'. Attention: Use only the 'number_of_points' or the 'stepwidth' parameter. Using both will cause an Error!
This parameter is relevant only if mode = 'step' has been selected. 
Number_of_points has to be an array of length '1' or greater. The values defines the number of steps within the corresponding sweep sequence.

	points = [0, 0.5, 3]
	number_of_points = [5, 2]
	
	==> steps: 0, 0.1, 0.2, 0.3, 0.4, 0.5, 1.75, 3

=head2 interval [float] (default = 1)

interval in seconds for taking measurement points. Only relevant in mode 'continuous'.

=head2 backsweep [int] (default = 0 | 1 | 2)

0 : no backsweep (default)
1 : a backsweep will be performed
2 : no backsweep performed automatically, but sweep sequence will be reverted every second time the sweep is started (relevant eg. if sweep operates as a slave. This way the sweep sequence is reverted at every second step of the master)

=head2 jump [int] (default = 0 | 1 )

can be used to switch off the sweeping between adjacent points in step or list mode.

0 : a sweep is performed between adjacent steps (default)
1 : the voltage is set without sweeping, given that gateprotect does not trigger a sweep.

=head2 id [string] (default = 'Voltage_sweep')

Just an ID.

=head2 filename_extention [string] (default = 'V=')

Defines a postfix, that will be appended to the filenames if necessary.

=head2 delay_before_loop [int] (default = 0)

defines the time in seconds to wait after the starting point has been reached.

=head2 delay_in_loop [int] (default = 0)

This parameter is relevant only if mode = 'step' or 'list' has been selected. 
Defines the time in seconds to wait after the value for the next step has been reached.

=head2 delay_after_loop [int] (default = 0)

Defines the time in seconds to wait after the sweep has been finished. This delay will be executed before an optional backsweep or optional repetitions of the sweep.

=head1 CAVEATS/BUGS

probably none

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Alois Dirnaichner, Andreas K. Huettel
            2015       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
