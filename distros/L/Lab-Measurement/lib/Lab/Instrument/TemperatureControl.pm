package Lab::Instrument::TemperatureControl;
#ABSTRACT: Generic temperature control instrument base class
$Lab::Instrument::TemperatureControl::VERSION = '3.881';
use v5.20;

use strict;

our @ISA = ('Lab::Instrument');

our %fields = (
    supported_connections => [],

    # supported config options
    device_settings => {
        has_pidcontroller => undef,
        num_heaters       => 0,
        num_sensors       => 0,
        sample_sensor     => undef,
        sample_heater     => undef,
    },

    # Config hash passed to subchannel objects or $self->configure()
    default_device_settings => {},
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    print
        "Temperature control support is experimental. You have been warned.\n";
    return $self;
}

sub set_sample_sensor() {
    my $self    = shift;
    my $channel = shift;

    # setze sample sensor if this is a valid channel number
}

sub get_temperature() {
    my $self    = shift;
    my $channel = shift;

    # no channel -> use default channel
    # use method from hardware
    return $self->_get_temperature($channel);
}

sub get_sample_temperature() {
    my $self = shift;
    return $self->get_temperature( $self->get_sample_sensor );
}

sub _get_temperature() {
    die "get_temperature not implemented for this instrument\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TemperatureControl - Generic temperature control instrument base class

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2009       Andreas K. Huettel
            2010       Andreas K. Huettel, Daniel Schroeer
            2011       Andreas K. Huettel, Florian Olbrich
            2012       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
