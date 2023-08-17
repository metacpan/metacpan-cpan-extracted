package Lab::Connection::LinuxGPIB;
#ABSTRACT: LinuxGPIB connection
$Lab::Connection::LinuxGPIB::VERSION = '3.881';
use v5.20;

#
# GPIB Connection class for Lab::Bus::LinuxGPIB
#
#
# TODO: Access to GPIB attributes, device clear, ...
#

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection::GPIB;
use Lab::Exception;

eval { require LinuxGpib; LinuxGpib->import(); };
die("Failed to load LinuxGpib in Lab::Connection::LinuxGPIB!\n$@") if ($@);

our @ISA = ("Lab::Connection::GPIB");

our %fields = (
    bus_class   => 'Lab::Bus::LinuxGPIB',
    wait_status => 0,                       # usec;
    wait_query  => 10e-6,                   # sec;
    read_length => 1000,                    # bytes
    timeout     => 1,                       # seconds
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

#
# Query from Lab::Connection is sufficient
# EnableTermChar, SetTermChar from Lab::Connection::GPIB are sufficient.
#


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::LinuxGPIB - LinuxGPIB connection

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This is not called directly. To make a GPIB suppporting instrument use Lab::Connection::LinuxGPIB, set
the connection_type parameter accordingly:

$instrument = new HP34401A(
   connection_type => 'LinuxGPIB',
   gpib_board => 0,
   gpib_address => 14
)

=head1 DESCRIPTION

C<Lab::Connection::LinuxGPIB> provides a GPIB-type connection with the bus L<Lab::Bus::LinuxGPIB>,
using L<Linux GPIB (aka libgpib0 in debian)|http://linux-gpib.sourceforge.net/> as backend.

It inherits from L<Lab::Connection::GPIB> and subsequently from L<Lab::Connection>.

For L<Lab::Bus::LinuxGPIB>, the generic methods of L<Lab::Connection> suffice, so only a few defaults are set:
  wait_status=>0, # usec;
  wait_query=>10, # usec;
  read_length=>1000, # bytes

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::LinuxGPIB(
    gpib_board => 0,
    gpib_address => $address,
    gpib_saddress => $secondary_address
 }

=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_Address=$instrument->Config(gpib_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_Address = $connection->Config()->{'gpib_address'};

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
            2012       Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
