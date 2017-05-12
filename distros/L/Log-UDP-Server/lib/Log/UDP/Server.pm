use strict;
use warnings;
use 5.006; # Found with Perl::MinimumVersion

package Log::UDP::Server;
BEGIN {
  $Log::UDP::Server::VERSION = '0.40.0';
}
use MooseX::POE;
with 'Data::Serializable' => { -version => '0.40.0' };

# ABSTRACT: A simple way to receive and handle structured messages via UDP

use IO::Socket::INET ();
use Readonly;


Readonly::Scalar our $DATAGRAM_MAXLEN => 8192;


has 'handler' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);


has 'server_address' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '127.0.0.1'; },
);


has 'server_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 9999; },
);


has 'server_socket' => (
    is  => 'rw',
    isa => 'IO::Socket::INET',
    lazy => 1,
    builder => '_build_server_socket',
);

sub _build_server_socket { ## no critic qw(Subroutines::ProhibitUnusedPrivateSubroutines)
    my ($self) = @_;

    # Create socket
    my $socket = IO::Socket::INET->new(
        Proto     => 'udp',
        LocalPort => $self->server_port,
        LocalAddr => $self->server_address,
    );

    # Croak on error
    unless ( $socket ) {
        die("Unable to bind to " . $self->server_address . ":" . $self->server_port . ": $!\n");
    }

    return $socket;
}


sub run {
    POE::Kernel->run();
    return 1; # OK
}


sub START {
    my ($self) = @_;
    POE::Kernel->select_read( $self->server_socket, "get_datagram" );
    return 1; # OK
}


event get_datagram => sub {
    my ($self) = @_;

    my $remote_address = recv( $self->server_socket, my $message = "", $DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

    my ( $peer_port, $peer_addr ) = IO::Socket::INET::unpack_sockaddr_in($remote_address);
    my $human_addr = IO::Socket::INET::inet_ntoa($peer_addr);

    # Deserialize and call handler
    $self->handler->(
        $self->deserialize($message)
    );
};

1;



=pod

=encoding utf-8

=head1 NAME

Log::UDP::Server - A simple way to receive and handle structured messages via UDP

=head1 VERSION

version 0.40.0

=head1 SYNOPSIS

    use Log::UDP::Server;

    my $server = Log::UDP::Server->new( handler => sub { warn( $_[0] ); } );
    $server->run();

=head1 DESCRIPTION

This module enables you to receive a message (simple string or complicated object)
over a UDP socket. An easy way to send a structured message is to use Log::UDP::Client.
The message received will automatically be handled by the specified callback.

=head1 ATTRIBUTES

=head2 handler : CodeRef

The handler that is used to process each message as it is received.

=head2 server_address : Str

The address you want to listen on.

=head2 server_port : Int

The port you want to listen on.

=head2 server_socket : IO::Socket::INET

The listening socket used for communication.

=head1 METHODS

=head2 run

Starts the server and listens for incoming datagrams on the specified socket.

=head2 START

Initializes the C<get_datagram> event on C<server_socket>.

=head1 EVENTS

=head2 get_datagram

Will execute the coderef in C<handler> with the deserialized message as the
first argument.

=head1 CONSTANTS

=head2 $DATAGRAM_MAXLEN : Int

Maximum UDP packet size. Set to 8192 bytes.

=head1 INHERITED METHODS

=over 4

=item *

deserialize

=item *

deserializer

=item *

serialize

=item *

serializer

=item *

serializer_module

=item *

throws_exception

=back

All of these methods are inherited from L<Data::Serializable>. Read more about them there.

=for :stopwords CPAN AnnoCPAN RT CPANTS Kwalitee diff

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Log::UDP::Server

=head2 Websites

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Log-UDP-Server>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-UDP-Server>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/Log-UDP-Server>

=item *

CPAN Forum

L<http://cpanforum.com/dist/Log-UDP-Server>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-UDP-Server>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Log-UDP-Server>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/L/Log-UDP-Server.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Log-UDP-Server>

=item *

Source Code Repository

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<git://github.com/robinsmidsrod/Log-UDP-Server.git>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-log-udp-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-UDP-Server>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

