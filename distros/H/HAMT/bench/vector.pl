#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use HAMT::Vector qw(hamt_vector_get);

# A vector against an array: where it loses (a single read, which an array
# does with an opcode) and where it wins (anything that would copy the array
# or move half of it).
#
# Usage: perl bench/vector.pl [SIZE]

my $T = -($ENV{HAMT_BENCH_SECONDS} || 1);
my $n = shift(@ARGV) || 100_000;
my @a = (1 .. $n);
my $v = HAMT::Vector->new(@a);
my @idx = map { int rand $n } 1 .. 1000;
my $mid = int($n / 2);
my $quarter = int($n / 4);
print "a vector of $n; perl $], $^O\n";

print "\nbuilding\n";
cmpthese($T, {
    'array push' => sub { my @b; push @b, $_ for 1 .. $n },
    'new(@a)'    => sub { my $b = HAMT::Vector->new(@a) },
    'transient'  => sub { my $t = HAMT::Vector->new->transient; $t->push($_) for 1 .. $n; my $b = $t->persistent },
});

print "\nreading 1,000 elements\n";
cmpthese($T, {
    'array fetch' => sub { my $x; $x = $a[$_] for @idx },
    'vector get'  => sub { my $x; $x = $v->get($_) for @idx },
    'vector get, function' => sub { my $x; $x = hamt_vector_get($v, $_) for @idx },
});

print "\nwalking all of it\n";
cmpthese($T, {
    'for (@a)'    => sub { my $s = 0; $s += $_ for @a },
    'vector each' => sub { my $s = 0; $v->each(sub { $s += $_[0] }) },
    'vector list' => sub { my $s = 0; $s += $_ for $v->list },
    'copy @a'     => sub { my @c = @a },
});

print "\none change, keeping the old version\n";
cmpthese($T, {
    'copy, set'       => sub { my @c = @a; $c[$mid] = 0 },
    'vector set'      => sub { my $c = $v->set($mid, 0) },
    'vector push'     => sub { my $c = $v->push(0) },
    'vector pop'      => sub { my $c = $v->pop },
    'copy, splice in' => sub { my @c = @a; splice @c, $mid, 0, 0 },
    'vector insert'   => sub { my $c = $v->insert($mid, 0) },
    'vector remove'   => sub { my $c = $v->remove($mid) },
});

print "\ncutting and joining\n";
cmpthese($T, {
    'array slice'   => sub { my @c = @a[$mid .. $mid + $quarter - 1] },
    'vector slice'  => sub { my $c = $v->slice($mid, $quarter) },
    'array join'    => sub { my @c = (@a, @a) },
    'vector concat' => sub { my $c = $v->concat($v) },
});

print "\ninsert in the middle with nothing kept, for scale\n";
my @w = @a;
cmpthese($T, {
    'splice in place'      => sub { splice @w, $mid, 0, 0; pop @w },
    'vector insert, remove' => sub { my $c = $v->insert($mid, 0)->remove($mid) },
});
