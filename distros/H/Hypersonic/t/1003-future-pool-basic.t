#!/usr/bin/env perl
use strict;
use warnings;

# Load and compile Future/Pool BEFORE Test::More to avoid call checker conflicts
use Hypersonic::Future;
use Hypersonic::Future::Pool;
Hypersonic::Future->compile();

# Now load Test::More
use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

# Test OO interface - single pool
{
    my $pool = Hypersonic::Future::Pool->new(workers => 2);
    ok($pool, 'Pool created');
    isa_ok($pool, 'Hypersonic::Future::Pool');
    is($pool->workers, 2, 'Workers set correctly');
    ok(!$pool->is_initialized, 'Pool not initialized initially');

    # Initialize
    my $result = $pool->init;
    ok($result, 'Pool init returns true');
    ok($pool->is_initialized, 'Pool is initialized');

    # Init again should be no-op
    my $result2 = $pool->init;
    ok($result2, 'Second init also returns true');

    # Get notify fd
    my $fd = $pool->get_notify_fd;
    ok($fd >= 0, "notify_fd is valid ($fd)");

    # Pending count
    my $count = $pool->pending_count;
    is($count, 0, 'No pending operations initially');

    # Shutdown
    my $shutdown = $pool->shutdown;
    ok($shutdown, 'Shutdown returns true');
    ok(!$pool->is_initialized, 'Pool not initialized after shutdown');
}

# Test multiple pools
{
    my $pool1 = Hypersonic::Future::Pool->new(workers => 4);
    my $pool2 = Hypersonic::Future::Pool->new(workers => 2);

    isnt($$pool1, $$pool2, 'Different pools have different slots');

    $pool1->init;
    $pool2->init;

    ok($pool1->is_initialized, 'Pool 1 initialized');
    ok($pool2->is_initialized, 'Pool 2 initialized');

    is($pool1->workers, 4, 'Pool 1 has 4 workers');
    is($pool2->workers, 2, 'Pool 2 has 2 workers');

    # Both should have valid notify fds
    my $fd1 = $pool1->get_notify_fd;
    my $fd2 = $pool2->get_notify_fd;
    ok($fd1 >= 0, "Pool 1 notify_fd valid ($fd1)");
    ok($fd2 >= 0, "Pool 2 notify_fd valid ($fd2)");
    isnt($fd1, $fd2, 'Pools have different notify fds');

    $pool1->shutdown;
    $pool2->shutdown;
}

# Test backward compatibility - init_global
{
    my $pool = Hypersonic::Future::Pool->init_global(workers => 3);
    ok($pool, 'init_global returns pool');
    isa_ok($pool, 'Hypersonic::Future::Pool');
    ok($pool->is_initialized, 'Global pool is initialized');
    is($pool->workers, 3, 'Global pool has correct workers');

    my $default = Hypersonic::Future::Pool->default_pool;
    is($$default, $$pool, 'default_pool returns same pool slot');

    Hypersonic::Future::Pool->shutdown_global;
    ok(!defined Hypersonic::Future::Pool->default_pool, 'default_pool is undef after shutdown');
}

done_testing;
