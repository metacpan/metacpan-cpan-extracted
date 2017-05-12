#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package IO::Async::Loop::linux;

use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

C<IO::Async::Loop::linux> - pick the best Loop implementation on Linux

=head1 DESCRIPTION

If this module is installed, then the best Loop implementation will
automatically be picked when C<< IO::Async::Loop->new() >> is called on a
Linux machine. It will attempt to use either of the following, in order, if
they are available

=over 4

=item *

L<IO::Async::Loop::Epoll>

=item *

L<IO::Async::Loop::Ppoll>

=back

The end application using L<IO::Async> does not need to make any special
effort to use these; the magic constructor in L<IO::Async::Loop> will
automatically find and use it if it is installed.

 $ perl -MIO::Async::Loop -E 'say ref IO::Async::Loop->new'
 IO::Async::Loop::Epoll

=cut

sub new
{
   shift;
   eval { require IO::Async::Loop::Epoll } and return IO::Async::Loop::Epoll->new;
   eval { require IO::Async::Loop::Ppoll } and return IO::Async::Loop::Ppoll->new;
   die;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
