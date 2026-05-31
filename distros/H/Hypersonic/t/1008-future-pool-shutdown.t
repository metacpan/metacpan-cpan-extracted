#!/usr/bin/env perl
use strict;
use warnings;

# Load and compile Future/Pool BEFORE Test::More
use Hypersonic::Future;
use Hypersonic::Future::Pool;
Hypersonic::Future->compile();

use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

# Test shutdown
{
    my $pool = Hypersonic::Future::Pool->new(workers => 4);
    $pool->init;
    ok($pool->is_initialized, 'Pool initialized');

    my $result = $pool->shutdown;
    ok($result, 'Shutdown returns true');
    ok(!$pool->is_initialized, 'Pool not initialized after shutdown');
}

# Test reinit after shutdown
{
    my $pool = Hypersonic::Future::Pool->new(workers => 4);
    $pool->init;
    ok($pool->is_initialized, 'Pool initialized');

    # Can submit work
    my $f = Hypersonic::Future->new;
    $pool->submit($f, sub { return 42 }, []);

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($f->is_done, 'Future works');
    is($f->result, 42, 'Result correct');

    $pool->shutdown;
}

# Test shutdown when not initialized
{
    my $pool = Hypersonic::Future::Pool->new(workers => 2);
    ok(!$pool->is_initialized, 'Pool not initialized');
    my $result = $pool->shutdown;
    is($result, 0, 'Shutdown returns 0 when not initialized');
}

done_testing;
