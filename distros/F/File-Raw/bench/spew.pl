#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw qw(import);

my $tmpdir = tempdir(CLEANUP => 1);

my $small_content  = "Hello, World!\n";
my $medium_content = "x" x 10_000;
my $large_content  = "x" x 1_000_000;

my $out = "$tmpdir/out.txt";

print "=== Spew Benchmarks ===\n\n";

print "--- small file (14 bytes) ---\n";
cmpthese(-3, {
    'File::Raw::spew'      => sub { File::Raw::spew($out, $small_content) },
    'file_spew (custom op)' => sub { file_spew($out, $small_content) },
    'Perl open/print'       => sub {
        open my $fh, '>', $out or die $!;
        print $fh $small_content;
        close $fh;
    },
    'Perl open/syswrite'    => sub {
        open my $fh, '>', $out or die $!;
        syswrite $fh, $small_content;
        close $fh;
    },
});

print "\n--- medium file (10KB) ---\n";
cmpthese(-3, {
    'File::Raw::spew'      => sub { File::Raw::spew($out, $medium_content) },
    'file_spew (custom op)' => sub { file_spew($out, $medium_content) },
    'Perl open/print'       => sub {
        open my $fh, '>', $out or die $!;
        print $fh $medium_content;
        close $fh;
    },
    'Perl open/syswrite'    => sub {
        open my $fh, '>', $out or die $!;
        syswrite $fh, $medium_content;
        close $fh;
    },
});

print "\n--- large file (1MB) ---\n";
cmpthese(-3, {
    'File::Raw::spew'      => sub { File::Raw::spew($out, $large_content) },
    'file_spew (custom op)' => sub { file_spew($out, $large_content) },
    'Perl open/print'       => sub {
        open my $fh, '>', $out or die $!;
        print $fh $large_content;
        close $fh;
    },
    'Perl open/syswrite'    => sub {
        open my $fh, '>', $out or die $!;
        syswrite $fh, $large_content;
        close $fh;
    },
});

print "\n--- append (small) ---\n";
my $append_file = "$tmpdir/append.txt";
File::Raw::spew($append_file, "");
cmpthese(-3, {
    'File::Raw::append'  => sub { File::Raw::append($append_file, "line\n") },
    'Perl open/append'    => sub {
        open my $fh, '>>', $append_file or die $!;
        print $fh "line\n";
        close $fh;
    },
});
