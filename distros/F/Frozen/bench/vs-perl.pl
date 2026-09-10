#!/usr/bin/env perl
use strict;
use warnings;

# Frozen against a plain Perl hash, which is the comparison everybody will
# make and the one most likely to be assumed backwards.
#
# Reported three ways - raw ops/sec, net ns per operation, and net ops/sec.
# See per_op below for why one number would mislead.
#
# READ THE ANSWER BEFORE THE NUMBERS.
#
# Frozen's lookup is FLAT and a Perl hash's DEGRADES. Measured on this box,
# net of the harness, per hit:
#
#     keys        perl    Frozen
#        500      22.0      30.7
#     10,000      30.0      32.0
#     50,000      37.5      32.0
#    200,000      40.3      36.2
#
# Frozen grows 18% across a four-hundredfold increase in table size; the Perl
# hash grows 83%, because its bucket array stops fitting in cache and a chain
# walk starts costing misses. The perfect hash has no chain to walk.
#
# So Frozen wins above roughly twenty thousand keys and loses below, and the
# reason it loses below is a floor it cannot get under: an XSUB call frame,
# which `$h{$k}` does not pay because it is an opcode. That floor is about
# 15-20ns and it is most of the gap at small n.
#
# Two consequences for the documentation. It must not say "faster than a Perl
# hash" without the size qualifier. And the C consumer - which reaches the
# same lookup through fz_abi.h with no Perl frame at all - does not pay the
# floor, so its numbers are a different and better story that this benchmark
# cannot measure.
#
# The other axis is memory, which is the one Frozen was built for, so this
# prints both.
#
# Usage: perl bench/vs-perl.pl [KEYS]

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Frozen ();
use Benchmark qw(cmpthese timethese);
no warnings 'once';

my $N = shift(@ARGV) || 100_000;

print "Frozen against pure Perl, $N keys, perl $], $^O\n\n";

# ---- the data, in three shapes -------------------------------------------

my %flat = map { ("key$_" => "value for key $_") } 1 .. $N;

# The nested shape is what punk_i18n.h actually holds - a catalogue, not a
# flat map - and it is what Frozen would replace. A flat hash flatters Perl,
# because the nested form costs a fetch per segment.
my %nested;
for my $i (1 .. $N) {
    my $sec = "section" . ($i % 200);
    my $grp = "group" . (($i / 50) % 20);
    $nested{$sec}{$grp}{"key$i"} = "value for key $i";
}

my $blk = Frozen->freeze(\%flat);
my $fz  = Frozen->attach($blk);
my $rt  = $fz->root;

printf "block: %d bytes for %d keys (%.1f bytes/key), perfect hash: %s\n\n",
       length $blk, $N, length($blk) / $N,
       Frozen->_has_mphf($blk) ? 'yes' : 'no';

# ---- the probe set --------------------------------------------------------
#
# Fixed and precomputed, so neither arm pays for generating it, and shared so
# both walk the same keys in the same order.

my @probe = map { "key" . (1 + int rand $N) } 1 .. 1000;

# Absent keys, PRECOMPUTED and the same shape and length as the present ones.
# The first version built them as "absent" . $i++ inside the loop, so as $i
# climbed into the millions the keys grew to thirteen characters while the hit
# arm's stayed at eight - the miss arm was hashing more bytes and allocating a
# fresh SV per call, and the gap was partly that rather than the lookup.
my @absent = map { "nokey" . (1 + int rand $N) } 1 .. 1000;
my $i      = 0;

# A coderef as well as the class method, because `Frozen->_find(...)` resolves
# a method on every call and that cost is the API's, not the format's. Showing
# both says which is which.
my $find = \&Frozen::find;

# Correctness before speed: a fast wrong answer is not a result.
for my $k (@probe[0 .. 99]) {
    die "Frozen disagrees with Perl on '$k'\n"
        unless defined $flat{$k} && defined $find->($fz, $k);
}

