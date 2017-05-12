#!/usr/bin/perl -w

#
# GPIB Connection class for Lab::Bus::USBtmc
#

# TODO: Access to GPIB attributes, device clear, ...

package Lab::Connection::USBtmc;
our $VERSION = '3.542';

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

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::USBtmc - F</dev/usbtmc> connection

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

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
