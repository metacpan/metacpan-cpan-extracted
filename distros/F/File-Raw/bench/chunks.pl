#!/usr/bin/env perl
#
# Pull reads: File::Raw::chunk_iter against core open/read.
#
# The question this answers is not "is the syscall faster" - both make
# one read(2) per chunk - but whether going through the XS surface and a
# fresh SV per chunk costs more than PerlIO's buffered read into a reused
# scalar. Run it before believing anything about performance in either
# direction.
#
#     perl -Mblib bench/chunks.pl [size_in_MiB] [chunk_bytes]

use strict;
use warnings;
use File::Raw;
use File::Temp qw(tempdir);
use Time::HiRes qw(time);

my $MiB    = shift || 256;
my $CHUNK  = shift || 65536;
my $ROUNDS = 3;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/bench.bin";

print "building a ${MiB} MiB file\n";
{
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    my $block = join '', map { chr($_ % 256) } 0 .. 65535;
    print $fh $block for 1 .. ($MiB * 16);
    close $fh;
}
my $bytes = -s $path;

sub perlio {
    open my $fh, '<:raw', $path or die "cannot open $path: $!";
    my ($total, $buf) = (0);
    while (my $n = read($fh, $buf, $CHUNK)) { $total += $n }
    close $fh;
    return $total;
}

sub chunk_iter {
    my $it = File::Raw::chunk_iter($path, size => $CHUNK)
        or die "cannot open $path: $!";
    my $total = 0;
    while (defined(my $c = $it->next)) { $total += length $c }
    $it->close;
    return $total;
}

sub chunk_iter_buf {
    my $it = File::Raw::chunk_iter($path, size => $CHUNK)
        or die "cannot open $path: $!";
    my ($total, $buf) = (0);
    while (my $n = $it->next($buf)) { $total += $n }
    $it->close;
    return $total;
}

sub timeit {
    my ($name, $code) = @_;
    my $best;
    for (1 .. $ROUNDS) {
        my $t0 = time;
        my $got = $code->();
        my $el  = time - $t0;
        die "$name read $got of $bytes bytes\n" unless $got == $bytes;
        $best = $el if !defined $best || $el < $best;
    }
    printf "%-14s %7.3f s   %7.1f MiB/s\n", $name, $best,
        ($bytes / (1024 * 1024)) / $best;
    return $best;
}

print "reading $bytes bytes in $CHUNK byte chunks, best of $ROUNDS\n\n";
my $a = timeit('open/read',       \&perlio);
my $b = timeit('chunk_iter',      \&chunk_iter);
my $c = timeit('chunk_iter buf',  \&chunk_iter_buf);
for my $r (['chunk_iter', $b], ['chunk_iter buf', $c]) {
    my ($name, $t) = @$r;
    printf "%-15s is %.2fx %s than open/read\n", $name,
        ($a > $t ? $a / $t : $t / $a), ($a > $t ? 'faster' : 'slower');
}