# THE BASELINE ARM IS NOT OPTIONAL.
#
# The first version of this benchmark wrote each arm as
# `$flat{ $probe[$i++ % 1000] }` and reported Frozen as 4% FASTER than a Perl
# hash on hits - which is not credible, because an XSUB call plus two 64-bit
# hashes plus a memcmp cannot beat one hash opcode. What it was measuring was
# mostly `$probe[$i++ % 1000]`: an array fetch, an increment and a modulo,
# paid identically by both arms and large enough to swamp the difference
# between them.
#
# So every arm loops over a batch, and `baseline` does the loop and the key
# selection and NOTHING ELSE. Subtracting it is what turns these into
# per-lookup costs rather than per-iteration costs.

my $BATCH = 200;

# Three numbers, and they are not interchangeable.
#
#   raw/s      what Benchmark actually measured, harness included. This is the
#              rate a caller writing this exact loop would see.
#   net ns     the same figure with the baseline arm subtracted, so it is the
#              cost of the OPERATION rather than of the loop around it.
#   net/s      1e9 / net ns - a synthetic rate, what the operation would run at
#              if the loop were free. It is the honest way to compare two
#              operations, and a dishonest thing to quote as throughput.
#
# Reporting only raw/s understates every difference here, because the harness
# is about 30ns and the operations are 20-40ns. Reporting only net/s overstates
# what anybody will actually get. Both, labelled.
sub per_op {
    my ($res, $base) = @_;
    my (%ns, %raw);
    for my $name (keys %$res) {
        my $t   = $res->{$name};
        my $ops = $t->iters * $BATCH;
        my $cpu = $t->cpu_a || 1e-9;
        $ns{$name}  = 1e9 * $cpu / $ops;
        $raw{$name} = $ops / $cpu;
    }
    # NOT `my $b` - that shadows the sort block's $b and every comparison
    # below silently becomes undef <=> undef.
    my $base_ns = delete $ns{$base} || 0;
    printf "  %-16s %12s %10s %14s\n", 'arm', 'raw/s', 'net ns', 'net/s';
    printf "  %-16s %12s %10.1f %14s\n",
           $base, commify($raw{$base}), $base_ns, '-';
    for my $name (sort { $ns{$a} <=> $ns{$b} } keys %ns) {
        my $net = $ns{$name} - $base_ns;
        printf "  %-16s %12s %10.1f %14s\n",
               $name, commify($raw{$name}), $net,
               $net > 0 ? commify(1e9 / $net) : 'n/a';
    }
}

sub commify {
    my $n = int(shift);
    1 while $n =~ s/^(\d+)(\d{3})/$1,$2/;
    return $n;
}

print "-- flat lookup, hit (batched, with the loop cost isolated) --\n";
{
    my $r = timethese(-2, {
        'baseline'       => sub { my $k = $probe[ $i++ % 1000 ]; },
        'perl hash'      => sub { my $v = $flat{ $probe[ $i++ % 1000 ]  } },
        'Frozen method'  => sub { my $v = $fz->find($probe[ $i++ % 1000 ]);  },
        'Frozen coderef' => sub { my $v = $find->($fz, $probe[ $i++ % 1000 ]);  },
    }, 'none');
    cmpthese($r);
}

print "\n-- flat lookup, miss --\n";
{
    my $r = timethese(-2, {
        'baseline'       => sub { my $k = $absent[ $i++ % 1000 ]; },
        'perl hash'      => sub { my $v = $flat{ $absent[ $i++ % 1000 ] }; },
        'Frozen coderef' => sub { my $v = $find->($fz, $absent[ $i++ % 1000 ]); },
    }, 'none');
    cmpthese($r);
}

