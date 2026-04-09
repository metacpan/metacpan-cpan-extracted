#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'void';
use Test::More;

# Skip if ps command not available (Windows, minimal docker containers, etc.)
my $ps_available = eval { my $r = `ps -o rss= -p $$ 2>/dev/null`; defined $r && $r =~ /\d/ };
plan skip_all => 'ps command not available' unless $ps_available;

# Memory leak tests for util higher-order functions

use Func::Util qw(
    dig tap
    stub_true stub_false stub_array stub_hash stub_string stub_zero
    first any all none
    pick omit defaults
    negate
    count
);

plan tests => 16;

# Helper to get current RSS in KB
sub get_rss {
    my $rss = `ps -o rss= -p $$`;
    chomp $rss;
    return $rss + 0;
}

# Test for memory leaks
sub test_no_leak {
    my ($name, $code, $iterations, $threshold_kb) = @_;
    $iterations //= 10_000;
    $threshold_kb //= 5_000;
    
    $code->() for 1..100;  # Warmup
    
    my $before = get_rss();
    $code->() for 1..$iterations;
    my $after = get_rss();
    
    my $diff = $after - $before;
    my $passed = $diff < $threshold_kb;
    ok($passed, "$name - memory growth: ${diff}KB");
    diag("LEAK: before=${before}KB after=${after}KB") unless $passed;
}

# Test dig
my $nested = { a => { b => { c => 42 } } };
test_no_leak("dig", sub {
    my $r = dig($nested, qw(a b c));
});

# Test tap
test_no_leak("tap", sub {
    my $r = tap(sub { }, 42);
});

# Test stubs - these return values, not coderefs
test_no_leak("stub_true", sub {
    my $r = stub_true();
});

test_no_leak("stub_false", sub {
    my $r = stub_false();
});

test_no_leak("stub_array", sub {
    my @r = stub_array();
});

test_no_leak("stub_hash", sub {
    my %r = stub_hash();
});

test_no_leak("stub_string", sub {
    my $r = stub_string();
});

test_no_leak("stub_zero", sub {
    my $r = stub_zero();
});

# Test first/any/all/none with callbacks using & prototype
my @nums = (1, 2, 3, 4, 5);
test_no_leak("first with callback", sub {
    my $r = first(sub { $_ > 2 }, @nums);
});

test_no_leak("any with callback", sub {
    my $r = any(sub { $_ > 2 }, @nums);
});

test_no_leak("all with callback", sub {
    my $r = all(sub { $_ > 0 }, @nums);
});

test_no_leak("none with callback", sub {
    my $r = none(sub { $_ < 0 }, @nums);
});

# Test pick/omit
my %hash = (a => 1, b => 2, c => 3);
test_no_leak("pick", sub {
    my %r = pick(\%hash, 'a', 'b');
});

test_no_leak("omit", sub {
    my %r = omit(\%hash, 'c');
});

# Test defaults
test_no_leak("defaults", sub {
    my %r = defaults({ a => 1 }, { a => 2, b => 3 });
});

# Test negate
my $is_even = sub { $_[0] % 2 == 0 };
my $is_odd = negate($is_even);
test_no_leak("negate", sub {
    my $r = $is_odd->(3);
});

done_testing();
