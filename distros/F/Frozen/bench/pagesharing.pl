#!/usr/bin/env perl
use strict;
use warnings;

# Phase 01's gate: does preload-then-fork actually lose its page sharing for
# Perl data, does mmap fix it, and does either beat the flat block Punk
# already has?
#
# Four arms over the same catalogue-shaped data:
#
#   hoh    a Perl HoH built before the fork          - the thing being disproved
#   json   one JSON scalar, decoded in each worker   - the naive alternative
#   flat   one block scalar, offsets into it         - the punk_i18n.h status quo
#   mmap   the same bytes in a file, mapped per worker - the Frozen shape
#
# EACH ARM RUNS IN ITS OWN PROCESS. Running them in one parent was the first
# version and it was wrong: the parent accumulates every arm's data, so by the
# third arm `parent_private` is measuring the first two. The driver re-execs
# itself once per arm.
#
# NOTHING IS COPIED OUT OF THE BLOCK. The flat and mmap arms both address ONE
# scalar by offset. The first version did `substr($all, 4 + $ilen)` to split
# index from block, which copies the whole 50 MiB out of the mapping and makes
# the mmap arm the worst of the four - measuring the copy, not the mapping.
#
# Linux is authoritative: /proc/self/smaps_rollup is the only thing here that
# separates shared from private. On macOS the numbers are advisory and are
# labelled so. `ps -o rss` is NOT used anywhere, because it counts shared pages
# in full in every process and would report the sharing as already gone.
#
# Usage:
#   perl bench/pagesharing.pl                    # every arm, one process each
#   perl bench/pagesharing.pl --arm flat         # one arm, in this process
#   perl bench/pagesharing.pl --unit             # the unit probe only
#   perl bench/pagesharing.pl --dirtyby          # which kind of read dirties
#   perl bench/pagesharing.pl --mmapprobe        # is File::Raw's data() zero-copy?

use File::Temp ();

my %OPT = (workers => 4, reads => 20_000, leaves => 200_000, seed => 20260909,
           arm => '', unit => 0, dirtyby => 0, mmapprobe => 0, keep => '');
{
    my @a = @ARGV;
    while (@a) {
        my $k = shift @a;
        $k =~ s/^--// or die "unknown argument: $k\n";
        my $v;
        ($k, $v) = ($1, $2) if $k =~ /^([\w]+)=(.*)$/;
        die "unknown option: $k\n" unless exists $OPT{$k};
        if ($k =~ /^(unit|dirtyby|mmapprobe)$/) { $OPT{$k} = defined $v ? $v : 1 }
        else { $OPT{$k} = defined $v ? $v : shift @a }
    }
}

my $LINUX = -r '/proc/self/smaps_rollup';

# ---- memory reporting ------------------------------------------------------

# Returns (private_dirty, shared_clean, pss).
#
# PSS IS THE POOL METRIC, not Private_Dirty, and the reason is a trap that cost
# a rewrite. "Private" in smaps means MAPCOUNT == 1, not "copied": one process
# mapping a file read-only shows its pages as Private_CLEAN, indistinguishable
# by that field from a private copy. They only become Shared_Clean once several
# workers map the same file. Gating on Private_* alone rejects the mmap arm for
# looking like exactly the thing it is not. Pss divides each shared page by the
# number of sharers, which is the question actually being asked.
sub mem_kib {
    if ($LINUX) {
        open my $fh, '<', '/proc/self/smaps_rollup' or return (0, 0, 0);
        my %v;
        while (<$fh>) { $v{$1} = $2 if /^(\w+):\s+(\d+) kB/ }
        close $fh;
        return ($v{Private_Dirty} || 0, $v{Shared_Clean} || 0, $v{Pss} || 0);
    }
    # macOS: phys_footprint excludes pages shared with other processes, the
    # closest available analogue of Private_Dirty. Advisory only.
    my $out = `footprint -p $$ 2>/dev/null` || '';
    if ($out =~ /phys_footprint[^0-9]*([\d.]+)\s*([KMG])/i) {
        my ($n, $u) = ($1, uc $2);
        return (int($n * ($u eq 'G' ? 1048576 : $u eq 'M' ? 1024 : 1)), 0, 0);
    }
    return (0, 0, 0);
}

# ---- the unit probe --------------------------------------------------------
#
# The field's unit is not documented anywhere reliable, and assuming the wrong
# one scales every threshold by 1024 while the gate still says PASS. So:
# allocate a known block, touch every page, and see how far the number moves.