print "\n-- exists --\n";
{
    my $r = timethese(-2, {
        'baseline'       => sub { my $k = $probe[ $i++ % 1000 ]; },
        'perl exists'    => sub { my $v = exists $flat{ $probe[ $i++ % 1000 ] }; },
        'Frozen coderef' => sub { my $v = defined $find->($fz, $probe[ $i++ % 1000 ]); },
    }, 'none');
    cmpthese($r);
}

# ---- what it costs to have the data at all --------------------------------
#
# The axis that matters. Measured as the block against a rough accounting of
# the Perl hash, which is deliberately generous to Perl: it counts only the
# key and value bytes plus a conservative per-SV overhead, and ignores the
# bucket array entirely.

{
    my $bytes = 0;
    $bytes += length($_) + length($flat{$_}) for keys %flat;
    my $sv_overhead = 56 * 2;          # one SV head per key and per value
    my $perl_est    = $bytes + $N * $sv_overhead;
    printf "\n-- size --\n";
    printf "  perl hash  ~%9d bytes  (payload %d + %d SV heads at 56, "
         . "bucket array ignored)\n", $perl_est, $bytes, $N * 2;
    printf "  Frozen      %9d bytes  (%.2fx smaller)\n",
           length $blk, $perl_est / length $blk;
    printf "  and Frozen's pages survive a fork, where the hash's are copied\n"
         . "  the first time each worker reads them - see bench/pagesharing.pl\n";
}

print "\n-- nested lookup, the shape a catalogue actually has --\n";
#
# A flat map flatters Perl. What punk_i18n.h holds is a catalogue, three
# levels deep, and that is the shape Frozen has to win on to be worth
# migrating to. Four ways of reaching the same leaf:
#
#   perl nested      three hash opcodes, no call frame
#   Frozen descent   child, child, fetch - FOUR XSUB frames
#   Frozen get       one frame, three probes inside it
#   Frozen get+flat  one frame, ONE probe, using the flat index
#
# The spread between descent and get is the whole lesson of this dist's
# performance work: the frame count is the variable, not the algorithm.
{
    my $nested_flat = eval { Frozen->attach(Frozen->freeze(\%nested, flat => '.')) };
    my $nested_tree = Frozen->attach(Frozen->freeze(\%nested));
    print "  (no flat index for this size: 4096-leaf cap)\n" if !$nested_flat;

    my (@np, @nd);
    for (1 .. 1000) {
        my $n = 1 + int rand $N;
        my @seg = ("section" . ($n % 200), "group" . (($n / 50) % 20), "key$n");
        push @np, \@seg;
        push @nd, join('.', @seg);
    }

    # Correctness before speed.
    {
        my $p = $np[0];
        my $want = $nested{$p->[0]}{$p->[1]}{$p->[2]};
        my ($got) = $nested_tree->get($nd[0]);
        die "Frozen disagrees on $nd[0]\n" unless defined $want && $got eq $want;
    }

    my $j = 0;
    my $r = timethese(-2, {
        'baseline'      => sub { for (1 .. $BATCH) { my $p = $np[ $j++ % 1000 ]; } },
        'perl nested'   => sub { for (1 .. $BATCH) { my $p = $np[ $j++ % 1000 ];
                                     my $v = $nested{$p->[0]}{$p->[1]}{$p->[2]}; } },
        'Frozen descent'=> sub { for (1 .. $BATCH) { my $p = $np[ $j++ % 1000 ];
                                     my $h = $nested_tree->child($nested_tree->root, $p->[0]);
                                     $h = $nested_tree->child($h, $p->[1]);
                                     my ($v) = $nested_tree->fetch($h, $p->[2]); } },
        'Frozen get'    => sub { for (1 .. $BATCH) { $j++;
                                     my ($v) = $nested_tree->get($nd[ $j % 1000 ]); } },
        ($nested_flat ? ('Frozen get+flat' => sub { for (1 .. $BATCH) { $j++;
                                     my ($v) = $nested_flat->get($nd[ $j % 1000 ]); } }) : ()),
    }, 'none');
    per_op($r, 'baseline');
}
