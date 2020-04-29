#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Metrics::Any '$metrics';
use Metrics::Any::Adapter 'Statsd';

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
   );

   $metrics->inc_counter( counter => );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.counter:1|c",
      '->inc_counter sends statsd packet'
   );
}

# distributions
{
   $metrics->make_distribution( distribution =>
      name => "the.distribution",
   );

   $metrics->inc_distribution_by( distribution => 20 );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.distribution.count:1|c\nthe.distribution.sum:20|c",
      '->inc_distribution sends statsd packet'
   );
}

# gauges
{
   $metrics->make_gauge( gauge =>
      name => "the.gauge",
   );

   $metrics->set_gauge_to( gauge => 123 );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.gauge:123|g",
      '->set_gauge_to sends statsd packet'
   );

   $metrics->inc_gauge_by( gauge => 45 );

   $socket->recv( $packet, 512 );
   is( $packet, "the.gauge:+45|g",
      '->set_gauge_to sends statsd packet'
   );

   # Special format for negative absolute values
   $metrics->set_gauge_to( gauge => -20 );

   $socket->recv( $packet, 512 );
   is( $packet, "the.gauge:0|g\nthe.gauge:-20|g",
      '->set_gauge_to sends statsd packet'
   );
}

# timers
{
   $metrics->make_timer( timer =>
      name => "the.timer",
   );

   $metrics->inc_timer_by( timer => 0.25 ); # seconds

   $socket->recv( my $packet, 512 );
   is( $packet, "the.timer:250|ms",
      '->inc_timer sends statsd packet'
   );
}

done_testing;
