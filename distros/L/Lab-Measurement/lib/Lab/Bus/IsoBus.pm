package Lab::Bus::IsoBus;
#ABSTRACT: Oxford Instruments ISOBUS bus
$Lab::Bus::IsoBus::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Connection;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Bus");

our %fields = (
    type              => 'IsoBus',
    base_connection   => undef,
    IsoEnableTermChar => 1,
    IsoTermChar       => "\r",
    brutal            => 0,          # brutal as default?
    wait_status       => 10e-6,      # sec;
    wait_query        => 10e-6,      # sec;
    query_length      => 300,        # bytes
    query_long_length => 10240,      #bytes
    read_length       => 1000,       # bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {        # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            # TODO implement twin detection
            $Lab::Bus::BusList{ $self->type() }->{'default'} = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{'default'} );
        }
    }

    # set the connection $self->base_connection to the parameters required by IsoBus
    $self->base_connection( $self->config('base_connection') )
        if defined $self->config('base_connection');
    $self->IsoEnableTermChar( $self->config('IsoEnableTermChar') )
        if defined $self->config('IsoEnableTermChar');
    $self->IsoTermChar( $self->config('IsoTermChar') )
        if defined $self->config('IsoTermChar');

    # clear the connection if possible

    # we need to set the following RS232 options: 9600baud, 8 data bits, 1 stop bit, no parity, no flow control
    # what is the read terminator? we assume CR=13 here, but this is not set in stone
    # write terminator should I think always be CR=13=0x0d

    return $self;
}

sub connection_new {    # @_ = ({ isobus_address => $isobus_address })
    my $self              = shift;
    my $args              = undef;
    my $status            = undef;
    my $connection_handle = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }                   # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $isobus_address = $args->{'isobus_address'};

    # check that this is a number and in the valid range

    # we dont actually have to open anything here

    # we abuse the isobus_address as connection handle
    return $isobus_address;
}

sub connection_read
{    # @_ = ( $connection_handle, $args = { read_length, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $result      = undef;

    $result = $self->config('base_connection')->Read(
        {
            brutal      => $brutal,
            read_length => $read_length,
        }
    );

    return $result;
}

sub connection_write
{    # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command = $args->{'command'} || undef;

    my $write_cnt = 0;

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }
    else {
        if ( $self->config("IsoEnableTermChar") ) {
            $write_cnt = $self->base_connection->Write(
                {
                    # build the format for an IsoBus command
                    command => sprintf(
                        "@%d%s%s",
                        $connection_handle, $command, $self->IsoTermChar()
                    ),
                }
            );

        }
        else {
            $write_cnt = $self->base_connection->Write(
                {
                    # build the format for an IsoBus command
                    command =>
                        sprintf( "@%d%s", $connection_handle, $command )
                }
            );
        }
        return $write_cnt;
    }
}

sub connection_query
{ # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command     = $args->{'command'}     || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $wait_status = $args->{'wait_status'} || $self->wait_status();
    my $wait_query  = $args->{'wait_query'}  || $self->wait_query();

    my $result    = undef;
    my $status    = undef;
    my $write_cnt = 0;
    my $read_cnt  = undef;

    $write_cnt = $self->connection_write($args);

    usleep($wait_query)
        ;    #<---ensures that asked data presented from the device

    $result = $self->connection_read($args);
    return $result;
}

sub connection_clear {
    my $self = shift;

    $self->config('base_connection')->Clear();

}

#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
    my $self = shift;

    # Only one VISA bus for the moment, stored as "default"
    if ( !$self->ignore_twins() ) {

        #		if(defined $Lab::Bus::BusList{$self->type()}->{'default'}) {
        #			return $Lab::Bus::BusList{$self->type()}->{'default'};
        #		}
    }

    return undef;
}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::IsoBus - Oxford Instruments ISOBUS bus

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This is the IsoBus bus class. Typically you create it implicit through instrument creation:

  my $instrument = new Lab::Instrument::IPS({
    BusType => 'IsoBus',
	base_connection => new Lab::Bus::VISA_GPIB({ gpib_board => 0, gpib_address => 24}),
	isobus_addres => 2,
  }

=head1 METHODS

=head2 connection_new

  $isobus->connection_new({ resource_name => $isobus_address });

Creates a new instrument handle for this bus.

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $isobus->connection_new({ resource_name => $isobus_address });
  $result = $isobus->connection_read($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.

=head2 connection_write

  $isobus->connection_write( $InstrumentHandle, { command => $command, wait_status => $wait_status } );

Puts in front of the $command-string the isobus_adress, e.g. "@1$command". Passes the modified argument hash to the base_connection.
For further information refer to the specific connection class of $base_connection.

=head2 connection_read

  $isobus->connection_read( $InstrumentHandle, { command => $command, read_length => $read_length, timeout => $seconds,  brutal => 0/1 } );

Puts in front of the $command-string the isobus_adress, e.g. "@1$command". Passes the modified argument hash to the base_connection.
For further information refer to the specific connection class of $base_connection.

=head2 connection_clear

  $isobus->connection_clear( $InstrumentHandle );

Clears the specified connection $InstrumentHandle.

=head2 connection_query

  $isobus->connection_query( $InstrumentHandle, { command => $command, read_length => $read_length, wait_status => $wait_status, wait_query => $wait_query, brutal => 0/1 } );

Puts in front of the $command-string the isobus_adress, e.g. "@1$command". Passes the modified argument hash to the base_connection.
For further information refer to the specific connection class of $base_connection.

=head1 SEE ALSO

=over 4

=item * L<Lab::Bus>

=item * L<Lab::Connection>

=item * and many more...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, David Kalok, Florian Olbrich, Stefan Geissler
            2013       Stefan Geissler
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel
            2021       Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
