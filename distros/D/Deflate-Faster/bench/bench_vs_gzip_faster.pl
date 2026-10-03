#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use FindBin '$Bin';
use lib "$Bin/../blib/lib", "$Bin/../blib/arch", "$Bin";

use Deflate::Faster qw(gzip gunzip deflate inflate);
use BenchPayloads qw(make_payloads);

my $have_gf = eval { require Gzip::Faster; 1 };
my $have_crz = eval { require Compress::Raw::Zlib; 1 };

print "Deflate::Faster Benchmark Suite\n";
print "==============================\n";
print "Comparing Deflate::Faster against ",
      ($have_gf ? "Gzip::Faster" : ""),
      ($have_gf && $have_crz ? " and " : ""),
      ($have_crz ? "Compress::Raw::Zlib" : ""), "\n\n";

sub run_benchmark {
    my ($label, $target_size) = @_;
    my @payloads = make_payloads($target_size);
    my $count = scalar(@payloads);
    my $mask = $count - 1;
    my $len = length($payloads[0]);

    print "\n", "=" x 60, "\n";
    printf("Payload: %s (%d bytes / %.1f KB, alternating %d distinct payloads)\n",
           $label, $len, $len / 1024, $count);
    print "=" x 60, "\n";

    # Pre-compress all payloads with each engine
    my @df6_gz = map { gzip($_) } @payloads;
    my @df1_gz = map { gzip($_, 1) } @payloads;
    my @gf_gz  = $have_gf ? (map { Gzip::Faster::gzip($_) } @payloads) : @df6_gz;

    my $avg_df6 = 0; $avg_df6 += length($_) for @df6_gz; $avg_df6 /= $count;
    my $avg_df1 = 0; $avg_df1 += length($_) for @df1_gz; $avg_df1 /= $count;
    my $avg_gf  = 0; $avg_gf  += length($_) for @gf_gz;  $avg_gf  /= $count;

    printf("Avg compressed sizes: Deflate::Faster(lvl 6)=%.0f, Deflate::Faster(lvl 1)=%.0f",
           $avg_df6, $avg_df1);
    if ($have_gf) {
        printf(", Gzip::Faster=%.0f", $avg_gf);
    }
    print "\n\n";

    # --- Compression Benchmark ---
    print "--- 1. Compression ---\n";
    my ($c_idx_df6, $c_idx_df1, $c_idx_gf) = (0, 0, 0);
    my %comp_targets = (
        'Deflate::Faster (lvl 6)' => sub { gzip($payloads[$c_idx_df6++ & $mask]) },
        'Deflate::Faster (lvl 1)' => sub { gzip($payloads[$c_idx_df1++ & $mask], 1) },
    );
    if ($have_gf) {
        $comp_targets{'Gzip::Faster'} = sub { Gzip::Faster::gzip($payloads[$c_idx_gf++ & $mask]) };
    }
    cmpthese(-2, \%comp_targets);

    # --- Decompression Benchmark ---
    print "\n--- 2. Decompression ---\n";
    my ($d_idx_df, $d_idx_gf) = (0, 0);
    my %decomp_targets = (
        'Deflate::Faster' => sub { gunzip($df6_gz[$d_idx_df++ & $mask]) },
    );
    if ($have_gf) {
        $decomp_targets{'Gzip::Faster'} = sub { Gzip::Faster::gunzip($gf_gz[$d_idx_gf++ & $mask]) };
    }
    cmpthese(-2, \%decomp_targets);

    # --- Roundtrip Benchmark ---
    print "\n--- 3. Roundtrip (compress + decompress) ---\n";
    my ($r_idx_df6, $r_idx_df1, $r_idx_gf) = (0, 0, 0);
    my %rt_targets = (
        'Deflate::Faster (lvl 6)' => sub { my $d = $payloads[$r_idx_df6++ & $mask]; gunzip(gzip($d)) },
        'Deflate::Faster (lvl 1)' => sub { my $d = $payloads[$r_idx_df1++ & $mask]; gunzip(gzip($d, 1)) },
    );
    if ($have_gf) {
        $rt_targets{'Gzip::Faster'} = sub { my $d = $payloads[$r_idx_gf++ & $mask]; Gzip::Faster::gunzip(Gzip::Faster::gzip($d)) };
    }
    cmpthese(-2, \%rt_targets);
}

run_benchmark("Small string (72 bytes)", 72);
run_benchmark("Medium text (2 KB)", 2048);
run_benchmark("Large text (100 KB)", 102400);
run_benchmark("Huge text (1 MB)", 1048576);
