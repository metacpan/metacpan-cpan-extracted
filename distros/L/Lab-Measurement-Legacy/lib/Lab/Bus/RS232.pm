package Lab::Bus::RS232;
#ABSTRACT: RS232 or Virtual Comm port bus
$Lab::Bus::RS232::VERSION = '3.899';
use v5.20;

use strict;
use warnings;

use Lab::Bus;
use Data::Dumper;

use Scalar::Util qw(weaken);

our @ISA = ("Lab::Bus");

# load serial driver
use vars qw( $OS_win);

BEGIN {
    $OS_win = ( $^O eq "MSWin32" ) ? 1 : 0;

    if ($OS_win) {
        eval "use Win32::SerialPort";
        die "$@\n" if ($@);
    }
    else {
        eval "use Device::SerialPort";
        die "$@\n" if ($@);
    }
}    # End BEGIN

our $RS232_DEBUG = 0;
our $WIN32 = ( $^O eq "MSWin32" ) ? 1 : 0;

our %fields = (
    client      => undef,
    type        => 'RS232',
    port        => '/dev/ttyS0',
    baudrate    => 38400,
    parity      => 'none',
    databits    => 8,
    stopbits    => 1,
    handshake   => 'none',
    timeout     => 500,
    read_length => 'all',
    brutal      => 0,
    wait_query  => 10e-6,          #sec
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # parameter parsing
    $self->port( $self->config('port') ) if defined $self->config('port');
    warn(     "No port supplied to RS232 bus. Assuming default port "
            . $self->config('port')
            . "\n" )
        if ( !defined $self->config('port') );
    $self->baudrate( $self->config('baudrate') )
        if defined $self->config('baudrate');
    $self->parity( $self->config('parity') )
        if defined $self->config('parity');
    $self->databits( $self->config('databits') )
        if defined $self->config('databits');
    $self->stopbits( $self->config('stopbits') )
        if defined $self->config('stopbits');
    $self->handshake( $self->config('handshake') )
        if defined $self->config('handshake');
    $self->timeout( $self->config('timeout') )
        if defined $self->config('timeout');

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {    # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            warn "Existing Bus object of type "
                . $self->type()
                . " for port "
                . $self->port()
                . " found. Reusing.\n";
            return $twin;    # ...and that's it.
        }
        else {
            $Lab::Bus::BusList{ $self->type() }->{ $self->port() } = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{ $self->port() } );
        }
    }

    # clear new port
    if ($WIN32) {
        $self->client(
            new Win32::SerialPort( $self->config('port') )
                or warn "Could not open serial port\n"
        );
    }
    else {
        $self->client(
            new Device::SerialPort( $self->config('port') )
                or warn "Could not open serial port\n"
        );
    }

    # config port if needed

    if ( defined $self->client ) {
        $self->client()->purge_all;
        $self->client()->read_const_time( $self->timeout() );
        $self->client()->handshake( $self->config('handshake') )
            if ( defined $self->config('handshake') );
        $self->client()->baudrate( $self->config('baudrate') )
            if ( defined $self->config('baudrate') );
        $self->client()->parity( $self->config('parity') )
            if ( defined $self->config('parity') );
        $self->client()->databits( $self->config('databits') )
            if ( defined $self->config('databits') );
        $self->client()->stopbits( $self->config('stopbits') )
            if ( defined $self->config('stopbits') );
    }
    else {
        Lab::Exception::Error->throw(
            error => "Error initializing the serial interface\n" );
    }

    return $self;
}

#
# This will be short.
#
sub connection_new {
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    return { handle_type => 'RS232', valid => 1 };
}

sub connection_read
{        # @_ = ( $connection_handle, $args = { read_length, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    return $self->_direct_read($args);
}

sub _direct_read
{ # _direct_read()   this is for inheriting buses like MODBUS_RS232 for direct access # @_ = ( $connection_handle, $args = { read_length, brutal }
    use bytes;
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();

    my $result = "";
    my $buf    = "";
    my $raw    = "";

    if ( $read_length eq 'all' ) {
        do {
            $buf = $self->client()->read(4096);
            $result .= $buf;
        } while ( length($buf) == 4096 );
    }
    else {
        $result = $self->client()->read($read_length)
            ; # note: taken from older code - is 4096 some strong limit? If yes, this needs more work.
    }

    return $result;
}

sub connection_write
{             # @_ = ( $connection_handle, $args = { command, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }         # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    return $self->_direct_write($args);
}

sub _direct_write
{ # _direct_write( command => $cmd )   this is for inheriting buses like MODBUS_RS232 for direct access
    use bytes;
    my $self = shift;
    my $args = undef;
    if   ( ref $_[0] eq 'HASH' ) { $args = shift }
    else                         { $args = {@_} }

    my $command = $args->{'command'} || undef;
    my $brutal  = $args->{'brutal'}  || $self->brutal();

    my $status = undef;

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }
    else {
        $status = $self->client()->write($command);
    }

    if ( !$status && !$brutal ) {
        Lab::Exception::RS232Error->throw(
                  error => "Error in "
                . __PACKAGE__
                . "::connection_write() while executing $command: write failed.\n",
            status => $status,
        );
    }
    elsif ($brutal) {
        warn "(brutal=>Ignored) error in "
            . __PACKAGE__
            . "::connection_write() while executing $command: write failed.\n";
    }

    return 1;
}

sub connection_query
{ # @_ = ( $connection_handle, $args = { command, read_length, wait_query, brutal }
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
    my $result      = undef;

    $self->connection_write( $connection_handle, $args );

    usleep($wait_query)
        ;    #<---ensures that asked data presented from the device

    $result = $self->connection_read( $connection_handle, $args );
    return $result;
}

sub connection_clear {
    my $self              = shift;
    my $connection_handle = shift;

    $self->connection_read( $connection_handle, read_length => 'all' )
        ;    # clear buffer

    return 1;
}

#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
    my $self = shift;

    if ( !$self->ignore_twins() ) {
        for my $conn ( values %{ $Lab::Bus::BusList{ $self->type() } } ) {
            return $conn if $conn->port() == $self->port();
        }
    }
    return undef;
}

# BrutalRead and Clear not implemented

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::RS232 - RS232 or Virtual Comm port bus (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

 my $bus = Lab::Bus::RS232({
    port => '/dev/ttyACM0'
  });

Return blessed $self, with @_ accessible through $self->config().

C<port>: Device name to use (e.g. C<COM1> under Windows or C</dev/ttyUSB1> under Linux)

TODO: check this!!!

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

This is a bus for Lab::Measurement to communicate via RS232 or Virtual Comm port e.g. for
FTDI devices.

=head1 CONSTRUCTOR

=head2 new

All parameters are used as by C<Device::SerialPort>. port is needed in every case. 
An additional parameter C<reuse> is avaliable if two instruments use the same port. This 
is mainly implemented for USBprologix gateway. C<reuse> can be a SerialPort object or 
a C<Lab::Instrument...> package. Default value for timeout is 500ms and can be set by the 
parameter "timeout". Other options: handshake, baudrate, databits, stopbits and parity

=head1 METHODS

Used by C<Lab::Instrument>. Not for direct use!!!

=head2 Read

Reads data.

=head2 Write

Sent data to instrument

=head2 Handle

Give instrument object handle

=head1 CAVEATS/BUGS

Probably many. So far BrutalRead and Clear are not implemented because not needed for this interface.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=item L<Win32::SerialPort>

=item L<Device::SerialPort>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2010       Andreas K. Huettel
            2011-2012  Andreas K. Huettel, Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
