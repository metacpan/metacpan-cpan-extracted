package Lab::Moose::Instrument::OI_ITC503;
$Lab::Moose::Instrument::OI_ITC503::VERSION = '3.792';
#ABSTRACT: Oxford Instruments ITC503 Intelligent Temperature Control

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Countdown 'countdown';
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

has empty_buffer_count =>
    ( is => 'ro', isa => 'Lab::Moose::PosInt', default => 1 );
has auto_pid => ( is => 'ro', isa => 'Bool', default => 1 );

has high_temp_sensor =>
    ( is => 'ro', isa => enum( [qw/1 2 3/] ), default => 3 );
has low_temp_sensor =>
    ( is => 'ro', isa => enum( [qw/1 2 3/] ), default => 2 );

# currently used sensor
has t_sensor => ( is => 'rw', isa => enum( [qw/1 2 3/] ), default => 3 );

# most function names should be backwards compatible with the
# Lab::Instrument::OI_ITC503 driver

sub BUILD {
    my $self = shift;

    warn "The ITC driver is work in progress. You have been warned\n";

    # Unlike modern GPIB equipment, this device does not assert the EOI
    # at end of message. The controller shell stop reading when receiving the
    # eos byte.

    $self->connection->set_termchar( termchar => "\r" );
    $self->connection->enable_read_termchar();
    $self->clear();

    # Dont clear the instrument since that may make it unresponsive.
    # Instead, set the communication protocol to "Normal", which should
    # also clear all communication buffers.
    $self->write( command => "Q0\r" );    # why not use set_control ???
    $self->set_control( value => 3 );

    if ( $self->auto_pid ) {
        warn "setting PID to AUTO\n";
        $self->itc_set_PID_auto( value => 1 );
    }

}


# query wrapper with error checking
around query => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $result = $self->$orig(@_);

    chomp $result;
    my $cmd = $args{command};
    my $cmd_char = substr( $cmd, 0, 1 );

    # ITC query answers always start with the command character
    # if successful with a question mark and the command char on failure
    my $status = substr( $result, 0, 1 );
    if ( $status eq '?' ) {
        croak "ITC503 returned error '$result' on command '$cmd'";
    }
    elsif ( defined $cmd_char and ( $status ne $cmd_char ) ) {
        croak
            "ITC503 returned unexpected answer. Expected '$cmd_char' prefix, 
received '$status' on command '$cmd'";
    }
    return substr( $result, 1 );
};


sub set_control {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1 2 3/] ) },
    );
    my $result = $self->query( command => "C$value\r", %args );
    sleep(1);
    return $result;
}


sub itc_set_communications_protocol {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 2/] ) }
    );
    return $self->query( command => "Q$value\r" );
}

# For Lab::Moose::Sweep interface
sub set_T {
    my $self = shift;
    $self->itc_set_T(@_);
}


sub itc_set_T {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' },
    );
    my $t_sensor         = $self->t_sensor;
    my $high_temp_sensor = $self->high_temp_sensor;
    my $low_temp_sensor  = $self->low_temp_sensor;

    if ( $value < 1.5 && $t_sensor != $low_temp_sensor ) {
        $t_sensor = $low_temp_sensor;
    }
    elsif ( $value >= 1.5 && $t_sensor != $high_temp_sensor ) {
        $t_sensor = $high_temp_sensor;
    }
    $self->itc_set_heater_auto( value => 0 );
    $self->itc_set_heater_sensor( value => $t_sensor );
    $self->itc_set_heater_auto( value => 1 );
    $self->itc_T_set_point( value => $value );

    warn "Set temperature $value with sensor $t_sensor\n";
    $self->t_sensor($t_sensor);
}


