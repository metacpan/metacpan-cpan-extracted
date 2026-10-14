#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Storable ();
use HAMT::Map;

# One update that keeps the old version: the thing a persistent map is for.
# Against the two ways a hash does it, both of which copy everything.
#
# Usage: perl bench/map-update.pl [SIZE ...]
#        HAMT_BENCH_SECONDS=3 perl bench/map-update.pl 10000

my $T = -($ENV{HAMT_BENCH_SECONDS} || 1);
my @sizes = @ARGV ? @ARGV : (10, 100, 1_000, 10_000, 100_000);
print "one update, keeping the old version; perl $], $^O\n";

for my $n (@sizes) {
    my %h = map { ("key$_" => $_) } 1 .. $n;
    my $m = HAMT::Map->new(%h);
    print "\n$n keys\n";
    cmpthese($T, {
        'hash copy'    => sub { my %c = (%h, new => 1) },
        'dclone'       => sub { my $c = Storable::dclone(\%h); $c->{new} = 1 },
        'set new'      => sub { my $c = $m->set(new => 1) },
        'set existing' => sub { my $c = $m->set(key1 => 0) },
        'delete'       => sub { my $c = $m->delete('key1') },
        'update'       => sub { my $c = $m->update(key1 => sub { $_[0] + 1 }) },
    });
}
