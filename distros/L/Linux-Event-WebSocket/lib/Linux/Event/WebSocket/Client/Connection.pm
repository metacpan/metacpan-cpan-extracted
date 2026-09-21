package Linux::Event::WebSocket::Client::Connection;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'Linux::Event::WebSocket::Connection';

1;

__END__

=head1 NAME

Linux::Event::WebSocket::Client::Connection - established client WebSocket connection

=head1 DESCRIPTION

This class represents a client connection after the HTTP Upgrade has completed.
It uses ordinary single inheritance from
L<Linux::Event::WebSocket::Connection>, which in turn inherits
L<Linux::Event::IO::Sock::Stream>.

=cut
