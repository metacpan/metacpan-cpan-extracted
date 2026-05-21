#!/usr/bin/env perl
# Demonstrate the qcache option: c-ares' built-in TTL-respecting query
# cache. The first query goes over the network; subsequent identical
# queries (within TTL) return synchronously from cache.
# Usage: perl eg/cache_demo.pl [name]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);
use Time::HiRes ();

my $name = shift // 'cloudflare.com';

# Without cache
my $r_nocache = EV::cares->new(qcache => 0, timeout => 5);

# With cache (60s TTL ceiling)
my $r_cached = EV::cares->new(qcache => 60, timeout => 5);

sub bench {
    my ($label, $r, $n) = @_;
    my @times;
    _bench_step($r, $n, \@times, 0);
    EV::run;
    printf "%-20s ", $label;
    printf "%6.1fms ", $_ for @times;
    print "\n";
}

# named-sub recursion avoids the CV-to-pad reference cycle that a
# self-referential `my $next; $next = sub { ... $next->() }` closure would
# create (and which Perl's refcount GC cannot collect).
sub _bench_step {
    my ($r, $n, $times, $i) = @_;
    return EV::break if $i >= $n;
    my $t0 = Time::HiRes::time();
    $r->resolve($name, sub {
        push @$times, 1000 * (Time::HiRes::time() - $t0);
        _bench_step($r, $n, $times, $i + 1);
    });
}

print "5 sequential resolves of $name\n\n";
bench 'qcache => 0 (off)', $r_nocache, 5;
bench 'qcache => 60',      $r_cached,  5;

print "\nWith caching enabled, queries 2..N should be near-instant.\n";
