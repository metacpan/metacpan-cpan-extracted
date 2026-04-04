#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('File::Raw');

my $tmpdir = tempdir(CLEANUP => 1);

# ============================================
# Basic iterator tests
# ============================================

subtest 'iterator basic usage' => sub {
    my $file = "$tmpdir/iter_basic.txt";
    File::Raw::spew($file, "line1\nline2\nline3");

    my $iter = File::Raw::lines_iter($file);
    ok($iter, 'iterator created');
    isa_ok($iter, 'File::Raw::lines', 'correct class');

    ok(!$iter->eof, 'not eof initially');

    is($iter->next, 'line1', 'first line');
    is($iter->next, 'line2', 'second line');
    is($iter->next, 'line3', 'third line');

    ok($iter->eof, 'eof after all lines');
    $iter->close;
};

# ============================================
# Iterator with empty lines
# ============================================

subtest 'iterator empty lines' => sub {
    my $file = "$tmpdir/iter_empty_lines.txt";
    File::Raw::spew($file, "first\n\nsecond\n\n\nthird");

    my $iter = File::Raw::lines_iter($file);
    my @lines;
    while (!$iter->eof) {
        push @lines, $iter->next;
    }
    $iter->close;

    is(scalar(@lines), 6, 'correct number of lines including empty');
    is($lines[0], 'first', 'first line');
    is($lines[1], '', 'first empty line');
    is($lines[2], 'second', 'second line');
    is($lines[3], '', 'second empty line');
    is($lines[4], '', 'third empty line');
    is($lines[5], 'third', 'third line');
};

# ============================================
# Iterator with single line (no newline)
# ============================================

subtest 'iterator single line no newline' => sub {
    my $file = "$tmpdir/iter_single.txt";
    File::Raw::spew($file, "single line no newline");

    my $iter = File::Raw::lines_iter($file);
    is($iter->next, 'single line no newline', 'single line read');
    ok($iter->eof, 'eof after single line');
    $iter->close;
};

# ============================================
# Iterator with single line (with newline)
# ============================================

subtest 'iterator single line with newline' => sub {
    my $file = "$tmpdir/iter_single_nl.txt";
    File::Raw::spew($file, "single line with newline\n");

    my $iter = File::Raw::lines_iter($file);
    is($iter->next, 'single line with newline', 'line without trailing newline');
    # After reading last line, need to try next read to trigger eof
    my $extra = $iter->next;
    ok($iter->eof, 'eof after exhausted');
    $iter->close;
};

# ============================================
# Iterator with empty file
# ============================================

subtest 'iterator empty file' => sub {
    my $file = "$tmpdir/iter_empty.txt";
    File::Raw::spew($file, "");

    my $iter = File::Raw::lines_iter($file);
    ok($iter, 'iterator created for empty file');
    # Need to try reading to discover eof
    my $line = $iter->next;
    ok($iter->eof, 'eof after read attempt on empty file');
    $iter->close;
};

# ============================================
# Iterator on nonexistent file
# ============================================

subtest 'iterator nonexistent file' => sub {
    my $iter = File::Raw::lines_iter("$tmpdir/nonexistent_iter.txt");
    ok(!defined($iter), 'iterator for nonexistent file is undef');
};

# ============================================
# Multiple iterators on same file
# ============================================

subtest 'multiple iterators same file' => sub {
    my $file = "$tmpdir/iter_multi.txt";
    File::Raw::spew($file, "line1\nline2\nline3\nline4\nline5");

    my $iter1 = File::Raw::lines_iter($file);
    my $iter2 = File::Raw::lines_iter($file);

    ok($iter1 && $iter2, 'both iterators created');

    # Interleave reads
    is($iter1->next, 'line1', 'iter1 first');
    is($iter2->next, 'line1', 'iter2 first');
    is($iter1->next, 'line2', 'iter1 second');
    is($iter2->next, 'line2', 'iter2 second');

    $iter1->close;
    is($iter2->next, 'line3', 'iter2 still works after iter1 closed');
    $iter2->close;
};

# ============================================
# Iterator with long lines
# ============================================

