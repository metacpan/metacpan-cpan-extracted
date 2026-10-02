use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Socket ();

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

# k51: every listen socket queues SOMAXCONN pending connections (the kernel
# caps it), not IO::Async's default of 3 -- with workers, connections wait
# there while the supervisor probes before the fork.

sub free_port {
  require IO::Socket::INET;
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "free_port: $!";
  my $p = $s->sockport;
  $s->close;
  return $p;
}

my $expected = eval { Socket::SOMAXCONN() } || 128;
my @ports = ( free_port(), free_port() );

my @asked;
my $knarr = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Code->new( code => sub { 'x' } ),
  loop    => IO::Async::Loop->new,
  listen  => [ map { "127.0.0.1:$_" } @ports ],
);
{
  no warnings 'redefine';
  my $orig = \&IO::Async::Loop::listen;
  local *IO::Async::Loop::listen = sub {
    my ( $loop, %params ) = @_;
    push @asked, $params{queuesize};
    goto &$orig;
  };
  $knarr->start;
}

is( \@asked, [ $expected, $expected ], "both listen addresses ask for a backlog of $expected" );
ok( $expected > 3, 'more than the IO::Async default of 3' );

SKIP: {
  my $ss = -x '/usr/bin/ss' ? '/usr/bin/ss' : -x '/bin/ss' ? '/bin/ss' : undef;
  skip 'no ss to read the kernel backlog', 2 unless $ss;
  my $cap = -r '/proc/sys/net/core/somaxconn'
    ? do { open my $fh, '<', '/proc/sys/net/core/somaxconn'; 0 + <$fh> } : $expected;
  my $kernel = $expected < $cap ? $expected : $cap;
  for my $port (@ports) {
    my ($line) = grep { /127\.0\.0\.1:$port\b/ } `$ss -ltn`;
    # LISTEN  Recv-Q  Send-Q  Local ...  -- Send-Q is the backlog
    my ( undef, undef, $backlog ) = split ' ', $line // '';
    is( $backlog, $kernel, "port $port: the kernel queues $kernel" );
  }
}

done_testing;
