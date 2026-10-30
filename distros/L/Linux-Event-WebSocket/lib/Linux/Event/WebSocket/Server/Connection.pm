package Linux::Event::WebSocket::Server::Connection;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.003';

use parent 'Linux::Event::WebSocket::Connection';

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
