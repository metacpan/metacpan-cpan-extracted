#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw qw(import);

my $tmpdir = tempdir(CLEANUP => 1);

my $lines_file = "$tmpdir/lines.txt";
File::Raw::spew($lines_file, join("\n", map { "Line number $_" } 1..1000));

my $big_lines_file = "$tmpdir/big_lines.txt";
File::Raw::spew($big_lines_file, join("\n", map { "Line number $_" } 1..100_000));

print "=== Line Processing Benchmarks ===\n\n";

print "--- lines() - 1,000 lines ---\n";
cmpthese(-3, {
    'File::Raw::lines'  => sub { File::Raw::lines($lines_file) },
    'file_lines (custom op)' => sub { file_lines($lines_file) },
    'Perl readline'      => sub {
        open my $fh, '<', $lines_file or die $!;
        my @lines = <$fh>;
        chomp @lines;
        close $fh;
    },
});

print "\n--- lines() - 100,000 lines ---\n";
cmpthese(-3, {
    'File::Raw::lines'  => sub { File::Raw::lines($big_lines_file) },
    'Perl readline'      => sub {
        open my $fh, '<', $big_lines_file or die $!;
        my @lines = <$fh>;
        chomp @lines;
        close $fh;
    },
});

print "\n--- each_line() callback vs while readline - 1,000 lines ---\n";
cmpthese(-3, {
    'File::Raw::each_line' => sub {
        my $count = 0;
        File::Raw::each_line($lines_file, sub { $count++ });
    },
    'Perl while readline'   => sub {
        my $count = 0;
        open my $fh, '<', $lines_file or die $!;
        while (<$fh>) { $count++ }
        close $fh;
    },
});

print "\n--- lines_iter() vs while readline - 1,000 lines ---\n";
cmpthese(-3, {
    'File::Raw::lines_iter' => sub {
        my $iter = File::Raw::lines_iter($lines_file);
        my $count = 0;
        while (!$iter->eof) {
            $iter->next;
            $count++;
        }
        $iter->close;
    },
    'Perl while readline'    => sub {
        my $count = 0;
        open my $fh, '<', $lines_file or die $!;
        while (<$fh>) { $count++ }
        close $fh;
    },
});

print "\n--- count_lines() vs wc ---\n";
cmpthese(-3, {
    'File::Raw::count_lines' => sub { File::Raw::count_lines($lines_file) },
    'Perl while readline'     => sub {
        my $count = 0;
        open my $fh, '<', $lines_file or die $!;
        while (<$fh>) { $count++ }
        close $fh;
    },
});

print "\n--- head(10) vs manual readline ---\n";
cmpthese(-3, {
    'File::Raw::head'   => sub { File::Raw::head($lines_file, 10) },
    'Perl head-10'       => sub {
        open my $fh, '<', $lines_file or die $!;
        my @head;
        while (<$fh>) { chomp; push @head, $_; last if @head == 10 }
        close $fh;
    },
});
