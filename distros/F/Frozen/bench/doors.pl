#!/usr/bin/env perl
use strict;
use warnings;

# THE GATE FOR PHASE 07, and the number belongs in the POD.
#
# The tied door is the pretty one. Without a figure printed beside it,
# somebody will build a request path on `$locale->{items}{one}` and discover
# the cost in production. `tie` is a full method dispatch per FETCH, where the
# fast door is one XSUB call - and a template that resolves three segments
# pays three dispatches.
#
# Reported three ways for the reason bench/vs-perl.pl gives: raw ops/sec is
# what a caller sees, net is what the operation costs, and quoting only one of
# them misleads in opposite directions.

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Frozen ();
use Benchmark qw(timethese);
no warnings 'once';

my $SECTIONS = 40;
my $GROUPS   = 5;
my $PER      = 10;

my %cat;
for my $s (1 .. $SECTIONS) {
    for my $g (0 .. $GROUPS - 1) {
        for my $k (1 .. $PER) {
            $cat{"section$s"}{"group$g"}{"key$k"} = "translation $s/$g/$k";
        }
    }
}
my $leaves = $SECTIONS * $GROUPS * $PER;

my $fz   = Frozen->attach(Frozen->freeze(\%cat, flat => '.'));
my $root = $fz->root;
my $tied = $fz->tied;

printf "%d leaves, block %d bytes, flat index: %s\n\n",
       $leaves, $fz->size, 'yes';

my (@seg, @dot);
for (1 .. 1000) {
    my $s = 1 + int rand $SECTIONS;
    my $g = int rand $GROUPS;
    my $k = 1 + int rand $PER;
    push @seg, ["section$s", "group$g", "key$k"];
    push @dot, "section$s.group$g.key$k";
}

# Correctness before speed.
{
    my $p = $seg[0];
    my $want = $cat{$p->[0]}{$p->[1]}{$p->[2]};
    die "get disagrees\n"  unless ($fz->get($dot[0]))[0] eq $want;
    die "tie disagrees\n"  unless $tied->{$p->[0]}{$p->[1]}{$p->[2]} eq $want;
}

my $i = 0;
my $B = 100;

my $r = timethese(-2, {
    'fast: get'   => sub { for (1..$B) { $i++; my ($v) = $fz->get($dot[$i % 1000]); } },
    'fast: probe' => sub { for (1..$B) { my $p = $seg[$i++ % 1000];
                               my $h = $fz->child($root, $p->[0]);
                               $h = $fz->child($h, $p->[1]);
                               my ($v) = $fz->fetch($h, $p->[2]); } },
    'tied: 3 deep'=> sub { for (1..$B) { my $p = $seg[$i++ % 1000];
                               my $v = $tied->{$p->[0]}{$p->[1]}{$p->[2]}; } },
    'tied: 1 deep'=> sub { for (1..$B) { my $p = $seg[$i++ % 1000];
                               my $v = $tied->{$p->[0]}; } },
    'perl nested' => sub { for (1..$B) { my $p = $seg[$i++ % 1000];
                               my $v = $cat{$p->[0]}{$p->[1]}{$p->[2]}; } },
}, 'none');

my (%ns, %raw);
for (keys %$r) {
    my $ops = $r->{$_}->iters * $B;
    my $cpu = $r->{$_}->cpu_a || 1e-9;
    $ns{$_}  = 1e9 * $cpu / $ops;
    $raw{$_} = $ops / $cpu;
}
sub commify { my $n = int(shift); 1 while $n =~ s/^(\d+)(\d{3})/$1,$2/; $n }
my $base = delete $ns{'fast: get'};
printf "  %-14s %12s %10s %14s\n", 'door', 'raw/s', 'net ns', 'net/s';
printf "  %-14s %12s %10.1f %14s\n", 'fast get', commify($raw{'fast: get'}), $base, '-';
for my $n (sort { $ns{$a} <=> $ns{$b} } keys %ns) {
    my $net = $ns{$n} - $base;
    printf "  %-14s %12s %10.1f %14s\n", $n, commify($raw{$n}), $net,
           $net > 0 ? commify(1e9 / $net) : 'n/a';
}

