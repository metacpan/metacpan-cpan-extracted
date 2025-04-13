package Lab::Moose::Instrument::Lakeshore340::Helium3;
$Lab::Moose::Instrument::Lakeshore340::Helium3::VERSION = '3.930';
#ABSTRACT: Lakeshore Model 340 Temperature Controller for Helium3 operation

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time sleep/;

#use POSIX qw/log10 ceil floor/;

extends 'Lab::Moose::Instrument::Lakeshore340';

sub BUILD {
    my $self = shift;

    # enable analog output 2
    $self->set_analog_out(
        output => 2,
        mode   => 3,    # loop,
    );
    $self->set_control_parameters(
        loop  => 2,
        input => $self->sample_channel(),
        units => 1,
        state => 1,
    );
    $self->set_setpoint( loop => 2, value => 0 );
}

# the set_T/get_T functions use these channels

has sample_channel =>
    ( is => 'ro', isa => enum( [qw/A B C D/] ), default => 'A' );

has sorb_channel =>
    ( is => 'ro', isa => enum( [qw/A B C D/] ), default => 'C' );

has one_K_channel =>
    ( is => 'ro', isa => enum( [qw/A B C D/] ), default => 'D' );

# use He3-pot heater if T > T_switch
has T_switch => ( is => 'ro', isa => 'Num', default => 1.5 );


sub condensate {
    my ( $self, %args ) = validated_getter(
        \@_,
        T_sorb => { isa => 'Lab::Moose::PosNum', default => 35 },
        wait   => { isa => 'Lab::Moose::PosNum', default => 1800 },
        T_cool => { isa => 'Lab::Moose::PosNum', default => 0.4 },
    );
    my ( $sorb_temp, $wait, $T_cool ) = delete @args{qw/T_sorb wait/};

    $self->set_setpoint( loop => 1, value => $sorb_temp );

    my $t_start = time();

    # enable autoflush
    my $autoflush = STDOUT->autoflush();

    while ( time() - $t_start < $wait ) {
        my $t_sorb = $self->get_T( channel => $self->sorb_channel,  %args );
        my $t_1k   = $self->get_T( channel => $self->one_K_channel, %args );
        my $t_sample
            = $self->get_T( channel => $self->sample_channel, %args );
        printf(
            "T_sorb = %.1f, T_1K = %.1f, T_sample = %.1f     \r",
            $t_sorb, $t_1k, $t_sample
        );
        sleep 5;

    }
    print " " x 70 . "\r";

    # heater off
    $self->set_heater_range( value => 0 );

    # wait until sample is cold again
    while (1) {
        my $t_sorb = $self->get_T( channel => $self->sorb_channel,  %args );
        my $t_1k   = $self->get_T( channel => $self->one_K_channel, %args );
        my $t_sample
            = $self->get_T( channel => $self->sample_channel, %args );

        printf(
            "T_sorb = %.1f, T_1K = %.1f, T_sample = %.1f     \r",
            $t_sorb, $t_1k, $t_sample
        );

        if ( $t_sample < $T_cool ) {
            last;
        }

        sleep 5;

    }

    print " " x 70 . "\r";

    # reset autoflush to previous value
    STDOUT->autoflush($autoflush);

}


sub set_T {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
    );

    if ( $value < $self->T_switch ) {

        # use Sorb heater (loop 1). Turn down loop 2 output.
        $self->set_setpoint( loop => 1, value => $value );
        $self->set_setpoint( loop => 2, value => 0 );
    }
    else {
        # set Sorb on 15K and use loop 2
        $self->set_setpoint( loop => 1, value => 15 );
        $self->set_setpoint( loop => 2, value => $value );
    }
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Lakeshore340::Helium3 - Lakeshore Model 340 Temperature Controller for Helium3 operation

=head1 VERSION

version 3.930

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $helium3 = instrument(
     type => 'Lakeshore340::Helium3',
     connection_type => 'LinuxGPIB',
     connection_options => {pad => 22},
     
 );

default thermometers:
sample => 'A'
sample_high => 'B' (optional)
sorb => 'C'
1K-pot => 'D'

Can be configured with attributes C<sample_channel>, C<sorb_channel>, C<one_K_channel>. 

default heater config:
loop 1 (dual Banana jack) => sorb heater
loop 2 (Analog output 2, BNC) => he3-pot heater

(Analog out 1 can be used for IVC-sorb)

The attribute C<T_switch> (default: 1.5) determines the used control loop for a given temperature setpoint:

- T < C<T_switch>: use sorb heater, ramp sample heater to zero
- T > C<T_switch>: use 3He-pot heater, set sorb to 15K

=head1 METHODS

Supports all methods from L<Lab::Moose::Instrument::Lakeshore340>.

=head2 condensate

 $lakeshore->condensate(
     T_sorb => 35, # default: 35 K
     wait => 1800, # default: 30 min
     T_cool => 0.4, # default: 0.4 K
 );

Heat sorb to 35K for 30min. Then turn off sorb heater and wait until sample temperature is below 400mK.

=head2 set_T

 $helium3->set_T(value => 0.345);

Behaviour depends on the attribute value C<T_switch> (see L</Synopsis>).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by the Lab::Measurement team; in detail:

  Copyright 2022       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
