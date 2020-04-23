#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Future::Mutex;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.45';

use Future;

=head1 NAME

C<Future::Mutex> - mutual exclusion lock around code that returns L<Future>s

=head1 SYNOPSIS

   use Future::Mutex;

   my $mutex = Future::Mutex->new;

   sub do_atomically
   {
      return $mutex->enter( sub {
         ...
         return $f;
      });
   }

=head1 DESCRIPTION

Most L<Future>-using code expects to run with some level of concurrency, using
future instances to represent still-pending operations that will complete at
some later time. There are occasions however, when this concurrency needs to
be restricted - some operations that, once started, must not be interrupted
until they are complete. Subsequent requests to perform the same operation
while one is still outstanding must therefore be queued to wait until the
first is finished. These situations call for a mutual-exclusion lock, or
"mutex".

A C<Future::Mutex> instance provides one basic operation, which will execute a
given block of code which returns a future, and itself returns a future to
represent that. The mutex can be in one of two states; either unlocked or
locked. While it is unlocked, requests to execute code are handled
immediately. Once a block of code is invoked, the mutex is now considered to
be locked, causing any subsequent requests to invoke code to be queued behind
the first one, until it completes. Once the initial code indicates completion
(by its returned future providing a result or failing), the next queued code
is invoked.

An instance may also be a counting mutex if initialised with a count greater
than one. In this case, it can keep multiple blocks outstanding up to that
limit, with subsequent requests queued as before. This allows it to act as a
concurrency-bounding limit around some operation that can run concurrently,
but an application wishes to apply overall limits to stop it growing too much,
such as communications with external services or executing other programs.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $mutex = Future::Mutex->new( count => $n )

Returns a new C<Future::Mutex> instance. It is initially unlocked.

Takes the following named arguments:

=over 8

=item count => INT

Optional number to limit outstanding concurrency. Will default to 1 if not
supplied.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   return bless {
      avail => $params{count} // 1,
      queue => [],
   }, $class;
}

=head1 METHODS

=cut

=head2 enter

   $f = $mutex->enter( \&code )

Returns a new C<Future> that represents the eventual result of calling the
code. If the mutex is currently unlocked, the code will be invoked
immediately. If it is currently locked, the code will be queued waiting for
the next time it becomes unlocked.

The code is invoked with no arguments, and is expected to return a C<Future>.
The eventual result of that future determines the result of the future that
C<enter> returned.

=cut

sub enter
{
   my $self = shift;
   my ( $code ) = @_;

   my $down_f;
   if( $self->{avail} ) {
      $self->{avail}--;
      $down_f = Future->done;
   }
   else {
      push @{ $self->{queue} }, $down_f = Future->new;
   }

   my $up = sub {
      if( my $next_f = shift @{ $self->{queue} } ) {
         $next_f->done;
      }
      else {
         $self->{avail}++;
      }
   };

   $down_f->then( $code )->on_ready( $up );
}

=head2 available

   $avail = $mutex->available

Returns true if the mutex is currently unlocked, or false if it is locked.

=cut

sub available
{
   my $self = shift;
   return $self->{avail};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
