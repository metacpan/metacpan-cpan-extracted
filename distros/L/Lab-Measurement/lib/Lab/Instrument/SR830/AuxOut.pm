package Lab::Instrument::SR830::AuxOut;
#ABSTRACT: Aux Outputs of the Stanford Research SR830 Lock-In Amplifier
$Lab::Instrument::SR830::AuxOut::VERSION = '3.881';
use v5.20;


use warnings;
use strict;


use Lab::Instrument;
use Data::Dumper;
use Carp;

use parent qw/Lab::Instrument::Source/;

our %fields = (
    supported_connections => [ 'GPIB', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        timeout      => 1
    },

    device_settings => {
        gate_protect => 1,

        #gp_equal_level          => 1e-5,
        gp_max_units_per_second => 0.005,
        gp_max_units_per_step   => 0.001,
        gp_max_step_per_second  => 5,

        max_sweep_time => 3600,
        min_sweep_time => 0.1,

        stepsize => 0.01,

    },

    channel => undef,
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    $self->empty_buffer();
    my $channel = $self->channel;
    if ( not defined $channel ) {
        croak "need channel (1-4) in constructor for ", __PACKAGE__;
    }
    elsif ( $channel !~ /^[1-4]$/ ) {
        croak "channel '$channel' is not in the range (1..4)";
    }
    return $self;
}

sub empty_buffer {
    my $self = shift;
    my ($times) = $self->_check_args( \@_, ['times'] );
    if ($times) {
        for ( my $i = 0; $i < $times; $i++ ) {
            eval { $self->read( brutal => 1 ) };
        }
    }
    else {
        while ( $self->read( brutal => 1 ) ) {
            print "Cleaning buffer.";
        }
    }
}


sub _set_level {
    my $self = shift;
    my ( $value, $tail ) = $self->_check_args( \@_, ['value'] );

    if ( abs($value) > 10.5 ) {
        Lab::Exception::CorruptParameter->throw(
            "The desired source level $value is not within the source range (10.5 V) \n"
        );
    }

    my $cmd = sprintf( "AUXV %d, %ee", $self->{channel}, $value );

    $self->write( $cmd, { error_check => 1 }, $tail );

    return $value;
}


sub set_voltage {
    my $self = shift;
    my ( $voltage, $tail ) = $self->_check_args( \@_, ['voltage'] );

    return $self->set_level( $voltage, $tail );
}


sub get_level {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );
    my $channel = $self->channel;
    return $self->query( "AUXV? $channel", $tail );
}

sub active {
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::SR830::AuxOut - Aux Outputs of the Stanford Research SR830 Lock-In Amplifier

=head1 VERSION

version 3.881

=head1 SYNOPSIS

 use Lab::Instrument::SR830::AuxOut
 my $output = Lab::Instrument::SR830::AuxOut->new(%options, channel => 1);

=head1 DESCRIPTION

This class provides access to the four DC outputs of the SR830. You have to
provide a C<channel> (1..4) parameter in the constructor. 

B<To use multiple virtual instruments, which use the same physical device, you have to share the connection between the virtual instruments:>

 use Lab::Measurement;

 # Create the shared connection. 
 my $connection = Connection('LinuxGPIB', {gpib_address => 8});
 
 # Create two outputs.
 my $gate = Instrument('SR830::AuxOut', {connection => $connection,
					channel => 1,
					gate_protect => 0});
 my $bias = Instrument('SR830::AuxOut', {connection => $connection,
					channel => 2,
					gate_protect => 0});

You can now use C<$gate> and C<$bias> to build XPRESS L<Voltage
Sweeps|Lab::XPRESS::Sweep::Voltage>. The SR830 does not have hardware support
for continuous voltage sweeps. Thus, the C<mode> parameter of the sweep must be
set to C<'step'> or C<'list'> and the C<jump> parameter must be set to
C<1>. Example sweep configuration:

 my $gate_sweep = Sweep('Voltage',
 		       {
 			       mode => 'step',
 			       instrument => $gate,
 			       points => [-0.1,0.1],
 			       stepwidth => [0.001],
 			       jump => 1,
 			       rate => [0.001],
 			       
 		       });
 
 my $bias_sweep = Sweep('Voltage',
 		       {
 			       mode => 'step',
 			       instrument => $bias,
 			       points => [-0.1,0.1],
 			       stepwidth => [0.001],
 			       rate => [0.001],
 			       jump => 1,
 		       });

=head1 Methods

=head2 _set_level($voltage)

Set the output voltage. Will throw an exception, if the absolute value of
C<$voltage> is bigger than 10.5 V. 

=head2 set_voltage($voltage)

Equivalent to C<_set_level>.

=head2 set_level($voltage)

See L<Lab::Instrument::Source>.

=head2 get_level()

Query the current output voltage.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