sub probe_unit {
    my ($before) = mem_kib();
    my $MB  = 64;
    my $buf = "\0" x ($MB * 1048576);
    for (my $i = 0; $i < length $buf; $i += 4096) { substr($buf, $i, 1, 'x') }
    my ($after) = mem_kib();
    my $moved = $after - $before;
    my $ratio = $moved / ($MB * 1024);
    printf "unit probe: touched %d MiB, the figure moved %d => reads as %s (%.3f vs KiB)\n",
           $MB, $moved,
           ($ratio > 0.5   && $ratio < 2)     ? 'KiB'
         : ($ratio > 500   && $ratio < 2000)  ? 'BYTES'
         : ($ratio > 4e-4  && $ratio < 2e-3)  ? 'MiB'
         : 'UNRECOGNISED - do not gate on it', $ratio;
    return $ratio;
}

# ---- the data --------------------------------------------------------------

sub build_data {
    my ($leaves) = @_;
    my %h;
    my @sections = map { "section$_" } 1 .. 200;
    my $per = int($leaves / @sections) || 1;
    for my $s (@sections) {
        my %sub;
        for my $i (1 .. $per) {
            my $g = "group" . int($i / 50);
            $sub{$g}{"key$i"} = "translation for $s $g key$i - " . ('x' x 80);
        }
        $h{$s} = \%sub;
    }
    return \%h;
}

sub flatten {
    my ($h, $prefix, $out) = @_;
    $out ||= [];
    for my $k (sort keys %$h) {
        my $v = $h->{$k};
        my $p = defined $prefix ? "$prefix.$k" : $k;
        ref $v eq 'HASH' ? flatten($v, $p, $out) : push @$out, [$p, $v];
    }
    return $out;
}

# ONE buffer: a 12-byte header, then the packed index, then the bytes.
#   header: N n_entries, N index_off, N block_off
#   index:  n * (N koff, N klen, N voff, N vlen)   offsets are into the buffer
sub build_buffer {
    my ($pairs) = @_;
    my $hdr_len = 12;
    my $idx_len = 16 * @$pairs;
    my $blk_off = $hdr_len + $idx_len;
    my ($block, $index) = ('', '');
    for my $p (@$pairs) {
        my ($k, $v) = @$p;
        my $koff = $blk_off + length $block; $block .= $k;
        my $voff = $blk_off + length $block; $block .= $v;
        $index .= pack 'NNNN', $koff, length $k, $voff, length $v;
    }
    return pack('NNN', scalar @$pairs, $hdr_len, $blk_off) . $index . $block;
}

# Binary search, addressing the ONE buffer by offset. $bref is a reference so
# the buffer is never copied into this sub.
sub buf_get {
    my ($bref, $key) = @_;
    my ($n, $idx_off) = unpack 'NN', substr($$bref, 0, 8);
    my ($lo, $hi) = (0, $n - 1);
    while ($lo <= $hi) {
        my $mid = ($lo + $hi) >> 1;
        my ($koff, $klen, $voff, $vlen)
            = unpack 'NNNN', substr($$bref, $idx_off + $mid * 16, 16);
        my $c = substr($$bref, $koff, $klen) cmp $key;
        if    ($c < 0) { $lo = $mid + 1 }
        elsif ($c > 0) { $hi = $mid - 1 }
        else           { return substr($$bref, $voff, $vlen) }
    }
    return;
}

# ---- one arm, in this process ---------------------------------------------

