package Lab::Bus::Socket;
#ABSTRACT: IP network socket bus
$Lab::Bus::Socket::VERSION = '3.899';
use v5.20;

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;
use IO::Socket;
use IO::Select;

our @ISA = ("Lab::Bus");

our %fields = (
    type              => 'Socket',
    remote_addr       => 'localhost',    # Client for Write
    remote_port       => '6342',
    open_server       => 0,
    local_addr        => 'localhost',    # Server for Read
    local_port        => '6342',
    proto             => 'tcp',
    listen_queue      => 1,
    reuse             => 1,
    timeout           => 60,
    closechar         => "\004",         # EOT
    brutal            => 0,              # brutal as default?
    wait_query        => 10e-6,          # sec;
    read_length       => 1000,           # bytes
    query_length      => 300,            # bytes
    query_long_length => 10240,          #bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # parameter parsing

    $self->remote_addr( $self->config('remote_addr') )
        if defined $self->config('remote_addr');
    $self->remote_port( $self->config('remote_port') )
        if defined $self->config('remote_port');
    $self->open_server( $self->config('open_server') )
        if defined $self->config('open_server');
    $self->local_addr( $self->config('local_addr') )
        if defined $self->config('local_addr');
    $self->local_port( $self->config('local_port') )
        if defined $self->config('local_port');
    $self->Proto( $self->config('Proto') ) if defined $self->config('Proto');
    $self->Timeout( $self->config('Timeout') )
        if defined $self->config('Timeout');
    $self->EnableTermChar( $self->config('EnableTermChar') )
        if defined $self->config('EnableTermChar');
    $self->TermChar( $self->config('TermChar') )
        if defined $self->config('TermChar');

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {    # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            $Lab::Bus::BusList{ $self->type() }->{'default'} = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{'default'} );
        }
    }

    return $self;
}

sub connection_new {         # { gpib_address => primary address }
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }
    my $server = undef;
    my $client = undef;
    if ( $args->{'open_server'} ) {
        die "server sockets not yet supported\n";
        $server = new IO::Socket::INET(
            LocalHost => $args->{'local_addr'},
            LocalPort => $args->{'local_port'},
            Proto     => $args->{'proto'},
            Listen    => $args->{'listen_queue'},
            Reuse     => $args->{'reuse'},
        );
        die "Could not create socket server: $!\n" unless $server;
    }
    $client = new IO::Socket::INET(
        PeerAddr => $args->{'remote_addr'},
        PeerPort => $args->{'remote_port'},
        Proto    => $args->{'proto'},
    );
    die "Could not create socket client: $!\n" unless $client;
    $client->autoflush(1);
    my $connection_handle = undef;
    $connection_handle = {
        valid                => 1,
        type                 => "SOCKET",
        socket_client_handle => $client,
        socket_server_handle => $server
    };    #,
    return $connection_handle;
}

sub connection_write
{         # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }     # try to be flexible about options as hash/hashref
    else { $args = {@_} }
    my $command     = $args->{'command'}     || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }
    else {
        if ( $self->{'EnableTermChar'} ) { $command .= $self->{'TermChar'} }
        my $sock = $connection_handle->{'socket_client_handle'};

        my @ready = IO::Select->new($sock)->can_write( $self->{'Timeout'} );
        if (@ready) {
            $sock->send($command) or die "$! sending command";
        }
        else {
            Lab::Exception::Timeout->throw(
                error => "Socket write time out\n",
            );
        }
    }
    return 1;
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

    my $sock = $connection_handle->{'socket_client_handle'} || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();

    my $raw    = "";
    my $result = undef;

    if ( !defined $sock ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No Socket given to "
                . __PACKAGE__
                . "::connection_read().\n", );
    }
    else {
        my @ready = IO::Select->new($sock)->can_read( $self->{'Timeout'} );
        if (@ready) {
            $sock->recv( $result, $read_length );
        }
        else {
            Lab::Exception::Timeout->throw(
                error => "Socket read time out\n",
            );
        }
    }

    $raw = $result;
    $result =~ s/[\n\r\x00]*$//;
    return $result;
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
    my $wait_query  = $args->{'wait_query'}  || $self->wait_query();
    my $result      = undef;

    $self->connection_write($args);

    sleep($wait_query); #<---ensures that asked data presented from the device

    $result = $self->connection_read($args);
    return $result;
}

sub serial_poll {
    my $self              = shift;
    my $connection_handle = shift;
    return undef;
}

sub connection_clear {
    my $self              = shift;
    my $connection_handle = shift;
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Bus::Socket - IP network socket bus (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       David Kalok
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
