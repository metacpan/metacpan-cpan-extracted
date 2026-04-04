#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw qw(import);

my $tmpdir = tempdir(CLEANUP => 1);

my $small_file  = "$tmpdir/small.txt";
my $medium_file = "$tmpdir/medium.txt";
my $large_file  = "$tmpdir/large.txt";

File::Raw::spew($small_file,  "Hello, World!\n");
File::Raw::spew($medium_file, "x" x 10_000);
File::Raw::spew($large_file,  "x" x 1_000_000);

print "=== Slurp Benchmarks ===\n\n";

print "--- small file (14 bytes) ---\n";
cmpthese(-3, {
    'File::Raw::slurp'      => sub { File::Raw::slurp($small_file) },
    'file_slurp (custom op)' => sub { file_slurp($small_file) },
    'Perl open/readline'     => sub {
        open my $fh, '<', $small_file or die $!;
        local $/;
        my $c = <$fh>;
        close $fh;
    },
    'Perl open/sysread'      => sub {
        open my $fh, '<', $small_file or die $!;
        my $c;
        sysread $fh, $c, -s $small_file;
        close $fh;
    },
});

print "\n--- medium file (10KB) ---\n";
cmpthese(-3, {
    'File::Raw::slurp'      => sub { File::Raw::slurp($medium_file) },
    'file_slurp (custom op)' => sub { file_slurp($medium_file) },
    'Perl open/readline'     => sub {
        open my $fh, '<', $medium_file or die $!;
        local $/;
        my $c = <$fh>;
        close $fh;
    },
    'Perl open/sysread'      => sub {
        open my $fh, '<', $medium_file or die $!;
        my $c;
        sysread $fh, $c, -s $medium_file;
        close $fh;
    },
});

print "\n--- large file (1MB) ---\n";
cmpthese(-3, {
    'File::Raw::slurp'      => sub { File::Raw::slurp($large_file) },
    'file_slurp (custom op)' => sub { file_slurp($large_file) },
    'Perl open/readline'     => sub {
        open my $fh, '<', $large_file or die $!;
        local $/;
        my $c = <$fh>;
        close $fh;
    },
    'Perl open/sysread'      => sub {
        open my $fh, '<', $large_file or die $!;
        my $c;
        sysread $fh, $c, -s $large_file;
        close $fh;
    },
});
