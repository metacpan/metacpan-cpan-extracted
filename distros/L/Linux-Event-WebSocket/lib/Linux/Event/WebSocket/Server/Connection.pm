package Linux::Event::WebSocket::Server::Connection;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'Linux::Event::WebSocket::Connection';

# Linux::Event::HTTP keeps its constructor-installed transport-close wrapper
# across transition_to(). That wrapper performs one final HTTP state cleanup
# before forwarding to the WebSocket close lifecycle, so preserve its private
# cleanup entry point on the transitioned object without duplicating HTTP state
# knowledge here.
sub _clear_transaction ($self) {
    require Linux::Event::HTTP::Server::Connection;
    Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
    return;
}

1;

__END__

=head1 NAME

Linux::Event::WebSocket::Server::Connection - established server WebSocket connection

=head1 DESCRIPTION

This class represents an accepted WebSocket connection after the HTTP Upgrade
has completed. It uses ordinary single inheritance from
L<Linux::Event::WebSocket::Connection>, which in turn inherits
L<Linux::Event::IO::Sock::Stream>.

Applications normally receive instances through
L<Linux::Event::WebSocket::Server>.

=cut
