#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use HAMT::Map;
use HAMT::Vector;

# Memory, by the resident size of a fresh process before and after: what one
# container costs against a hash or an array, and what a thousand versions
# cost against a thousand copies. Each case runs in a child of its own.
#
# This one does not use Benchmark: it measures space and not time.
#
# Usage: perl bench/memory.pl

sub rss_kb {
    my $kb = `ps -o rss= -p $$ 2>/dev/null`;
    return defined $kb && $kb =~ /(\d+)/ ? $1 : 0;
}

sub grown {
    my ($label, $build) = @_;
    pipe(my $r, my $w) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $r;
        my $before = rss_kb();
        my $keep = $build->();
        print {$w} rss_kb() - $before;
        close $w;
        exit 0;
    }
    close $w;
    my $kb = do { local $/; <$r> };
    waitpid $pid, 0;
    printf "  %-44s %9.1f MB\n", $label, $kb / 1024;
    return $kb;
}

print "resident memory grown; perl $], $^O\n";

print "\n1,000,000 short keys with integer values\n";
my $h = grown('a hash', sub { my %h; $h{"key$_"} = $_ for 1 .. 1_000_000; \%h });
my $m = grown('a HAMT::Map', sub { my $t = HAMT::Map->new->transient; $t->set("key$_", $_) for 1 .. 1_000_000; $t->persistent });
printf "  the map is %.2f times the hash\n", $m / $h if $h;

print "\n1,000,000 integers\n";
# Pushed one at a time, as the vector is: a list of a million built first
# would be counted against the array.
my $a = grown('an array', sub { my @a; push @a, $_ for 1 .. 1_000_000; \@a });
my $v = grown('a HAMT::Vector', sub { my $t = HAMT::Vector->new->transient; $t->push($_) for 1 .. 1_000_000; $t->persistent });
printf "  the vector is %.2f times the array\n", $v / $a if $a;

print "\n1,000 versions of a 10,000-key map, each one set apart\n";
my $copies = grown('1,000 copies of a hash', sub {
    my %h; $h{"key$_"} = $_ for 1 .. 10_000;
    my @keep;
    for my $i (1 .. 1000) { $h{"key$i"} = -$i; push @keep, { %h } }
    \@keep;
});
my $versions = grown('1,000 versions of a HAMT::Map', sub {
    my $t = HAMT::Map->new->transient; $t->set("key$_", $_) for 1 .. 10_000;
    my $m = $t->persistent;
    my @keep;
    for my $i (1 .. 1000) { $m = $m->set("key$i" => -$i); push @keep, $m }
    \@keep;
});
printf "  the versions are 1/%.0f of the copies\n", $copies / $versions if $versions;

print "\n1,000 versions of a 100,000-long vector, each one set apart\n";
my $acopies = 10 * grown('100 copies of an array', sub {
    my @a; push @a, $_ for 1 .. 100_000;
    my @keep;
    for my $i (1 .. 100) { $a[$i] = -$i; push @keep, [ @a ] }
    \@keep;
});
my $vversions = grown('1,000 versions of a HAMT::Vector', sub {
    my $t = HAMT::Vector->new->transient; $t->push($_) for 1 .. 100_000;
    my $v = $t->persistent;
    my @keep;
    for my $i (1 .. 1000) { $v = $v->set($i * 97, -$i); push @keep, $v }
    \@keep;
});
printf "  the versions are 1/%.0f of 1,000 copies (ten times the 100 measured)\n", $acopies / $vversions if $vversions;
