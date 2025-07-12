#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2024 -- leonerd@leonerd.org.uk

package Future::XS 0.14;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

use Time::HiRes qw( tv_interval );

# Future::_base is provided in Future.pm itself
require Future;
our @ISA = qw( Future::_base );

our @CARP_NOT = qw( Future Future::_base );

require Future::Exception;

=head1 NAME

C<Future::XS> - experimental XS implementation of C<Future>

=head1 SYNOPSIS

=for highlighter language=perl

   my $future = Future::XS->new;

   perform_some_operation(
      on_complete => sub {
         $future->done( @_ );
      }
   );

   $future->on_ready( sub {
      say "The operation is complete";
   } );

=head1 DESCRIPTION

This module provides an XS-based implementation of the L<Future> class. It is
currently experimental and shipped in its own distribution for testing
purposes, though once it seems stable the plan is to move it into the main
C<Future> distribution and load it automatically in favour of the pureperl
implementation on supported systems.

=head2 Future::XS and threads

In a program not involving multiple threads, this module behaves entirely as
expected, following the behaviour of the regular pure-perl C<Future>
implementation (regardless of whether or not the perl interpreter is actually
built to support threads).

When multiple threads are created, previous versions of this module would most
likely crash. The current version (0.10) fixes enough of the logic, that
future instances that are only ever accessed from one thread (either the
initial main thread, or any additional sidecar threads) will work fine.
However, future instances cannot currently cross the boundary between threads.
Any instances that were created before a new thread is made will no longer be
accessible within that thread, and instances may not be returned as the result
of the thread exit value. Some of these restrictions may be relaxed in later
versions.

Attempts to access a future instance created in one thread from another thread
will raise an exception:

=for highlighter

   Future::XS instance IO::Async::Future=SCALAR(0x...) is not available in this thread at ...

As a special case for process cleanup activities, the C<< ->cancel >> method
does not throw this exception, but simply returns silently. This is because
cleanup code such as C<DESTROY> methods or C<defer> blocks often attempt to
call this on existing instances.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
