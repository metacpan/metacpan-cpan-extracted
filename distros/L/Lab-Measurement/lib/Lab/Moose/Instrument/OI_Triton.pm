package Lab::Moose::Instrument::OI_Triton;
$Lab::Moose::Instrument::OI_Triton::VERSION = '3.682';
#ABSTRACT: Oxford Instruments Triton gas handling system control

use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate 'validated_hash';
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use YAML::XS;

extends 'Lab::Moose::Instrument';

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has max_temperature => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    default => 0.7
);

# default connection options:
around default_connection_options => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = $self->$orig();

    $options->{Socket}{port}    = 33576;
    $options->{Socket}{timeout} = 10;
    return $options;
};

with qw(Lab::Moose::Instrument::OI_Common);



sub get_temperature {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Int', default => 1 }
    );
    $args{channel} = 'T' . $args{channel};

    return $self->get_temperature_channel(%args);
}


sub get_temperature_resistance {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Int', default => 1 }
    );
    $args{channel} = 'T' . $args{channel};

    return $self->get_temperature_channel_resistance(%args);
}


sub get_T {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->get_temperature( channel => 5, %args );
}


sub set_user {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/NORM GUEST/] ) },
    );
    return $self->oi_setter( cmd => "SET:SYS:USER", value => $value, %args );
}


sub enable_control {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_user( value => 'NORM', %args );
}

sub disable_control {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_user( value => 'GUEST', %args );
}


sub set_temp_pid {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) },
    );
    return $self->oi_setter(
        cmd   => "SET:DEV:T5:TEMP:LOOP:MODE",
        value => $value, %args
    );
}

sub enable_temp_pid {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_temp_pid( value => 'ON', %args );
}

sub disable_temp_pid {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->set_temp_pid( value => 'OFF', %args );
}


sub get_max_current {
    my ( $self, %args ) = validated_getter( \@_ );
    my $range
        = $self->oi_getter( cmd => "READ:DEV:T5:TEMP:LOOP:RANGE", %args );
    $range =~ s/mA$//;
    return $range / 1000;    # return Amps, not mA
}


sub set_max_current {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' },
    );
    if ( $value > 0.0101 ) {
        croak "current $value is too large";
    }
    $value *= 1000;    # in mA
    return $self->oi_setter(
        cmd   => "SET:DEV:T5:TEMP:LOOP:RANGE",
        value => $value, %args
    );
}

sub t_get {
    my ( $self, %args ) = validated_getter( \@_ );
    my $t = $self->oi_getter( cmd => "READ:DEV:T5:TEMP:LOOP:TSET", %args );
    $t =~ s/K$//;
    return $t;
}

# low-level method. Use safer set_T in high-level code.
sub t_set {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' }
    );
    return $self->oi_setter(
        cmd   => "SET:DEV:T5:TEMP:LOOP:TSET",
        value => $value, %args
    );
}


sub set_T {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    my $max_temperature = $self->max_temperature;
    if ( $value > $max_temperature ) {
        croak "setting temperatures above $max_temperature K is forbidden\n";
    }

    # Adjust heater setting.
    if ( $value < 0.035 ) {
        $self->set_max_current( value => 0.000316 );
    }
    elsif ( $value < 0.07 ) {
        $self->set_max_current( value => 0.001 );
    }
    elsif ( $value < 0.35 ) {
        $self->set_max_current( value => 0.00316 );
    }
    else {
        $self->set_max_current( value => 0.01 );
    }

    # Why call t_set twice?
    # Because of very weird bugs in the OI GHS control software.
    # If you don't do that you may end up with a setpoint different from
    # what you really want... :/
    $self->t_set( value => $value );
    $self->enable_temp_pid();
    return $self->t_set( value => $value );
}


sub get_P {
    my ( $self, %args ) = validated_getter( \@_ );
    my $power = $self->oi_getter( cmd => "READ:DEV:H1:HTR:SIG:POWR", %args );
    $power =~ s/uW$//;
    return $power;
}

sub set_P {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    return $self->oi_setter(
        cmd   => "SET:DEV:H1:HTR:SIG:POWR",
        value => $value, %args
    );
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::OI_Triton - Oxford Instruments Triton gas handling system control

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $oi_triton = instrument(
     type => 'OI_Triton',
     connection_type => 'Socket',
     connection_options => {host => 'triton'},
     max_temperature => 1.1, # Maximum temperature setpoint.
                             # Defaults to 0.7 K.
 );

 my $temp = $oi_triton->get_T();

=head1 METHODS

=head2 get_temperature

 $temp = $oi_triton->get_temperature(channel => 1);

=head2 get_temperature_resistance

 $resistance = $oi_triton->get_temperature_resistance(channel => 1);

=head2 get_T

equivalent to

 $oi_triton->get_temperature(channel => 5);

=head2 set_user

 $oi_triton->set_user(value => 'NORM');
 $oi_triton->set_user(value => 'GUEST');

=head2 enable_control/disable_control

 $oi_triton->enable_control();
 $oi_triton->disable_control();

Equivalent to 

 $oi_triton->set_user(value => 'NORM');
 $oi_triton->set_user(value => 'GUEST');

respectively.

=head2 set_temp_pid/enable_temp_pid/disable_temp_pid

 $oi_triton->set_temp_pid(value => 'ON');
 # or $oi_triton->enable_temp_pid();

Set PID control of the mixing chamber temperature to 'ON' or 'OFF'.

=head2 get_max_current

 $current_range = $oi_triton->get_max_current();

Return the mixing chamber heater current range (in Amperes).

=head2 set_max_current

 $oi_triton->set_max_current(value => 0.005);

Set the mixing chamber heater current range (in Amperes).

=head2 set_T

 $oi_triton->set_T(value => 0.1);

Program the GHS to regulate the temperature towards a specific value (in K).
The function returns immediately; this means that the target temperature most
likely has not been reached yet.

=head2 get_P/set_P

 my $power = $oi_triton->get_P();
 $oi_triton->set_P(value => $power);

Get/set the mixing chamber heater power (in micro Watts).

Obviously this only makes sense while we're not in loop control mode.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel, Simon Reinhardt
            2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
