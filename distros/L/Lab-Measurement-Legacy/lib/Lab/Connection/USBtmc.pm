package Lab::Connection::USBtmc;
#ABSTRACT: F</dev/usbtmc> Linux USB Test&Measurement kernel driver connection
$Lab::Connection::USBtmc::VERSION = '3.899';
use v5.20;

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection::GPIB;
use Lab::Exception;

our @ISA = ("Lab::Connection::GPIB");

our %fields = (
    bus_class   => 'Lab::Bus::USBtmc',
    wait_status => 0,                    # usec;
    wait_query  => 10e-6,                # sec;
    read_length => 1000,                 # bytes
    timeout     => 1,                    # seconds
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub Write {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $timeout = $options->{'timeout'} || $self->timeout();
    $self->bus()->timeout( $self->connection_handle(), $timeout );

    return $self->bus()
        ->connection_write( $self->connection_handle(), $options );
}

sub Read {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $timeout = $options->{'timeout'} || $self->timeout();
    $self->bus()->timeout( $self->connection_handle(), $timeout );

    return $self->bus()
        ->connection_read( $self->connection_handle(), $options );
}

sub Query {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $wait_query = $options->{'wait_query'} || $self->wait_query();
    my $timeout    = $options->{'timeout'}    || $self->timeout();
    $self->bus()->timeout( $self->connection_handle(), $timeout );

    $self->Write($options);
    usleep($wait_query);
    return $self->Read($options);
}

sub Clear {
    my $self    = shift;
    my $options = undef;
    return $self->bus()
        ->connection_device_clear( $self->connection_handle() );
}

#
# Query from Lab::Connection is sufficient
# EnableTermChar, SetTermChar from Lab::Connection::GPIB are sufficient.
#


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::USBtmc - F</dev/usbtmc> Linux USB Test&Measurement kernel driver connection (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

This is not called directly. To make a GPIB suppporting instrument use
Lab::Connection::USBtmc, set the connection_type parameter accordingly:

 $instrument = U2000->new(
    connection_type => 'USBtmc',
    usb_vendor => 0x3838,
    usb_product => 0x1234,
 )

Ways to indicate device:

 tmc_address => number   (for /dev/usbtmcN)
 visa_name => 'USB::0x1234::0x5678::serial:INSTR';
 usb_vendor => 0x1234,  usb_product => 0x5678

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

Lab::Connection::USBtmc provides a GPIB-type connection with the bus
L<Lab::Bus::USBtmc>, using F</dev/usbtmc*> as backend.

It inherits from L<Lab::Connection::GPIB> and subsequently from
L<Lab::Connection>. 

For L<Lab::Bus::USBtmc>, the generic methods of L<Lab::Connection> suffice, so
only a few defaults are set:

 wait_status=>0, # usec;
 wait_query=>10, # usec;
 read_length=>1000, # bytes

=head1 CONSTRUCTOR

=head2 new

 my $connection = Lab::Connection::USBtmc->new(
    usb_vendor => 0x1234,   # vendor id
    usb_product => 0x5678,  # product id
 }

=head1 METHODS

Mostly, this just falls back on the methods inherited from L<Lab::Connection>.

=head2 config

Provides unified access to the attributes of all the child
classes. E.g.

 $USB_product = $instrument->config('usb_product');

Without arguments, returns a reference to the complete C<< $self->config >>
created by the constructor. 

 $config = $connection->config();
 $USB_product = $connection->config()->{'usb_product'};

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::GPIB>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich, Hermann Kraus
            2016       Charles Lane, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
