package Lab::Instrument::IPSWeissDillFridge;
#ABSTRACT: Derived IPS instrument for the AG Weiss dilution refrigerator
$Lab::Instrument::IPSWeissDillFridge::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Instrument::IPS;
our @ISA = ('Lab::Instrument::IPS');

our %fields = (
    supported_connections => [
        'VISA', 'VISA_GPIB', 'GPIB', 'VISA_RS232', 'RS232', 'IsoBus', 'DEBUG'
    ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        baudrate     => 9600,
        databits     => 8,
        stopbits     => 2,
        parity       => 'none',
        handshake    => 'none',
        termchar     => "\r",
        timeout      => 2,

    },

    device_settings => { has_switchheater => 0 },

    device_cache => { id => "Weiss Dilution Fridge" }

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->{LIMITS} = {
        'magneticfield'          => 17,
        'field_intervall_limits' => [ 0, 10.99, 13.73, 16.48, 17 ],
        'rate_intervall_limits'  => [ 0.660, 0.552, 0.276, 0.138, 0.138 ]
    };

    $self->connection()->Clear();
    $self->check_magnet();

    #$self->_init_magnet();
    $self->_device_init();

    return $self;
}

sub check_magnet {
    my $self = shift;

    my $version = $self->get_version();
    if ( not( $version =~ /\b(IPS180)/ ) ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "This Instrument driver is supposed to be used ONLY with LS Weiss Dilution Cryostat !\n"
        );
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::IPSWeissDillFridge - Derived IPS instrument for the AG Weiss dilution refrigerator

=head1 VERSION

version 3.881

=head1 TO DO

Move this module to a separate distribution with files specific for the
Regensburg labs.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Christian Butschkow
            2013       Andreas K. Huettel, Christian Butschkow
            2017       Andreas K. Huettel, Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