sub get_value {
    my ( $self, %args ) = validated_getter( \@_ );
    my $t_sensor         = $self->t_sensor();
    my $high_temp_sensor = $self->high_temp_sensor();
    my $low_temp_sensor  = $self->low_temp_sensor();
    my $temp             = $self->itc_read_parameter( param => $t_sensor );
    $temp = $self->itc_read_parameter( param => $t_sensor );
    $temp = $self->itc_read_parameter( param => $t_sensor );
    if ( $temp < 1.5 && $t_sensor != $low_temp_sensor ) {
        $t_sensor = $low_temp_sensor;
        $temp     = $self->itc_read_parameter( param => $t_sensor );
        $temp     = $self->itc_read_parameter( param => $t_sensor );
        $temp     = $self->itc_read_parameter( param => $t_sensor );
        warn "Switching to sensor $t_sensor at temperature $temp\n";
    }
    elsif ( $temp >= 1.5 && $t_sensor != $high_temp_sensor ) {
        $t_sensor = $high_temp_sensor;
        $temp     = $self->itc_read_parameter( param => $t_sensor );
        $temp     = $self->itc_read_parameter( param => $t_sensor );
        $temp     = $self->itc_read_parameter( param => $t_sensor );
        warn "Switching to sensor $t_sensor at temperature $temp\n";
    }
    warn "Read temperature $temp with sensor $t_sensor\n";
    $self->t_sensor($t_sensor);
    return $temp;
}


sub get_T {
    my $self = shift;
    return $self->get_value(@_);
}


sub itc_read_parameter {
    my ( $self, %args ) = validated_getter(
        \@_,
        param => { isa => enum( [qw/0 1 2 3 4 5 6 7 8 9 10 11 12 13/] ) },
    );
    my $param = delete $args{param};
    my $result = $self->query( command => "R$param\r", %args );
    return sprintf( "%e", $result );
}


sub itc_set_wait {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );
    $self->query( command => "W$value\r" );
}


sub itc_examine {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "X\r", %args );
}

# for XPRESS compatiblity
sub set_heatercontrol {
    my $self = shift;
    my $mode = shift;

    if ( $mode eq 'MAN' ) {
        $self->itc_set_heater_auto( value => 0 );
    }
    elsif ( $mode eq 'AUTO' ) {
        $self->itc_set_heater_auto( value => 1 );
    }
    else {
        warn "set_heatercontrol received an invalid parameter: $mode\n";
    }

}


sub itc_set_heater_auto {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1 2 3/] ) }
    );
    return $self->query( command => "A$value\r", %args );
}

# for XPRESS compatibility
sub set_PID {
    my $self = shift;
    my $p    = shift;
    my $i    = shift;
    my $d    = shift;
    $self->itc_set_PID( p => $p, i => $i, d => $d );
}


sub itc_set_PID {
    my ( $self, %args ) = validated_getter(
        \@_,
        p => { isa => 'Num' },
        i => { isa => 'Num' },
        d => { isa => 'Num' },
    );
    $self->itc_set_proportional_value( value => $args{p} );
    $self->itc_set_integral_value( value => $args{i} );
    $self->itc_set_derivative_value( value => $args{d} );
}

sub itc_set_proportional_value {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );
    $self->itc_set_PID_auto( value => 0 );
    return $self->query( command => "P$value\r", %args );
}

sub itc_set_integral_value {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );
    $self->itc_set_PID_auto( value => 0 );
    return $self->query( command => "I$value\r", %args );
}

sub itc_set_derivative_value {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' }
    );
    $self->itc_set_PID_auto( value => 0 );
    return $self->query( command => "D$value\r", %args );
}


sub itc_set_heater_sensor {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 1, 2, 3 ] ) }
    );
    return $self->query( command => "H$value\r", %args );
}


sub itc_set_PID_auto {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1/] ) }
    );
    return $self->query( command => "L$value\r", %args );
}


# in 0.1 V
# 0 dynamical varying limit
sub itc_set_max_heater_voltage {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    return $self->query( command => "M$value\r", %args );
}

# from 0 to 0.999
# 0 dynamical varying limit


