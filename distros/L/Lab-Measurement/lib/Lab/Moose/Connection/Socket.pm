package Lab::Moose::Connection::Socket;
$Lab::Moose::Connection::Socket::VERSION = '3.682';
#ABSTRACT: Transfer IEEE 488.2 / SCPI messages over TCP

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Socket::INET;
use IO::Select;
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;

use namespace::autoclean;

has client => (
    is       => 'ro',
    isa      => 'IO::Socket::INET',
    writer   => '_client',
    init_arg => undef,
);

has select => (
    is       => 'ro',
    isa      => 'IO::Select',
    writer   => '_select',
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

has write_termchar => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => "\n",
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

    $client->setsockopt( IPPROTO_TCP, TCP_NODELAY, 1 )
        or croak "setsockopt: cannot enable TCP_NODELAY";

    my $select = IO::Select->new($client)
        or croak "cannot create IO::Select object: $!";

    $self->_client($client);
    $self->_select($select);
}

sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my $write_termchar = $self->write_termchar() // '';
    my $command        = $args{command} . $write_termchar;
    my $timeout        = $self->_timeout_arg(%args);

    my $client = $self->client();

    my $length  = length($command);
    my $written = 0;
    my $select  = $self->select();
    while ($length) {
        if ( !$select->can_write($timeout) ) {
            croak "timeout in Socket connection Write";
        }
        my $bytes_written = $client->syswrite( $command, $length, $written )
            or croak("Write: syswrite failed: $!");
        $written += $bytes_written;
        $length -= $bytes_written;
    }
}

sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        read_length_param(),
    );
    my $timeout     = $self->_timeout_arg(%args);
    my $read_length = $self->_read_length_arg(%args);
    my $client      = $self->client();
    my $select      = $self->select();

    my $string;
    my $length = 0;
    if ( $args{read_length} ) {

        # explicit read_length arg:
        # Keep reading until we have $read_length bytes.
        while ($read_length) {
            if ( !$select->can_read($timeout) ) {
                croak "timeout in connection Read";
            }
            my $read_bytes
                = $client->sysread( $string, $read_length, $length )
                or croak "socket read error: $!";
            $read_length -= $read_bytes;
            $length += $read_bytes;
        }
    }
    else {
        if ( !$select->can_read($timeout) ) {
            croak "timeout in connection Read";
        }
        $client->sysread( $string, $read_length )
            or croak "socket read error: $!";
    }

    return $string;
}

sub Clear {

    # Some instruments provide an additional control port.
}

with qw/
    Lab::Moose::Connection
    /;

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::Socket - Transfer IEEE 488.2 / SCPI messages over TCP

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'Socket',
     connection_options => {
         host => '132.199.11.2',
         port => 5025
     },
 );

=head1 DESCRIPTION

This connection uses L<IO::Socket::INET> to interface with the operating
system's TCP stack. This works on most operating systems without installing any
additional software.

Without knowing the syntax of the used command-messages there is no way for the
connection to determine when C<Read> is finished. This is unlike GPIB, USBTMC,
or VXI-11 which have explicit End of Message indicators. To deal with this, the
C<read_length> parameter has the following semantics:

=over

=item C<Read> is given an explicit C<read_length> parameter

Keep calling sysread until C<read_length> bytes are read.

=item C<Read> is not given an explicit C<read_length> parameter

Do a single sysread with the connections default C<read_length>.

=back

For SCPI definite length blocks you will have to give the exact block length
with the C<read_length> parameter.

=head2 CONNECTION OPTIONS

=over

=item host

Host address.

=item port

Host port.

=item write_termchar

Append this to each write command. Default: C<"\n">.

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
