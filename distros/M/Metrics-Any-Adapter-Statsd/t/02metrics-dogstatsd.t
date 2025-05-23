#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Metrics::Any '$metrics';
use Metrics::Any::Adapter 'DogStatsd';

use IO::Socket::INET;

# A local statsd "server" which will do for testing
my $socket = IO::Socket::INET->new(
   LocalHost => "127.0.0.1",
   LocalPort => 0,
   Proto => "udp",
) or die "$@";

{
   no warnings 'once';
   $Net::Statsd::PORT = $socket->sockport;
}

# counters
{
   $metrics->make_counter( counter =>
      name => "the.counter",
      labels => [qw( label )],
   );

   $metrics->inc_counter( counter => "labvalue" );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.counter:1|c|#label:labvalue",
      '->inc_counter sends statsd packet'
   );
}

# distributions
{
   $metrics->make_distribution( distribution =>
      name => "the.distribution",
      labels => [qw( label )],
   );

   $metrics->report_distribution( distribution => 20, "labvalue" );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.distribution:20|h|#label:labvalue",
      '->report_distribution sends statsd packet'
   );
}

# gauges
{
   $metrics->make_gauge( gauge =>
      name => "the.gauge",
      labels => [qw( label )],
   );

   $metrics->set_gauge_to( gauge => 123, "labvalue" );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.gauge:123|g|#label:labvalue",
      '->set_gauge_to sends statsd packet'
   );
}

# timers
{
   $metrics->make_timer( timer =>
      name => "the.timer",
      labels => [qw( label )],
   );

   $metrics->report_timer( timer => 0.25, "labvalue" ); # seconds

   $socket->recv( my $packet, 512 );
   is( $packet, "the.timer:250|ms|#label:labvalue",
      '->report_timer sends statsd packet'
   );
}

done_testing;
