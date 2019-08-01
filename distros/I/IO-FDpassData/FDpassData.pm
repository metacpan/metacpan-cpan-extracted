#!/usr/bin/perl
package IO::FDpassData;
#
use strict;
#use diagnostics;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;

$VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT = qw(
	fd_sendata
	fd_recvdata
);

require DynaLoader;
@ISA = qw(Exporter DynaLoader);
bootstrap IO::FDpassData $VERSION;

sub DESTROY {};

=head1 NAME

IO::FDpassData - send/receive data and/or file descriptor

=head1 SYNOPSIS

  use IO::FDpassData;

  $bytessent = fd_sendata(socket, message, FD);

  ($bytesrcvd, message, FD) = fd_rcvdata(socket, $maxsize);

=head1 DESCRIPTION

This module will send and receive data and/or a file descriptor locally over a unix pipe.

=over 2

=item * $bytessent = fd_sendata(socket, message, FD);

  input:	socket file descriptor,
    {optional}	message,		may be zero length string
    {optional}	file descriptor		to send to other process

 NOTE: optional message may be 'undef' or zero length string
       optional FD may be omitted, 'undef'

  returns:	bytes sent
	    or -1 on error

=item * ($bytesrcvd, message, FD) = fd_rcvdata(socket, $maxsize);

  input:	socket file descriptor,
		maximum length to receive	overrun will cause segfault??

  returns:	msg bytes received,		or -1 on error
		message,		may be zero a length string
    {optional}	file descriptor or undef

=back

=head1 EXPORTS

  fd_sendata
  fd_recvdata

=head1 COPYRIGHT

Copyright Michael Robinton 2019

=head1 CREDITS

This package was inspired by an article published by Keith Packard https://keithp.com/blogs/fd-passing/
and the package IO::FDpass written by Marc A. Lehmann

=head1 SHORTCOMINGS

At the present time this package does not support Windows. Patches welcome.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version, or

b) the "Artistic License". 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

=cut

1;
