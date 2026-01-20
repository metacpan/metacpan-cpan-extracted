#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::IOAsync 0.805;

use v5.14;
use warnings;
use base qw( Future::IO::ImplBase );
BEGIN { Future::IO::ImplBase->VERSION( '0.19' ); }

use Future::IO qw( POLLIN POLLOUT POLLHUP );

=head1 NAME

C<Future::IO::Impl::IOAsync> - implement C<Future::IO> using C<IO::Async>

=head1 DESCRIPTION

=for highlighter language=perl

This module provides an implementation for L<Future::IO> which uses
L<IO::Async>.

There are no additional methods to use in this module; it simply has to be
loaded, and will provide the C<Future::IO> implementation methods.

   use Future::IO;
   use Future::IO::Impl::IOAsync;

   my $f = Future::IO->sleep(5);
   ...

=head1 LIMITATIONS

This module only provides a limited subset of the L<Future::IO/poll> method
API. It fully handles C<POLLIN> and C<POLLOUT> conditions, but is not able to
report on C<POLLHUP> and C<POLLERR> events.

When a filehandle is at hangup condition it is reported as only C<POLLIN>, and
when at error condition it is reported as only C<POLLOUT>. This I<should> be
sufficient for most purposes, and works fine for internally providing
asynchronous reading and writing on regular filehandles, but may cause some
odd behaviours if you are attempting to detect those conditions directly.

=cut

use IO::Async::Loop;

__PACKAGE__->APPLY;

my $loop;

sub sleep
{
   shift;
   my ( $secs ) = @_;

   return ( $loop //= IO::Async::Loop->new )->delay_future( after => $secs );
}

my %futures_read_by_fileno;  # {fileno} => [@futures]
my %futures_write_by_fileno; # {fileno} => [@futures]

sub poll
{
   shift;
   my ( $fh, $events ) = @_;

   my $fileno = $fh->fileno;

   my $f = ( $loop //= IO::Async::Loop->new )->new_future;

   if( $events & (POLLIN|POLLHUP) ) {
      my $futures = $futures_read_by_fileno{$fileno} //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      # We can't watch for on_hangup as well here because most loop
      # implementations will invoke that *as well as* on_read_ready, but
      # only afterwards. That makes it difficult to report POLLHUP conditions
      # properly.
      $loop->watch_io(
         handle => $fh,
         on_read_ready => sub {
            $futures->[0]->done( POLLIN );
            shift @$futures;

            return if scalar @$futures;

            $loop->unwatch_io(
               handle => $fh,
               on_read_ready => 1,
            );
            delete $futures_read_by_fileno{$fileno};
         },
      ) if !$was;
   }
   if( $events & POLLOUT ) {
      my $futures = $futures_write_by_fileno{$fileno} //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      $loop->watch_io(
         handle => $fh,
         on_write_ready => sub {
            $futures->[0]->done( POLLOUT );
            shift @$futures;

            return if scalar @$futures;

            $loop->unwatch_io(
               handle => $fh,
               on_write_ready => 1,
            );
            delete $futures_write_by_fileno{$fileno};
         },
      ) if !$was;
   }

   return $f;
}

sub waitpid
{
   shift;
   my ( $pid ) = @_;

   my $f = ( $loop //= IO::Async::Loop->new )->new_future;

   $loop->watch_process( $pid, sub {
      my ( undef, $wstatus ) = @_;
      $f->done( $wstatus );
   } );
   $f->on_cancel( sub { $loop->unwatch_process( $pid ) } );

   return $f;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
