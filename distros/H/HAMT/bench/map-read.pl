#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use HAMT::Map qw(hamt_map_get hamt_map_exists);

# Reading, against a hash. Each timed call reads the same 1,000 keys, so the
# rates are per thousand reads.
#
# A hash fetch is an opcode and a map's get is a method call, so part of any
# gap is the call and not the lookup: "empty method" calls a method that
# does nothing a thousand times, for scale. "map get, function" is
# hamt_map_get, which is the same read without the call.
#
# Usage: perl bench/map-read.pl [SIZE ...]

{
    package Local::Empty;
    sub new { bless {}, shift }
    sub nothing { }
}

my $T = -($ENV{HAMT_BENCH_SECONDS} || 1);
my @sizes = @ARGV ? @ARGV : (100, 10_000, 1_000_000);
my $empty = Local::Empty->new;
print "reading 1,000 keys; perl $], $^O\n";

for my $n (@sizes) {
    my %h = map { ("key$_" => $_) } 1 .. $n;
    my $m = HAMT::Map->from_hash(\%h);
    my @present = map { 'key' . (1 + int rand $n) } 1 .. 1000;
    my @absent  = map { "nokey$_" } 1 .. 1000;
    print "\n$n keys, present\n";
    cmpthese($T, {
        'hash fetch'   => sub { my $x; $x = $h{$_} for @present },
        'map get'      => sub { my $x; $x = $m->get($_) for @present },
        'map get, function' => sub { my $x; $x = hamt_map_get($m, $_) for @present },
        'empty method' => sub { $empty->nothing($_) for @present },
    });
    print "\n$n keys, absent\n";
    cmpthese($T, {
        'hash exists' => sub { my $x; $x = exists $h{$_} for @absent },
        'map exists'  => sub { my $x; $x = $m->exists($_) for @absent },
        'map exists, function' => sub { my $x; $x = hamt_map_exists($m, $_) for @absent },
    });
}
