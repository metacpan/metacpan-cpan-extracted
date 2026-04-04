#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('File::Raw');

my $tmpdir = tempdir(CLEANUP => 1);

# ============================================
# Basic mmap tests
# ============================================

subtest 'mmap basic read' => sub {
    my $file = "$tmpdir/mmap_basic.txt";
    my $content = "Memory mapped file content\nLine 2\nLine 3";

    File::Raw::spew($file, $content);

    my $mmap = File::Raw::mmap_open($file);
    ok($mmap, 'mmap_open returns object');
    isa_ok($mmap, 'File::Raw::mmap', 'correct class');

    my $data = $mmap->data;
    is($data, $content, 'mmap data matches file content');

    $mmap->close;
    pass('mmap close succeeded');
};

# ============================================
# mmap with various sizes
# ============================================

subtest 'mmap small file' => sub {
    my $file = "$tmpdir/mmap_small.txt";
    File::Raw::spew($file, "x");

    my $mmap = File::Raw::mmap_open($file);
    ok($mmap, 'mmap small file');
    is($mmap->data, "x", 'single byte content');
    $mmap->close;
};

subtest 'mmap medium file' => sub {
    my $file = "$tmpdir/mmap_medium.txt";
    my $content = "x" x 10000;  # 10KB
    File::Raw::spew($file, $content);

    my $mmap = File::Raw::mmap_open($file);
    ok($mmap, 'mmap medium file');
    is(length($mmap->data), 10000, 'medium file length');
    $mmap->close;
};

subtest 'mmap large file' => sub {
    my $file = "$tmpdir/mmap_large.txt";
    my $content = "x" x (1024 * 100);  # 100KB
    File::Raw::spew($file, $content);

    my $mmap = File::Raw::mmap_open($file);
    ok($mmap, 'mmap large file');
    is(length($mmap->data), 1024 * 100, 'large file length');
    $mmap->close;
};

# ============================================
# mmap empty file (should fail gracefully)
# ============================================

subtest 'mmap empty file' => sub {
    my $file = "$tmpdir/mmap_empty.txt";
    File::Raw::spew($file, "");

    my $mmap = File::Raw::mmap_open($file);
    ok(!defined($mmap), 'mmap empty file returns undef');
};

# ============================================
# mmap nonexistent file
# ============================================

subtest 'mmap nonexistent file' => sub {
    my $mmap = File::Raw::mmap_open("$tmpdir/nonexistent_mmap.txt");
    ok(!defined($mmap), 'mmap nonexistent returns undef');
};

# ============================================
# Writable mmap
# ============================================

subtest 'writable mmap' => sub {
    my $file = "$tmpdir/mmap_writable.txt";
    my $original = "Original content here";
    File::Raw::spew($file, $original);

    # Open for writing
    my $mmap = File::Raw::mmap_open($file, 1);  # 1 = writable
    ok($mmap, 'writable mmap opened');

    my $data = $mmap->data;
    is($data, $original, 'initial data correct');

    # Sync (just verify it doesn't crash)
    $mmap->sync;
    pass('sync completed');

    $mmap->close;
};

# ============================================
# Multiple mmaps to same file
# ============================================

subtest 'multiple mmaps same file' => sub {
    my $file = "$tmpdir/mmap_multi.txt";
    File::Raw::spew($file, "shared content");

    my $mmap1 = File::Raw::mmap_open($file);
    my $mmap2 = File::Raw::mmap_open($file);

    ok($mmap1 && $mmap2, 'both mmaps opened');
    is($mmap1->data, $mmap2->data, 'both see same content');

    $mmap1->close;
    is($mmap2->data, "shared content", 'mmap2 still works after mmap1 closed');
    $mmap2->close;
};

# ============================================
# mmap with binary content
# ============================================

subtest 'mmap binary content' => sub {
    my $file = "$tmpdir/mmap_binary.dat";
    my $binary = join('', map { chr($_) } 0..255);
    File::Raw::spew($file, $binary);

    my $mmap = File::Raw::mmap_open($file);
    ok($mmap, 'mmap binary file');

    my $data = $mmap->data;
    is(length($data), 256, 'binary length correct');
    is($data, $binary, 'binary content matches');

    $mmap->close;
};

# ============================================
# mmap data access
# ============================================

subtest 'mmap data access' => sub {
    my $file = "$tmpdir/mmap_access.txt";
    File::Raw::spew($file, "access test content");

    my $mmap = File::Raw::mmap_open($file);
    my $data = $mmap->data;

    # Verify data is correct
    is($data, "access test content", 'mmap data is accessible');
    ok(defined($data), 'mmap data is defined');

    $mmap->close;
};

# ============================================
# mmap close multiple times (should be safe)
# ============================================

subtest 'mmap double close' => sub {
    my $file = "$tmpdir/mmap_double.txt";
    File::Raw::spew($file, "double close test");

    my $mmap = File::Raw::mmap_open($file);
    $mmap->close;
    $mmap->close;  # Should not crash
    pass('double close is safe');
};

# ============================================
# mmap with special file content
# ============================================

subtest 'mmap special content' => sub {
    my $file = "$tmpdir/mmap_special.txt";
    my $content = "line1\nline2\twithtab\r\nwindows\n\0nullbyte";
    File::Raw::spew($file, $content);

    my $mmap = File::Raw::mmap_open($file);
    is($mmap->data, $content, 'special characters preserved');
    $mmap->close;
};

# ============================================
# Compare mmap vs slurp content
# ============================================

subtest 'mmap vs slurp' => sub {
    my $file = "$tmpdir/mmap_vs_slurp.txt";
    my $content = "Compare mmap and slurp\n" x 100;
    File::Raw::spew($file, $content);

    my $slurped = File::Raw::slurp($file);
    my $mmap = File::Raw::mmap_open($file);
    my $mapped = $mmap->data;

    is($mapped, $slurped, 'mmap and slurp return same content');
    $mmap->close;
};

done_testing();
