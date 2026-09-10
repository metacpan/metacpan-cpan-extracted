#!/usr/bin/env perl
use strict;
use warnings;

# The decision Phase 06 requirement 5 turns on: is segment-at-a-time descent
# fast enough to leave the tree as the representation, or does the optional
# flat index have to be built?
#
# Frozen stores the tree, so a dotted lookup is N O(1) probes where a
# flattened representation would do one. N is two or three for a catalogue.
# The number that matters is descent against a Perl nested traversal, which is
# what punk_i18n.h's tied-hash door actually competes with.

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Frozen ();
use Benchmark qw(timethese);
no warnings 'once';

my $SECTIONS = 200;
my $GROUPS   = 20;
my $PER      = 25;

my %cat;
for my $s (1 .. $SECTIONS) {
    for my $g (0 .. $GROUPS - 1) {
        for my $k (1 .. $PER) {
            $cat{"section$s"}{"group$g"}{"key$k"} = "translation $s/$g/$k";
        }
    }
}
my $leaves = $SECTIONS * $GROUPS * $PER;

my $fz   = Frozen->attach(Frozen->freeze(\%cat));
my $root = $fz->root;

# The same data with a flat index over dotted paths. It is limited to 4096
# leaves in this release, so a catalogue this size cannot have one - which is
# itself the number that matters.
my $flat = eval { Frozen->attach(Frozen->freeze(\%cat, flat => '.')) };
my $flat_root = $flat ? $flat->root : undef;
print $flat ? "flat index built\n" : "flat index refused: $@";

printf "%d leaves, block %d bytes (%.1f per leaf)\n\n", $leaves, $fz->size,
       $fz->size / $leaves;

my @probe = map {
    my $s = 1 + int rand $SECTIONS;
    my $g = int rand $GROUPS;
    my $k = 1 + int rand $PER;
    ["section$s", "group$g", "key$k"]
} 1 .. 1000;
my @dotted = map { join '.', @$_ } @probe;

# Correctness before speed.
for my $i (0 .. 9) {
    my $p = $probe[$i];
    my $want = $cat{$p->[0]}{$p->[1]}{$p->[2]};
    my ($h) = $fz->path($root, $dotted[$i]);
    die "descent disagrees\n" unless $fz->value($h) eq $want;
}

my $i = 0;
my $B = 100;

# The baseline arm does the index and nothing else, because the arms below
# differ by one operation and the loop cost is large enough to hide it.
my $r = timethese(-2, {
    'baseline'      => sub { for (1..$B) { my $p = $probe[$i++ % 1000]; } },
    'perl nested'   => sub { for (1..$B) { my $p = $probe[$i++ % 1000];
                                           my $v = $cat{$p->[0]}{$p->[1]}{$p->[2]}; } },
    'Frozen descent'=> sub { for (1..$B) { my $p = $probe[$i++ % 1000];
                                           my $h = $fz->child($root, $p->[0]);
                                           $h = $fz->child($h, $p->[1]);
                                           my ($v) = $fz->fetch($h, $p->[2]); } },
    'Frozen path'   => sub { for (1..$B) { my $p = $probe[$i++ % 1000];
                                           my ($h) = $fz->path($root, $dotted[$i % 1000]);
                                           my $v = $fz->value($h); } },
    ($flat ? ('Frozen flat' => sub { for (1..$B) { $i++;
                                       my ($h) = $flat->path($flat_root, $dotted[$i % 1000]);
                                       my $v = $flat->value($h); } }) : ()),
}, 'none');

my %ns;
for (keys %$r) { $ns{$_} = 1e9 * ($r->{$_}->cpu_a || 1e-9) / ($r->{$_}->iters * $B) }
my $base = delete $ns{baseline};
printf "baseline %.1f ns (subtracted)\n\n", $base;
printf "  %-16s %8.1f ns\n", $_, $ns{$_} - $base
    for sort { $ns{$a} <=> $ns{$b} } keys %ns;

print "\nthe question: is descent close enough to leave the tree as the\n"
    . "representation, or must the optional flat index be built?\n";
