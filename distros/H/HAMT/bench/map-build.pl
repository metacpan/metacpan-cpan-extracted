#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use HAMT::Map;

# Building a map, each way there is, against building a hash. The rates are
# whole builds.
#
# Usage: perl bench/map-build.pl [SIZE]

my $T = -($ENV{HAMT_BENCH_SECONDS} || 2);
my $n = shift(@ARGV) || 100_000;
my @keys = map { "key$_" } 1 .. $n;
my %src; @src{@keys} = (1 .. $n);
print "building $n keys; perl $], $^O\n\n";

cmpthese($T, {
    'hash, one by one' => sub { my %h; my $i = 0; $h{$_} = $i++ for @keys },
    'from_hash'        => sub { my $m = HAMT::Map->from_hash(\%src) },
    'new(%h)'          => sub { my $m = HAMT::Map->new(%src) },
    'transient'        => sub { my $t = HAMT::Map->new->transient; my $i = 0; $t->set($_, $i++) for @keys; my $m = $t->persistent },
    'persistent set'   => sub { my $m = HAMT::Map->new; my $i = 0; $m = $m->set($_, $i++) for @keys },
});
