#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package IO::Async::OS::linux;

use strict;
use warnings;

our $VERSION = '0.77';

our @ISA = qw( IO::Async::OS::_Base );

=head1 NAME

C<IO::Async::OS::linux> - operating system abstractions on C<Linux> for L<IO::Async>

=head1 DESCRIPTION

This module contains OS support code for C<Linux>.

See instead L<IO::Async::OS>.

=cut

# Suggest either Epoll or Ppoll loops first if they are installed
use constant LOOP_PREFER_CLASSES => qw( Epoll Ppoll );

# Try to use /proc/pid/fd to get the list of actually-open file descriptors
# for our process. Saves a bit of time when running with high ulimit -n /
# fileno counts.
sub potentially_open_fds
{
   my $class = shift;

   opendir my $fd_path, "/proc/$$/fd" or do {
      warn "Cannot open /proc/$$/fd, falling back to generic method - $!";
      return $class->SUPER::potentially_open_fds
   };

   # Skip ., .., our directory handle itself and any other cruft
   # except fileno() isn't available for the handle so we'll
   # end up with that in the output anyway. As long as we're
   # called just before the relevant close() loop, this
   # should be harmless enough.
   my @fd = map { m/^([0-9]+)$/ ? $1 : () } readdir $fd_path;
   closedir $fd_path;

   return @fd;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