sub itc_set_heater_output {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $value = sprintf( "%d", 1000 * $value );
    return $self->query( command => "O$value\r", %args );
}


sub itc_T_set_point {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    $value = sprintf( "%.3f", $value );
    return $self->query( command => "T$value\r" );
}

#
#
# subs below need some more care
#
#

sub itc_sweep {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosInt' },
    );
    if ( $value > 32 ) {
        croak "value argument of itc_sweep must be in the range 0..32";
    }
    return $self->query( command => "S$value\r", %args );
}

sub itc_set_pointer {

    # Sets Pointer in internal ITC memory
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    if ( $x < 0 or $x > 128 ) {
        printf "x=$x no valid ITC Pointer value\n";
        die;
    }
    if ( $y < 0 or $y > 128 ) {
        printf "y=$y no valid ITC Pointer value\n";
        die;
    }
    my $cmd = sprintf( "x%d\r", $x );
    $self->query( command => $cmd );
    $cmd = sprintf( "y%d\r", $y );
    $self->query( command => $cmd );
}

sub itc_program_sweep_table {
    my $self      = shift;
    my $setpoint  = shift;    #K Sweep Stop Point
    my $sweeptime = shift;    #Min. Total Sweep Time
    my $holdtime  = shift;    #sec. Hold Time

    if ( $setpoint < 0. or $setpoint > 9.9 ) {
        printf "Cannot reach setpoint: $setpoint\n";
        die;
    }

    $self->itc_set_pointer( 1, 1 );
    $setpoint = sprintf( "%1.4f", $setpoint );
    $self->query( command => "s$setpoint\r" );

    $self->itc_set_pointer( 1, 2 );
    $sweeptime = sprintf( "%.4f", $sweeptime );
    $self->query( command => "s$sweeptime\r" );

    $self->itc_set_pointer( 1, 3 );
    $holdtime = sprintf( "%.4f", $holdtime );
    $self->query( command => "s$holdtime\r" );

    $self->itc_set_pointer( 0, 0 );
}

sub itc_read_sweep_table {

    # Clears Sweep Program Table
    my $self = shift;
    $self->query( command => "r\r" );
}

sub itc_clear_sweep_table {

    # Clears Sweep Program Table
    my $self = shift;
    $self->query( command => "w\r" );
}


