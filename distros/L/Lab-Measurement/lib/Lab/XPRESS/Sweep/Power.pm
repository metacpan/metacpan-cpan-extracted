package Lab::XPRESS::Sweep::Power;
#ABSTRACT: Signal generator power sweep
$Lab::XPRESS::Sweep::Power::VERSION = '3.881';
use v5.20;

use Lab::XPRESS::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto                  = shift;
    my @args                   = @_;
    my $class                  = ref($proto) || $proto;
    my $self->{default_config} = {
        id                  => 'Power_Sweep',
        filename_extension  => 'POW=',
        interval            => 1,
        points              => [],
        rate                => [1],
        mode                => 'step',
        allowed_instruments => [
            'Lab::Instrument::HP83732A', 'Lab::Instrument::MG369xB',
            'Lab::Instrument::RSSMB100A'
        ],
        allowed_sweep_modes => [ 'list', 'step' ],
        number_of_points    => [undef]
    };

    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );

    return $self;
}

sub go_to_sweep_start {
    my $self = shift;

    # go to start:
    $self->{config}->{instrument}
        ->set_power( { value => @{ $self->{config}->{points} }[0] } );
}

sub start_continuous_sweep {
    my $self = shift;

    return;

}

sub go_to_next_step {
    my $self = shift;

    $self->{config}->{instrument}->set_power(
        { value => @{ $self->{config}->{points} }[ $self->{iterator} ] } );

}

sub exit_loop {
    my $self = shift;

    if ( $self->{config}->{mode} =~ /step|list/ ) {
        if (
            not
            defined @{ $self->{config}->{points} }[ $self->{iterator} + 1 ] )
        {
            return 1;
        }
        else {
            return 0;
        }
    }
}

sub get_value {
    my $self = shift;
    return $self->{config}->{instrument}->get_power();
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

Lab::XPRESS::Sweep::Power - Signal generator power sweep

=head1 VERSION

version 3.881

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	
	my $Osc = $hub->Instrument('HP83732A', 
		{
		connection_type => 'VISA_GPIB',
		gpib_address => 2
		});
	
	my $sweep_voltage = $hub->Sweep('Power',
		{
		instrument => $Osc,
		points => [0,10],
		stepwidth => [1],
		mode => 'step',		
		backsweep => 0 
		});

.

=head1 DESCRIPTION

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::Power class implements a module for power sweeps in the Lab::XPRESS::Sweep framework.

.

=head1 CONSTRUCTOR

		my $sweep_voltage = $hub->Sweep('Power',
		{
		instrument => $Osc,
		points => [100,1e5],
		stepwidth => [1e5,100],
		mode => 'step',		
		backsweep => 0 
		});

Instantiates a new power sweep.

.

=head1 PARAMETERS

=head2 instrument [Lab::Instrument] (mandatory)

Instrument, conducting the sweep. Must be of type Lab:Instrument. 
Allowed instruments: Lab::Instrument::SignalRecovery726x

.

=head2 mode [string] (default = 'step' | 'list')

step: measurements will be performed at discrete values of the power between start and end points defined in parameter points, seperated by steps defined in parameter stepwidth

list: measurements will be performed at a list frequencies defined in parameter points

.

=head2 points [float array] (mandatory)

array of values (in Hz) that defines the characteristic points of the sweep.
First value is appraoched before measurement begins. 

Case mode => 'step' :
Same as in 'continuous' but power will be swept in stop and go mode. 

Case mode => 'list' :
Array of values, with minimum length 1, that are approached in sequence to perform a measurment.

.

=head2 stepwidth [float array]

This parameter is relevant only if mode = 'step' has been selected. 
Stepwidth has to be an array of length '1' or greater. The values define the width for each step within the corresponding sweep sequence. 
If the length of the defined sweep sequence devided by the stepwidth is not an integer number, the last step will be smaller in order to reach the defined points-value.

	points = [100, 3000, 300]
	stepwidth = [500, 1000]
	
	==> steps: 100, 600, 1100, 1600, 2100, 2600, 3000, 2000, 1000, 300

.

=head2 number_of_points [int array]

can be used instead of 'stepwidth'. Attention: Use only the 'number_of_points' or the 'stepwidth' parameter. Using both will cause an Error!
This parameter is relevant only if mode = 'step' has been selected. 
Number_of_points has to be an array of length '1' or greater. The values defines the number of steps within the corresponding sweep sequence.

	points = [100, 3000, 300]
	number_of_points = [10, 2]
	
	==> steps: 100, 390, 680, 970, 1260, 1550, 1840, 2130, 2420, 2710, 3000, 1650, 300

=head2 backsweep [int] (default = 0 | 1 | 2)

0 : no backsweep (default)
1 : a backsweep will be performed
2 : no backsweep performed automatically, but sweep sequence will be reverted every second time the sweep is started (relevant eg. if sweep operates as a slave. This way the sweep sequence is reverted at every second step of the master)

=head2 id [string] (default = 'Power_Sweep')

Just an ID.

=head2 filename_extention [string] (default = 'FRQ=')

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

  Copyright 2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
