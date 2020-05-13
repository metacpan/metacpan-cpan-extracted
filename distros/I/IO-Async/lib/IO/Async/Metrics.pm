#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package IO::Async::Metrics;

use strict;
use warnings;

# Metrics support is entirely optional
our $METRICS;
eval {
   require Metrics::Any and
      Metrics::Any->VERSION( '0.05' ) and
      Metrics::Any->import( '$METRICS',
         name_prefix => [qw( io_async )],
      );
};

=head1 NAME

C<IO::Async::Metrics> - report metrics about C<IO::Async> to C<Metrics::Any>

=head1 DESCRIPTION

This module contains the implementation of metrics-reporting code from
C<IO::Async> to provide information about its operation into L<Metrics::Any>.

=cut

sub import
{
   my $class = shift;
   my $caller = caller;
   my ( $varname ) = @_;

   $varname =~ s/^\$//;

   no strict 'refs';
   *{"${caller}::${varname}"} = \$METRICS;
}

=head1 METRICS

The following metrics are reported:

=head2 io_async_forks

A counter giving the number of times that C<fork(2)> has been called by the
L<IO::Async::Loop>.

=head2 io_async_notifiers

A gauge giving the number of L<IO::Async::Notifiers> currently registered
with the Loop.

=head2 io_async_processing

A time distribution giving the amount of time spent processing IO events. This
time does not include the time spent blocking on the underlying kernel system
call to wait for IO events, but only the time spent in userland afterwards to
handle them.

=head2 io_async_resolver_lookups

A labelled counter giving the number of attempted lookups by the
L<IO::Async::Resolver>.

This metric has one label, C<type>, containing the type of lookup;
e.g. C<getaddrinfo>.

=head2 io_async_resolver_failures

A labelled counter giving the number of Resolver lookups that failed. This is
labelled as for C<io_async_resolver_lookups>.

=head2 io_async_stream_read

A counter giving the number of bytes read by L<IO::Async::Stream> instances.
Note that for SSL connections, this will only be able to count bytes of
plaintext, not ciphertext, and thus will be a slight under-estimate in this
case.

=head2 io_async_stream_written

A counter giving the number of bytes written by Stream instances. Note again
for SSL connections this will only be able to count bytes of plaintext.

=cut

if( defined $METRICS ) {
   # Loop metrics
   $METRICS->make_gauge( notifiers =>
      description => "Number of IO::Async::Notifiers registered with the Loop",
   );
   $METRICS->make_counter( forks =>
      description => "Number of times IO::Async has fork()ed a process",
   );
   $METRICS->make_timer( processing_time =>
      name => [qw( processing )],
      description => "Time spent by IO::Async:Loop processing IO",
      # Override bucket generation
      bucket_min => 0.001, bucket_max => 1, # 1msec to 1sec
      buckets_per_decade => [qw( 1 2.5 5 )],
   );
   $METRICS->make_gauge( loops =>
      description => "Count of IO::Async::Loop instances by class",
      labels => [qw( class )],
   );

   # Resolver metrics
   $METRICS->make_counter( resolver_lookups =>
      name => [qw( resolver lookups )],
      description => "Number of IO::Async::Resolver lookups by type",
      labels => [qw( type )],
   );
   $METRICS->make_counter( resolver_failures =>
      name => [qw( resolver failures )],
      description => "Number of IO::Async::Resolver lookups that failed by type",
      labels => [qw( type )],
   );

   # Stream metrics
   $METRICS->make_counter( stream_written =>
      name => [qw( stream written )],
      description => "Bytes written by IO::Async::Streams",
      units => "bytes",
   );
   $METRICS->make_counter( stream_read =>
      name => [qw( stream read )],
      description => "Bytes read by IO::Async::Streams",
      units => "bytes",
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