sub heat_sorb {
    my $self = shift;
    my (
        $max_temp,    $max_temp_time, $middle_temp, $middle_temp_time,
        $target_temp, $sorb_sensor
        )
        = validated_list(
        \@_,
        max_temp      => { isa => 'Lab::Moose::PosNum', default => 30 },
        max_temp_time => { isa => 'Lab::Moose::PosNum', default => 20 * 60 },
        middle_temp   => { isa => 'Lab::Moose::PosNum', default => 10 },
        middle_temp_time => { isa => 'Lab::Moose::PosNum', default => 200 },
        target_temp      => { isa => 'Lab::Moose::PosNum', default => 0.3 },
        sorb_sensor => { isa => enum( [ 1, 2, 3 ] ), default => 1 },
        );
    warn "Heating sorb\n";
    $self->itc_set_heater_auto( value => 0 );
    $self->itc_set_PID_auto( value => 1 );

    $self->itc_set_heater_output( value => 0 );
    $self->itc_set_heater_sensor( value => $sorb_sensor );
    $self->itc_T_set_point( value => $middle_temp );

    $self->itc_set_heater_auto( value => 1 );

    warn "Sorb setpoint set to $middle_temp K\n";
    countdown( $middle_temp_time, "Waiting for $middle_temp_time seconds: " );

    $self->itc_T_set_point( value => $max_temp );
    $self->itc_set_heater_auto( value => 1 );
    warn "Sorb setpoint set to $max_temp K\n";
    countdown( $max_temp_time, "Waiting for $max_temp_time seconds: " );
    warn "He3 should be condensated. Switching off heater\n";

    $self->itc_set_heater_auto( value => 0 );
    $self->itc_set_heater_output( value => 0 );
    $self->itc_set_PID_auto( value => 1 );
    warn "Waiting until target temperature $target_temp is reached\n";
    while (1) {
        my $temp = $self->get_value();
        warn "temp: $temp\n";
        if ( $temp <= $target_temp ) {
            warn "reached target temperature\n";
            last;
        }
        sleep(5);
    }
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::OI_ITC503 - Oxford Instruments ITC503 Intelligent Temperature Control

=head1 VERSION

version 3.792

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $itc = instrument(
     type => 'OI_ITC503',
     connection_type => 'LinuxGPIB',
     connection_options => {pad => 10},
 );


 # Get temperature
 say "Temperature: ", $itc->get_value();

 # Set heater to AUTO
 $itc->itc_set_heater_auto( value => 0 );

 # Set PID to AUTO
 $itc->itc_set_PID_auto( value => 1 );

=head1 DESCRIPTION

By default, two temperature sensors are used: Sensor 2 for temperatures below
1.5K and sensor 3 for temperatures above 1.5K. The used sensors can be set in
the constructor, e.g.

 my $itc = instrument(
     ...
     high_temp_sensor => 2,
     low_temp_sensor => 3
 );

The L</get_value> and L</set_T> functions will dynamically choose the proper sensor.

=head1 METHODS

=head2 set_control

 $itc->set_control(value => 1);

Set device local/remote mode (0, 1, 2, 3)

=head2 itc_set_communications_protocol

 $itc->itc_set_communications_protocol(value => 0); # 0 or 2

=head2 itc_set_T

 $itc->itc_set_T(value => 0.5);

Set target temperature.

=head2 get_value

 my $temp = $itc->get_value();

Get current temperature value.

=head2 get_T

Alias for L</get_value>.

=head2 itc_read_parameter

 my $value = $itc->itc_read_parameter(param => 1);

Allowed values for C<param> are 0..13

=head2 itc_set_wait

 $itc->itc_set_wait(value => $milli_seconds);

=head2 itc_examine

 my $status = $itc->itc_examine();

=head2 itc_set_heater_auto

 $itc->itc_set_heater_auto(value => 0);

Allowed values:
0 Heater Manual, Gas Manual;
1 Heater Auto, Gas Manual
2 Heater Manual, Gas Auto
3 Heater Auto, Gas Auto

=head2 itc_set_PID

 $itc->itc_set_PID(
     p => $p,
     i => $i,
     d => $d
 );

=head2 itc_set_heater_sensor

 $itc->itc_set_heater_sensor( value => 1 );

Value must be one of 1, 2, or 3.

=head2 itc_set_PID_auto

 $itc->itc_set_PID_auto(value => 1); # enable
 $itc->itc_set_PID_auto(value => 0); # disable

=head2 itc_set_max_heater_voltage

 $itc->itc_set_max_heater_voltage(value => $voltage);

=head2 itc_set_heater_output

 $itc->itc_set_heater_output(value => $output); # value from 0 to 0.999

=head2 itc_T_set_point

 $itc->itc_T_set_point(value => $temp);

=head2

 $itc->heat_sorb(
     max_temp => $max_temp, # default: 30 K
     max_temp_time => ..., # default: 20 * 60 seconds
     middle_temp => ..., # default: 20 K
     middle_temp_time => ..., # default: 200 seconds
     target_time => ..., # default: 0.3 K
     sorb_sensor => ..., # default: 1
     sample_sensor => ..., # default: 2
 );

Heat the sorb of a 3-He cryostat (like OI HelioxVL). The sorb temperature is
first set to C<middle_temp> for C<middle_temp_time> seconds, then to
C<max_temp> for C<max_temp_time> seconds. Then the heater is switched off and
the routine returns when the temperature at C<sample_sensor> has dropped below C<target_time>.  

=head2 Consumed Roles

This driver consumes the following roles:

=over

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
