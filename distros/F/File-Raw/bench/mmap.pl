#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw;

my $tmpdir  = tempdir(CLEANUP => 1);
my $content = "x" x 100_000;   # 100KB - good size for mmap benefit

my $mmap_file = "$tmpdir/mmap.txt";
File::Raw::spew($mmap_file, $content);

print "=== Memory-Mapped File Benchmarks ===\n\n";

print "--- read 100KB: mmap vs slurp vs Perl ---\n";
cmpthese(-3, {
    'File::Raw::mmap_open' => sub {
        my $m = File::Raw::mmap_open($mmap_file);
        my $d = $m->data;
        $m->close;
    },
    'File::Raw::slurp'     => sub {
        File::Raw::slurp($mmap_file);
    },
    'Perl open/readline'    => sub {
        open my $fh, '<', $mmap_file or die $!;
        local $/;
        my $c = <$fh>;
        close $fh;
    },
});

print "\n--- repeated reads same file (cache-warm): mmap vs slurp ---\n";
my $m = File::Raw::mmap_open($mmap_file);
cmpthese(-3, {
    'mmap (keep-open)' => sub {
        my $d = $m->data;
        my $len = length($d);
    },
    'File::Raw::slurp' => sub {
        my $c = File::Raw::slurp($mmap_file);
        my $len = length($c);
    },
    'Perl open/readline' => sub {
        open my $fh, '<', $mmap_file or die $!;
        local $/;
        my $c = <$fh>;
        my $len = length($c);
        close $fh;
    },
});
$m->close;
