#!/usr/bin/env perl
use strict;
use warnings;

# Load and compile Future/Pool BEFORE Test::More
use Hypersonic::Future;
use Hypersonic::Future::Pool;
Hypersonic::Future->compile();

use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

# Create and init pool (OO API)
my $pool = Hypersonic::Future::Pool->new(workers => 4);
$pool->init;

# Test error handling - die
{
    my $f = Hypersonic::Future->new;

    $pool->submit($f, sub {
        die "Intentional error";
    }, []);

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($f->is_failed, 'Future failed when code dies');
    my ($msg) = $f->failure;
    like($msg, qr/Intentional error/, 'Failure message contains error');
}

# Test error handling - croak
{
    my $f = Hypersonic::Future->new;

    $pool->submit($f, sub {
        require Carp;
        Carp::croak("Croaked error");
    }, []);

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($f->is_failed, 'Future failed when code croaks');
    my ($msg) = $f->failure;
    like($msg, qr/Croaked error/, 'Failure message contains croak');
}

# Test error with catch recovery
{
    my $f = Hypersonic::Future->new;
    my $recovered;

    my $chain = $f->catch(sub {
        my ($err) = @_;
        $recovered = $err;
        return 'recovered';
    });

    $pool->submit($f, sub {
        die "Error to catch";
    }, []);

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($f->is_failed, 'Original future failed');
    ok($chain->is_done, 'Chained future recovered');
    like($recovered, qr/Error to catch/, 'Catch received error');
    is($chain->result, 'recovered', 'Catch returned recovery value');
}

$pool->shutdown;

done_testing;