sub run_arm {
    my ($arm) = @_;

    my $data  = build_data($OPT{leaves});
    my $pairs = flatten($data);
    my $nsec  = 200;
    my $per   = int($OPT{leaves} / $nsec) || 1;
    # NO SHARED KEY ARRAY. Holding 200k key strings in the parent and picking
    # from it in each child dirtied ~65 MiB per child in every arm - the
    # harness reproducing the very effect under test, and charging it to
    # whichever arm was being measured. Keys are composed arithmetically
    # instead, so a child touches no inherited SV to choose one.
    my $random_key = sub {
        my $s = 1 + int rand $nsec;
        my $i = 1 + int rand $per;
        return "section$s.group" . int($i / 50) . ".key$i";
    };

    my ($json, $buf, $path, $tmpdir);
    if ($arm eq 'json') {
        require JSON::PP;
        $json = JSON::PP->new->canonical->encode($data);
        undef $data;                       # the parent holds only the scalar
    }
    elsif ($arm eq 'flat') {
        $buf = build_buffer($pairs);
        undef $data;
    }
    elsif ($arm eq 'mmap') {
        # THE FILE IS BUILT IN A CHILD THAT THEN EXITS.
        #
        # Not a convenience: perl does not return freed memory to the OS, so a
        # parent that built the buffer carries its peak allocation for the rest
        # of its life even after `undef`. Measuring that would charge Frozen for
        # a build the design says happens at DEPLOY time - `punk i18n compile`
        # writing a .frz that the server only ever maps. Building in a child
        # models the shipped artifact, which is the actual claim.
        $tmpdir = $OPT{keep} || File::Temp::tempdir(CLEANUP => 1);
        $path = "$tmpdir/cat.bin";
        my $bpid = fork;
        die "fork: $!" unless defined $bpid;
        if ($bpid == 0) {
            my $b = build_buffer($pairs);
            open my $fh, '>:raw', "$path.tmp" or die $!;
            print $fh $b; close $fh;
            rename "$path.tmp", $path or die $!;
            exit 0;
        }
        waitpid $bpid, 0;
        die "the builder child failed\n" unless -s $path;
        undef $data;                       # the parent holds NOTHING
    }
    undef $pairs;

    my ($base_priv) = mem_kib();
    pipe(my $rfh, my $wfh) or die "pipe: $!";

    my @kids;
    for my $w (1 .. $OPT{workers}) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            close $rfh;
            srand($OPT{seed} + $w);
            my ($lookup, $hold);

            if ($arm eq 'hoh') {
                $lookup = sub {
                    my $c = $data;
                    $c = $c->{$_} for split /\./, $_[0];
                    return $c;
                };
            }
            elsif ($arm eq 'json') {
                require JSON::PP;
                my $d = JSON::PP->new->decode($json);      # the per-worker parse
                $hold = $d;
                $lookup = sub {
                    my $c = $d;
                    $c = $c->{$_} for split /\./, $_[0];
                    return $c;
                };
            }
            elsif ($arm eq 'flat') {
                $lookup = sub { buf_get(\$buf, $_[0]) };
            }
            elsif ($arm eq 'mmap') {
                require File::Raw;
                my $m = File::Raw::mmap_open($path);
                # data() must hand back the mapping, not a copy of it. Held by
                # reference and never assigned into another scalar.
                my $ref = \($m->data);
                $hold = [$m, $ref];
                $lookup = sub { buf_get($ref, $_[0]) };
            }

            my $sink = 0;
            for (1 .. $OPT{reads}) {
                my $v = $lookup->($random_key->());
                $sink += length($v || '');
            }
            my ($priv, $shcl, $pss) = mem_kib();
            print $wfh "$priv $shcl $pss $sink\n";
            close $wfh;
            exit 0;
        }
        push @kids, $pid;
    }
    close $wfh;

    my ($cpriv, $cshcl, $cpss, $n) = (0, 0, 0, 0);
    while (my $l = <$rfh>) {
        my ($p, $s, $ps) = split ' ', $l;
        $cpriv += $p; $cshcl += $s; $cpss += $ps; $n++;
    }
    close $rfh;
    waitpid $_, 0 for @kids;

    my ($ppriv, $pshcl, $ppss) = mem_kib();
    printf "RESULT %s parent=%d children=%d nkids=%d shared=%d pool=%d base=%d ppss=%d cpss=%d poolpss=%d\n",
           $arm, $ppriv, $cpriv, $n, $cshcl, $ppriv + $cpriv, $base_priv,
           $ppss, $cpss, $ppss + $cpss;
}

# ---- is File::Raw's data() actually zero-copy? -----------------------------
#
# Phase 05 depends on the answer. If data() copies, the mmap arm can never win
# and the whole container design needs its own mapping rather than a borrowed
# scalar.

sub mmap_probe {
    require File::Raw;
    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $path = "$dir/probe.bin";
    my $MB   = 128;
    open my $fh, '>:raw', $path or die $!;
    print $fh ("\xAB" x 1048576) for 1 .. $MB;
    close $fh;

    my ($p0) = mem_kib();
    my $m    = File::Raw::mmap_open($path);
    my ($p1) = mem_kib();
    my $ref  = \($m->data);
    my ($p2) = mem_kib();
    my $len  = length $$ref;
    my ($p3) = mem_kib();
    my $sink = 0;
    for (my $i = 0; $i < $len; $i += 4096) { $sink += ord substr($$ref, $i, 1) }
    my ($p4) = mem_kib();

    printf "mmap probe over a %d MiB file (figures are KiB of private):\n", $MB;
    printf "  after mmap_open       %+8d\n", $p1 - $p0;
    printf "  after data()          %+8d   <- a copy would show ~%d here\n",
           $p2 - $p1, $MB * 1024;
    printf "  after length()        %+8d\n", $p3 - $p2;
    printf "  after touching pages  %+8d   <- read faults, should stay SHARED\n",
           $p4 - $p3;
    my ($pd, $sc) = mem_kib();
    printf "  final shared_clean    %8d\n", $sc;
    printf "  VERDICT: data() is %s\n",
           ($p2 - $p1) > ($MB * 1024 * 0.5) ? 'A COPY - the design needs its own mmap'
                                            : 'zero-copy';
}

