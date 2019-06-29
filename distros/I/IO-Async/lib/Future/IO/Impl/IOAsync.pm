#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::IO::Impl::IOAsync;

use strict;
use warnings;
use base qw( Future::IO::ImplBase );

=head1 NAME

C<Future::IO::Impl::IOAsync> - implement C<Future::IO> using C<IO::Async>

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses
L<IO::Async>.

There are no additional methods to use in this module; it simply has to be
loaded, and will provide the C<Future::IO> implementation methods.

   use Future::IO;
   use Future::IO::Impl::IOAsync;

   my $f = Future::IO->sleep(5);
   ...

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

my %watching_read_by_fileno; # {fileno} => [@futures]

# Not (yet) part of Future::IO API but it seems a useful way to build this
sub ready_for_read
{
   shift;
   my ( $fh ) = @_;

   my $watching = $watching_read_by_fileno{ $fh->fileno } //= [];

   $loop //= IO::Async::Loop->new;
   my $f = $loop->new_future;

   my $was = scalar @$watching;
   push @$watching, $f;

   return $f if $was;

   $loop->watch_io(
      handle => $fh,
      on_read_ready => sub {
         $watching->[0]->done;
         shift @$watching;

         return if scalar @$watching;

         $loop->unwatch_io(
            handle => $fh,
            on_read_ready => 1,
         );
         delete $watching_read_by_fileno{ $fh->fileno };
      },
   );

   return $f;
}

my %watching_write_by_fileno; # {fileno} => [@futures]

sub ready_for_write
{
   shift;
   my ( $fh ) = @_;

   my $watching = $watching_write_by_fileno{ $fh->fileno } //= [];

   $loop //= IO::Async::Loop->new;
   my $f = $loop->new_future;

   my $was = scalar @$watching;
   push @$watching, $f;

   return $f if $was;

   $loop->watch_io(
      handle => $fh,
      on_write_ready => sub {
         $watching->[0]->done;
         shift @$watching;

         return if scalar @$watching;

         $loop->unwatch_io(
            handle => $fh,
            on_write_ready => 1,
         );
         delete $watching_write_by_fileno{ $fh->fileno };
      },
   );

   return $f;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
