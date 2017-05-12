use strict;
use Test::More;

use lib 't/lib';
use libmemcached_test;

# This test requires at least 5 memcached instances.
# We start out by creating 100 items in 4 instances.
# After that, we add another server to the server list, and
# do the fetch of the 100 items. When used with consistent hashing, we
# should be getting around 80% hit ratio

my @servers;
BEGIN
{
    @servers = libmemcached_test_servers();
    plan skip_all => "Set PERL_LIBMEMCACHED_TEST_SERVERS env var to at least 5 servers to run this test"
        if @servers < 5;

    plan(tests => 2);
    use_ok("Cache::Memcached::libmemcached", "MEMCACHED_DISTRIBUTION_CONSISTENT");
}

my $max = 100;

{ # First, flush everything in these test memcached
    my $cache = Cache::Memcached::libmemcached->new({
        servers => \@servers,
    });
    $cache->flush_all;
}

{ # Now, warm 4 out of 5 servers
    my $cache = Cache::Memcached::libmemcached->new({
        servers => [ @servers[0..3] ],
        distribution_method => MEMCACHED_DISTRIBUTION_CONSISTENT,
    });

    for (1..$max) {
        $cache->set($_ => $_);
    }
}

{ # 4 caches have been warmed. add another cache, and our hit ratio should
  # be somewhere around 0.80 (we'll allow plus-or-minus 0.05
    my $hits = 0;
    my $cache = Cache::Memcached::libmemcached->new({
        servers => [ @servers[0..4] ],
        distribution_method => MEMCACHED_DISTRIBUTION_CONSISTENT,
    });

    for (1..$max) {
        if (defined $cache->get($_)) {
            $hits++;
        }
    }

    my $ratio = $hits / $max;
    ok( $ratio >= 0.75 && $ratio <= 0.85, "Hit ratio is somewhere around 0.80 (was $ratio)" );
}