subtest 'iterator long lines' => sub {
    my $file = "$tmpdir/iter_long.txt";
    my $long_line = "x" x 100000;  # 100KB line
    File::Raw::spew($file, "short\n$long_line\nshort again");

    my $iter = File::Raw::lines_iter($file);
    is($iter->next, 'short', 'short line before long');
    my $long = $iter->next;
    is(length($long), 100000, 'long line length correct');
    is($iter->next, 'short again', 'short line after long');
    $iter->close;
};

# ============================================
# Iterator close multiple times
# ============================================

subtest 'iterator double close' => sub {
    my $file = "$tmpdir/iter_dblclose.txt";
    File::Raw::spew($file, "content");

    my $iter = File::Raw::lines_iter($file);
    $iter->next;
    $iter->close;
    $iter->close;  # Should not crash
    pass('double close is safe');
};

# ============================================
# Iterator with binary content
# ============================================

subtest 'iterator binary content' => sub {
    my $file = "$tmpdir/iter_binary.txt";
    # Binary content with embedded newlines
    my $line1 = join('', map { chr($_) } 0..9);
    my $line2 = join('', map { chr($_) } 100..110);
    File::Raw::spew($file, "$line1\n$line2");

    my $iter = File::Raw::lines_iter($file);
    my $read1 = $iter->next;
    my $read2 = $iter->next;
    $iter->close;

    is(length($read1), 10, 'binary line 1 length');
    is(length($read2), 11, 'binary line 2 length');
};

# ============================================
# Iterator with tabs and special chars
# ============================================

subtest 'iterator special characters' => sub {
    my $file = "$tmpdir/iter_special.txt";
    File::Raw::spew($file, "with\ttab\nwith spaces   \n\$pecial \@chars");

    my $iter = File::Raw::lines_iter($file);
    is($iter->next, "with\ttab", 'tab preserved');
    is($iter->next, 'with spaces   ', 'trailing spaces preserved');
    is($iter->next, '$pecial @chars', 'special chars preserved');
    $iter->close;
};

# ============================================
# Iterator line count
# ============================================

subtest 'iterator counts correctly' => sub {
    my $file = "$tmpdir/iter_count.txt";
    my @lines = map { "Line $_" } 1..100;
    File::Raw::spew($file, join("\n", @lines));

    my $iter = File::Raw::lines_iter($file);
    my $count = 0;
    while (!$iter->eof) {
        $iter->next;
        $count++;
    }
    $iter->close;

    is($count, 100, 'iterator counts all 100 lines');
};

# ============================================
# Compare iterator vs lines()
# ============================================

subtest 'iterator vs lines' => sub {
    my $file = "$tmpdir/iter_vs_lines.txt";
    File::Raw::spew($file, "one\ntwo\nthree\nfour\nfive");

    # Using lines()
    my $lines_result = File::Raw::lines($file);

    # Using iterator
    my $iter = File::Raw::lines_iter($file);
    my @iter_result;
    while (!$iter->eof) {
        push @iter_result, $iter->next;
    }
    $iter->close;

    is_deeply(\@iter_result, $lines_result, 'iterator and lines() return same');
};

# ============================================
# Iterator early termination
# ============================================

subtest 'iterator early termination' => sub {
    my $file = "$tmpdir/iter_early.txt";
    File::Raw::spew($file, join("\n", 1..1000));

    my $iter = File::Raw::lines_iter($file);
    my @first_ten;
    for (1..10) {
        push @first_ten, $iter->next;
    }
    $iter->close;

    is(scalar(@first_ten), 10, 'got first 10 lines');
    is($first_ten[0], '1', 'first line is 1');
    is($first_ten[9], '10', 'tenth line is 10');
};

# ============================================
# Iterator with Windows line endings
# ============================================

subtest 'iterator windows line endings' => sub {
    my $file = "$tmpdir/iter_windows.txt";
    # Note: file module handles \n, not \r\n, so \r will be part of line
    File::Raw::spew($file, "line1\r\nline2\r\nline3");

    my $iter = File::Raw::lines_iter($file);
    my $l1 = $iter->next;
    my $l2 = $iter->next;
    my $l3 = $iter->next;
    $iter->close;

    # Lines will include \r since we split on \n only
    is($l1, "line1\r", 'windows line 1 includes CR');
    is($l2, "line2\r", 'windows line 2 includes CR');
    is($l3, "line3", 'last line has no CR');
};

done_testing();
