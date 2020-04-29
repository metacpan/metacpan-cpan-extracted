#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Metrics::Any '$metrics';
use Metrics::Any::Adapter 'SignalFx';

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
   is( $packet, "the.[label=labvalue]counter:1|c",
      '->inc_counter sends statsd packet'
   );
}

# distributions
{
   $metrics->make_distribution( distribution =>
      name => "the.distribution",
      labels => [qw( label )],
   );

   $metrics->inc_distribution_by( distribution => 20, "labvalue" );

   $socket->recv( my $packet, 512 );
   is( $packet, "the.distribution.[label=labvalue]count:1|c\nthe.distribution.[label=labvalue]sum:20|c",
      '->inc_distribution sends statsd packet'
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
   is( $packet, "the.[label=labvalue]gauge:123|g",
      '->set_gauge_to sends statsd packet'
   );
}

# timers
{
   $metrics->make_timer( timer =>
      name => "the.timer",
      labels => [qw( label )],
   );

   $metrics->inc_timer_by( timer => 0.25, "labvalue" ); # seconds

   $socket->recv( my $packet, 512 );
   is( $packet, "the.[label=labvalue]timer:250|ms",
      '->inc_timer sends statsd packet'
   );
}

done_testing;
