#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use HAMT::Map;

# Walking a whole map, against walking a hash. The rates are whole walks.
#
# Usage: perl bench/map-iter.pl [SIZE ...]

my $T = -($ENV{HAMT_BENCH_SECONDS} || 1);
my @sizes = @ARGV ? @ARGV : (1_000, 100_000);
print "walking every entry; perl $], $^O\n";

for my $n (@sizes) {
    my %h = map { ("key$_" => $_) } 1 .. $n;
    my $m = HAMT::Map->from_hash(\%h);
    print "\n$n keys: the keys, the values\n";
    cmpthese($T, {
        'keys %h'    => sub { my @k = keys %h },
        'map keys'   => sub { my @k = $m->keys },
        'values %h'  => sub { my @v = values %h },
        'map values' => sub { my @v = $m->values },
    });
    print "\n$n keys: every pair\n";
    cmpthese($T, {
        'each %h'     => sub { my $s = 0; while (my ($k, $v) = each %h) { $s += $v } },
        'map each'    => sub { my $s = 0; $m->each(sub { $s += $_[1] }) },
        'map pairs'   => sub { my %c = $m->pairs },
        'map to_hash' => sub { my $c = $m->to_hash },
        'copy %h'     => sub { my %c = %h },
    });
}
