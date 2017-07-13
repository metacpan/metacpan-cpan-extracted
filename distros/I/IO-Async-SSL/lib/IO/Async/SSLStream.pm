#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package IO::Async::SSLStream;

use strict;
use warnings;
use base qw( IO::Async::Stream );
IO::Async::Stream->VERSION( '0.59' );

our $VERSION = '0.20';
$VERSION = eval $VERSION;

use IO::Async::SSL;

=head1 NAME

C<IO::Async::SSLStream> - read and write buffers around an SSL connection

=head1 DESCRIPTION

This subclass of L<IO::Async::Stream> provides support for using an SSL
connection, as created by L<IO::Async::SSL>'s C<SSL_connect> or C<SSL_listen>
extension methods. After one of these methods has provided a socket handle, it
should be wrapped in an L<IO::Async::SSLStream> object to provide the usual
C<on_read> callback.

It provides no extra methods and consumes no extra configuration parameters;
treat it the same as a regular C<IO::Async::Stream> object.

See the main L<IO::Async::SSL> documentation for an example of its use.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{reader} = \&IO::Async::SSL::sslread;
   $params->{writer} = \&IO::Async::SSL::sslwrite;

   $self->SUPER::_init( $params );
}

=head1 BUGS

=over 4

=item *

Currently, this subclass does not completely handle the C<autoflush> configure
option. It is possible for the C<SSL_write(3ssl)> call to fail with C<EAGAIN>
and C<SSL_WANT_READ>, indicating that it wishes to read (perhaps to obtain
fresh keys from the server). In this case, the subclass will not correctly
poll for readability and retry the write operation. This bug does not occur
with regular C<write> with C<autoflush> turned off.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
