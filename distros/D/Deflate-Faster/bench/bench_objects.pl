#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use FindBin '$Bin';
use lib "$Bin/../blib/lib", "$Bin/../blib/arch", "$Bin";

use Deflate::Faster;
use Gzip::Libdeflate;
use BenchPayloads qw(make_payloads);

print "Deflate::Faster vs Gzip::Libdeflate (Pre-created Objects Only)\n";
print "============================================================\n\n";

sub run_bench {
    my ($label, $target_size) = @_;
    my @payloads = make_payloads($target_size);
    my $count = scalar(@payloads);
    my $mask = $count - 1;
    my $len = length($payloads[0]);

    print "\n", "=" x 60, "\n";
    printf("Payload: %s (%d bytes / %.1f KB, alternating %d distinct payloads)\n",
           $label, $len, $len / 1024, $count);
    print "=" x 60, "\n";

    # Pre-created objects
    my $df6 = Deflate::Faster->new();
    $df6->level(6);

    my $df1 = Deflate::Faster->new();
    $df1->level(1);

    my $gl6 = Gzip::Libdeflate->new(level => 6);
    my $gl1 = Gzip::Libdeflate->new(level => 1);

    # Pre-compress sample payloads for decompression benchmark
    my @gz_df6 = map { $df6->zip($_) } @payloads;
    my @gz_gl6 = map { $gl6->compress($_) } @payloads;

    # Sanity checks
    for my $i (0..$#payloads) {
        die "Mismatch" unless $df6->unzip($gz_gl6[$i]) eq $payloads[$i];
        die "Mismatch" unless $gl6->decompress($gz_df6[$i]) eq $payloads[$i];
    }

    # 1. Compression
    print "\n--- 1. Compression (pre-created objects) ---\n";
    my ($c_df6, $c_df1, $c_gl6, $c_gl1) = (0, 0, 0, 0);
    cmpthese(-1.5, {
        "Deflate::Faster (lvl 6)"   => sub { $df6->zip($payloads[$c_df6++ & $mask]) },
        "Deflate::Faster (lvl 1)"   => sub { $df1->zip($payloads[$c_df1++ & $mask]) },
        "Gzip::Libdeflate (lvl 6)"  => sub { $gl6->compress($payloads[$c_gl6++ & $mask]) },
        "Gzip::Libdeflate (lvl 1)"  => sub { $gl1->compress($payloads[$c_gl1++ & $mask]) },
    });

    # 2. Decompression
    print "\n--- 2. Decompression (pre-created objects) ---\n";
    my ($d_df, $d_gl) = (0, 0);
    cmpthese(-1.5, {
        "Deflate::Faster"   => sub { $df6->unzip($gz_df6[$d_df++ & $mask]) },
        "Gzip::Libdeflate"  => sub { $gl6->decompress($gz_gl6[$d_gl++ & $mask]) },
    });

    # 3. Roundtrip
    print "\n--- 3. Roundtrip (pre-created objects) ---\n";
    my ($r_df6, $r_df1, $r_gl6, $r_gl1) = (0, 0, 0, 0);
    cmpthese(-1.5, {
        "Deflate::Faster (lvl 6)"   => sub { my $d = $payloads[$r_df6++ & $mask]; $df6->unzip($df6->zip($d)) },
        "Deflate::Faster (lvl 1)"   => sub { my $d = $payloads[$r_df1++ & $mask]; $df1->unzip($df1->zip($d)) },
        "Gzip::Libdeflate (lvl 6)"  => sub { my $d = $payloads[$r_gl6++ & $mask]; $gl6->decompress($gl6->compress($d)) },
        "Gzip::Libdeflate (lvl 1)"  => sub { my $d = $payloads[$r_gl1++ & $mask]; $gl1->decompress($gl1->compress($d)) },
    });
}

run_bench("Small string (72 bytes)", 72);
run_bench("Medium text (2 KB)", 2048);
run_bench("Large text (100 KB)", 102400);
run_bench("Huge text (1 MB)", 1048576);
