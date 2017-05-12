#!perl -T

use strict;
use warnings;

use Test::More tests => 20;

use Cache::Memcached;
use Memoize::Memcached qw( :all ),
  memcached => {
    servers => [qw( 127.0.0.1:11211 )],
  },
  ;



my $side_effect;


sub memo_this_00 {
  my $x = shift;
  $side_effect = 'side effect';
  return $x;
}


sub memo_this_01 {
  my $x = shift;
  $side_effect = 'side effect';
  return $x;
}


SKIP: {
  {
    my @servers = qw( 127.0.0.1:11211 );
    my $memcached = Cache::Memcached->new(
      servers => \@servers,
    )
      or do {
        local $, = ', ';
        skip "No memcached server running on hosts @servers", 20;
      };

    my $stats = do {
      # This call will throw lots of warnings if there's no memcached
      # server.
      local $SIG{__WARN__} = sub {};
      $memcached->stats;
    };
    skip "No memcached server running on hosts @servers", 20
      unless $stats and $stats->{hosts};
  }

  ok(memoize_memcached('memo_this_00'), "Memoizing of 'memo_this_00'");
  ok(memoize_memcached('memo_this_01'), "Memoizing of 'memo_this_01'");

  ok(flush_cache(), "Global flush cache");

  $side_effect = 'none';
  is(memo_this_00(5), 5, "Memoized function 'memo_this_00' returns correct value");
  is($side_effect, 'side effect', "Memoized function 'memo_this_00' side effect detected");

  $side_effect = 'none';
  is(memo_this_00(5), 5, "Memoized function 'memo_this_00' returns correct value");
  is($side_effect, 'none', "Memoized function 'memo_this_00' side effect not detected");

  $side_effect = 'none';
  is(memo_this_01(5), 5, "Memoized function 'memo_this_01' returns correct value");
  is($side_effect, 'side effect', "Memoized function 'memo_this_01' side effect detected");

  $side_effect = 'none';
  is(memo_this_01(5), 5, "Memoized function 'memo_this_01' returns correct value");
  is($side_effect, 'none', "Memoized function 'memo_this_01' side effect not detected");

  ok(flush_cache(memo_this_00 => 5), "Flush cache for 'memo_this_00' with arg (5)");

  $side_effect = 'none';
  is(memo_this_00(5), 5, "Memoized function 'memo_this_00' returns correct value");
  is($side_effect, 'side effect', "Memoized function 'memo_this_00' side effect detected");

  $side_effect = 'none';
  is(memo_this_01(5), 5, "Memoized function 'memo_this_01' returns correct value");
  is($side_effect, 'none', "Memoized function 'memo_this_01' side effect not detected");

  flush_cache('memo_this_00');

  $side_effect = 'none';
  is(memo_this_00(5), 5, "Memoized function 'memo_this_00' returns correct value");
  is($side_effect, 'side effect', "Memoized function 'memo_this_00' side effect detected");

  $side_effect = 'none';
  is(memo_this_01(5), 5, "Memoized function 'memo_this_01' returns correct value");
  is($side_effect, 'side effect', "Memoized function 'memo_this_01' side effect detected");

  flush_cache();
}