# ---- which kind of read dirties -------------------------------------------

sub run_dirtyby {
    my $data = build_data($OPT{leaves});
    my $nsec = 200;
    my $per  = int($OPT{leaves} / $nsec) || 1;
    my $random_key = sub {
        my $s = 1 + int rand $nsec;
        my $i = 1 + int rand $per;
        return "section$s.group" . int($i / 50) . ".key$i";
    };
    print "-- which read dirties (HoH, one child each) --\n";
    for my $mode (qw(none exists fetch copy pass)) {
        pipe(my $rfh, my $wfh) or die $!;
        my $pid = fork; die unless defined $pid;
        if ($pid == 0) {
            close $rfh;
            my ($before) = mem_kib();
            my $sink = 0;
            my $take = sub { $sink += length $_[0] };
            for (1 .. $OPT{reads}) {
                my @p = split /\./, $random_key->();
                next if $mode eq 'none';
                my $c = $data;
                if ($mode eq 'exists') {
                    my $last = pop @p;
                    $c = $c->{$_} for @p;
                    $sink++ if exists $c->{$last};
                }
                else {
                    $c = $c->{$_} for @p;
                    if    ($mode eq 'fetch') { $sink += length $c }
                    elsif ($mode eq 'copy')  { my $cp = $c; $sink += length $cp }
                    elsif ($mode eq 'pass')  { $take->($c) }
                }
            }
            my ($after) = mem_kib();
            print $wfh +($after - $before), "\n";
            close $wfh; exit 0;
        }
        close $wfh;
        chomp(my $d = <$rfh> // 0); close $rfh; waitpid $pid, 0;
        printf "  %-7s child private grew by %8d KiB\n", $mode, $d;
    }
}

# ---- main ------------------------------------------------------------------

if ($OPT{arm}) { run_arm($OPT{arm}); exit 0 }

printf "platform: %s   %s\n", $^O,
       $LINUX ? '/proc/self/smaps_rollup - AUTHORITATIVE'
              : 'no smaps_rollup - ADVISORY only, do not gate on these';
printf "perl %vd, workers %d, reads %d, leaves %d\n\n",
       $^V, $OPT{workers}, $OPT{reads}, $OPT{leaves};

probe_unit();
print "\n";
if    ($OPT{unit})      { exit 0 }
elsif ($OPT{mmapprobe}) { mmap_probe(); exit 0 }
elsif ($OPT{dirtyby})   { run_dirtyby(); exit 0 }

# Each arm in a fresh process, so no arm's parent holds another arm's data.
my %row;
for my $arm (qw(hoh json flat mmap)) {
    my @cmd = ($^X, (map { "-I$_" } @INC[0 .. 3]), $0,
               "--arm=$arm", "--workers=$OPT{workers}",
               "--reads=$OPT{reads}", "--leaves=$OPT{leaves}");
    open my $ph, '-|', @cmd or die "cannot re-exec: $!";
    while (<$ph>) {
        next unless /^RESULT (\w+) parent=(\d+) children=(\d+) nkids=(\d+) shared=(\d+) pool=(\d+) base=(\d+) ppss=(\d+) cpss=(\d+) poolpss=(\d+)/;
        $row{$1} = { parent => $2, children => $3, nkids => $4, shared => $5,
                     pool => $6, poolpss => $10 };
        printf "%-5s dirty: parent %8d children %8d   POOL_DIRTY %8d   POOL_PSS %8d\n",
               $1, $2, $3, $6, $10;
    }
    close $ph;
}

print "\n== POOL PSS, KiB, lower is better - this is the gate metric ==\n";
printf "  %-5s %9d   (pool private_dirty %9d)\n",
       $_->[0], $row{$_->[0]}{poolpss}, $row{$_->[0]}{pool}
    for sort { $a->[1] <=> $b->[1] }
        map { [$_, $row{$_}{poolpss}] } keys %row;

if ($row{hoh} && $row{mmap}) {
    printf "\ngate 2  mmap against hoh   %.2fx %s\n",
        $row{hoh}{poolpss} / ($row{mmap}{poolpss} || 1),
        $row{mmap}{poolpss} < $row{hoh}{poolpss}
            ? '(PASS)' : '(FAIL - mmap adds nothing)';
}
if ($row{flat} && $row{mmap}) {
    printf "gate 3  mmap against flat  %.2fx %s\n",
        $row{flat}{poolpss} / ($row{mmap}{poolpss} || 1),
        $row{mmap}{poolpss} < $row{flat}{poolpss}
            ? '(mmap wins on RSS too)'
            : '(records: the pitch is the other four claims, not RSS)';
}
