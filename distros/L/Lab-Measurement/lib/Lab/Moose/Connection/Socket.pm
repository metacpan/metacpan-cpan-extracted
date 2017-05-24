package Lab::Moose::Connection::Socket;

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Socket::INET;
use IO::Socket::Timeout;
use Carp;

use Lab::Moose::Instrument qw/timeout_param/;

use namespace::autoclean;

our $VERSION = '3.543';

has client => (
    is       => 'ro',
    isa      => 'IO::Socket::INET',
    writer   => '_client',
    init_arg => undef,
);

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

sub BUILD {
    my $self    = shift;
    my $host    = $self->host();
    my $port    = $self->port();
    my $timeout = $self->timeout();
    my $client  = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $timeout,
    ) or croak "cannot open connection with $host on port $port: $!";

    IO::Socket::Timeout->enable_timeouts_on($client);
    $client->read_timeout($timeout);
    $client->write_timeout($timeout);

    $client->setsockopt( IPPROTO_TCP, TCP_NODELAY, 1 )
        or die "setsockopt: cannot enable TCP_NODELAY";
    $self->_client($client);
}

sub Write {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my $command = $arg{command} . "\n";
    my $timeout = $self->_timeout_arg(%arg);

    my $client = $self->client();
    $client->write_timeout($timeout);

    print {$client} $command
        or croak "socket write error: $!";
}

sub Read {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param(),
    );
    my $timeout = $self->_timeout_arg(%arg);
    my $client  = $self->client();

    $client->read_timeout($timeout);

    my $line = <$client>;
    if ( !defined $line ) {
        croak "socket read error: $!";
    }

    if ( $line =~ /^#([1-9])/ ) {

        # DEFINITE LENGTH ARBITRARY BLOCK RESPONSE DATA
        # See IEEE 488.2, Sec. 8.7.9
        my $num_digits = $1;
        my $num_bytes = substr( $line, 2, $num_digits );

        # We do require a trailing newline
        my $needed = 2 + $num_digits + $num_bytes - length($line) + 1;

        if ( $needed == 0 ) {
            return $line;
        }

        if ( $needed < 0 ) {
            croak "negative read length";
        }
        my $string;
        my $read_bytes = read( $client, $string, $needed );
        if ( !$read_bytes ) {
            croak "socket read error: $!";
        }

        if ( $read_bytes != $needed ) {
            croak "tcp read returned too few bytes:\n"
                . "expected: $needed, got: $read_bytes";
        }
        return $line . $string;
    }
    else {
        return $line;
    }
}

sub Query {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );
    my %write_arg = %arg;
    $self->Write(%write_arg);
    delete $arg{command};
    return $self->Read(%arg);
}

sub Clear {

}

with qw/
    Lab::Moose::Connection
    /;

__PACKAGE__->meta->make_immutable();

1;

=head1 NAME

Lab::Moose::Connection::Socket - Transfer IEEE 488.2 / SCPI messages over TCP
socket.

=head1 SYNOPSIS

 use Lab::Moose;

 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'Socket',
     connection_options => {host => '132.199.11.2', port => 5025},
 );

=head1 DESCRIPTION

This connection uses L<IO::Socket::INET> to interface with the operating
system's TCP stack. This works on most operating systems without installing any
additional software (like NI-VISA).

It supports both newline terminated messages of arbitrary length and definite
length block data, which is needed to transfer binary data from e.g. spectrum
analyzers, oscilloscopes and VNAs (IEEE 488.2 Sec. 8.7.9).

=cut

