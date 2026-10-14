#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use HAMT::Set;

# Union, intersection and difference of two sets, against the hash idioms:
# between sets built apart, at three overlaps, and then between two versions
# of one set a few members apart, which is where sharing is the whole cost.
#
# Usage: perl bench/set-algebra.pl [SIZE]

my $T = -($ENV{HAMT_BENCH_SECONDS} || 1);
my $n = shift(@ARGV) || 100_000;
print "sets of $n members; perl $], $^O\n";

sub compare {
    my ($a, $b, $sa, $sb) = @_;
    cmpthese($T, {
        'hash union'     => sub { my %u = (%$a, %$b) },
        'set union'      => sub { my $u = $sa->union($sb) },
        'hash intersect' => sub { my %i = map { ($_ => 1) } grep { $b->{$_} } keys %$a },
        'set intersect'  => sub { my $i = $sa->intersect($sb) },
        'hash difference' => sub { my %d = map { ($_ => 1) } grep { !$b->{$_} } keys %$a },
        'set difference' => sub { my $d = $sa->difference($sb) },
    });
    cmpthese($T, {
        'hash subset?' => sub { my $s = !grep { !$b->{$_} } keys %$a },
        'set subset?'  => sub { my $s = $sa->is_subset($sb) },
        'hash equal?'  => sub { my $e = keys %$a == keys %$b && !grep { !$b->{$_} } keys %$a },
        'set equal?'   => sub { my $e = $sa->equals($sb) },
    });
    return;
}

for my $case ([ 'disjoint', $n ], [ 'half shared', int($n / 2) ], [ 'the same members', 0 ]) {
    my ($name, $offset) = @$case;
    my %a = map { ("m$_" => 1) } 1 .. $n;
    my %b = map { ("m$_" => 1) } $offset + 1 .. $offset + $n;
    print "\nbuilt apart, $name\n";
    compare(\%a, \%b, HAMT::Set->new(keys %a), HAMT::Set->new(keys %b));
}

my %a = map { ("m$_" => 1) } 1 .. $n;
my %b = (%a, map { ("extra$_" => 1) } 1 .. 5);
delete @b{ map { "m$_" } 1 .. 5 };
my $sa = HAMT::Set->new(keys %a);
my $sb = $sa->add(map { "extra$_" } 1 .. 5)->remove(map { "m$_" } 1 .. 5);
print "\ntwo versions of one set, ten members apart\n";
compare(\%a, \%b, $sa, $sb);
