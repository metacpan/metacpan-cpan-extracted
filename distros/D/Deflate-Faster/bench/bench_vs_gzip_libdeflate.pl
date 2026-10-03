#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use FindBin '$Bin';
use lib "$Bin/../blib/lib", "$Bin/../blib/arch", "$Bin";

use Deflate::Faster qw(gzip gunzip);
use Gzip::Libdeflate;
use BenchPayloads qw(make_payloads);

print "Deflate::Faster vs Gzip::Libdeflate Benchmark Suite\n";
print "===================================================\n\n";

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

    my $gl6 = Gzip::Libdeflate->new(level => 6);
    my $gl1 = Gzip::Libdeflate->new(level => 1);
    my $df = Deflate::Faster->new();
    $df->level(6);

    my @gz_df = map { gzip($_) } @payloads;
    my @gz_gl = map { $gl6->compress($_) } @payloads;

    # 1. Compression
    print "\n--- 1. Compression ---\n";
    my ($c_proc6, $c_proc1, $c_oo6, $c_gl6, $c_gl1, $c_gl_new) = (0, 0, 0, 0, 0, 0);
    cmpthese(-2, {
        "Deflate::Faster (proc, lvl 6)" => sub { gzip($payloads[$c_proc6++ & $mask]) },
        "Deflate::Faster (proc, lvl 1)" => sub { gzip($payloads[$c_proc1++ & $mask], 1) },
        "Deflate::Faster (OO, lvl 6)"   => sub { $df->zip($payloads[$c_oo6++ & $mask]) },
        "Gzip::Libdeflate (pre-alloc, lvl 6)" => sub { $gl6->compress($payloads[$c_gl6++ & $mask]) },
        "Gzip::Libdeflate (pre-alloc, lvl 1)" => sub { $gl1->compress($payloads[$c_gl1++ & $mask]) },
        "Gzip::Libdeflate (new/call)"         => sub { Gzip::Libdeflate->new(level => 6)->compress($payloads[$c_gl_new++ & $mask]) },
    });

    # 2. Decompression
    print "\n--- 2. Decompression ---\n";
    my ($d_proc, $d_oo, $d_gl_pre, $d_gl_new) = (0, 0, 0, 0);
    cmpthese(-2, {
        "Deflate::Faster (proc)"        => sub { gunzip($gz_df[$d_proc++ & $mask]) },
        "Deflate::Faster (OO)"          => sub { $df->unzip($gz_df[$d_oo++ & $mask]) },
        "Gzip::Libdeflate (pre-alloc)"  => sub { $gl6->decompress($gz_gl[$d_gl_pre++ & $mask]) },
        "Gzip::Libdeflate (new/call)"   => sub { Gzip::Libdeflate->new()->decompress($gz_gl[$d_gl_new++ & $mask]) },
    });

    # 3. Roundtrip
    print "\n--- 3. Roundtrip ---\n";
    my ($r_proc6, $r_proc1, $r_gl6, $r_gl1, $r_gl_new) = (0, 0, 0, 0, 0);
    cmpthese(-2, {
        "Deflate::Faster (proc, lvl 6)" => sub { my $d = $payloads[$r_proc6++ & $mask]; gunzip(gzip($d)) },
        "Deflate::Faster (proc, lvl 1)" => sub { my $d = $payloads[$r_proc1++ & $mask]; gunzip(gzip($d, 1)) },
        "Gzip::Libdeflate (pre-alloc, lvl 6)" => sub { my $d = $payloads[$r_gl6++ & $mask]; $gl6->decompress($gl6->compress($d)) },
        "Gzip::Libdeflate (pre-alloc, lvl 1)" => sub { my $d = $payloads[$r_gl1++ & $mask]; $gl1->decompress($gl1->compress($d)) },
        "Gzip::Libdeflate (new/call)"         => sub { my $d = $payloads[$r_gl_new++ & $mask]; my $o = Gzip::Libdeflate->new(level => 6); $o->decompress($o->compress($d)) },
    });
}

run_bench("Small string (72 bytes)", 72);
run_bench("Medium text (2 KB)", 2048);
run_bench("Large text (100 KB)", 102400);
run_bench("Huge text (1 MB)", 1048576);
