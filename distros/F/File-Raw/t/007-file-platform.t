#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Config;

use_ok('File::Raw');

my $tmpdir = tempdir(CLEANUP => 1);
my $is_windows = $^O eq 'MSWin32';
my $is_unix = !$is_windows;

diag("Running on: $^O");
diag("Perl version: $]");

# ============================================
# Platform detection
# ============================================

subtest 'platform identification' => sub {
    ok(defined $^O, 'OS is defined');
    diag("Operating system: $^O");
};

# ============================================
# Path separator handling
# ============================================

subtest 'path separators' => sub {
    # Forward slashes work everywhere
    my $path1 = File::Raw::join('a', 'b', 'c');
    ok($path1 =~ m{a.b.c}, 'join produces path-like string');

    # Test dirname/basename with forward slashes
    is(File::Raw::basename('/path/to/file.txt'), 'file.txt', 'basename with forward slashes');
    is(File::Raw::dirname('/path/to/file.txt'), '/path/to', 'dirname with forward slashes');

    SKIP: {
        skip "Windows path tests", 2 unless $is_windows;

        # Windows should also handle backslashes
        is(File::Raw::basename('C:\\path\\to\\file.txt'), 'file.txt', 'basename with backslashes');
        is(File::Raw::dirname('C:\\path\\to\\file.txt'), 'C:\\path\\to', 'dirname with backslashes');
    }
};

# ============================================
# Symlink tests (Unix only)
# ============================================

SKIP: {
    skip "Symlink tests require Unix", 6 unless $is_unix;

    subtest 'symlinks' => sub {
        my $target = "$tmpdir/symlink_target.txt";
        my $link = "$tmpdir/symlink_link.txt";

        File::Raw::spew($target, "target content");

        SKIP: {
            skip "symlink not available", 5 unless eval { symlink($target, $link) };

            ok(File::Raw::exists($link), 'symlink exists');
            ok(File::Raw::is_link($link), 'is_link returns true for symlink');
            ok(!File::Raw::is_link($target), 'is_link returns false for regular file');

            # Reading through symlink should work
            is(File::Raw::slurp($link), "target content", 'can read through symlink');

            # File tests on symlink
            ok(File::Raw::is_file($link), 'symlink to file is_file');
        }
    };
}

# ============================================
# Permission tests (Unix only)
# ============================================

SKIP: {
    skip "Permission tests require Unix", 1 unless $is_unix;
    skip "Permission tests unreliable as root", 1 if $> == 0;

    subtest 'unix permissions' => sub {
        my $file = "$tmpdir/perm_test.txt";
        File::Raw::spew($file, "permission test");

        # Test chmod
        ok(File::Raw::chmod($file, 0644), 'chmod 0644');
        my $mode = File::Raw::mode($file);
        is($mode & 0777, 0644, 'mode is 0644');

        ok(File::Raw::chmod($file, 0755), 'chmod 0755');
        $mode = File::Raw::mode($file);
        is($mode & 0777, 0755, 'mode is 0755');

        # Test is_executable
        ok(File::Raw::is_executable($file), 'is_executable after chmod 0755');

        File::Raw::chmod($file, 0644);
        ok(!File::Raw::is_executable($file), 'not executable after chmod 0644');
    };
}

# ============================================
# Case sensitivity
# ============================================

subtest 'case sensitivity' => sub {
    my $lower = "$tmpdir/casefile.txt";
    my $upper = "$tmpdir/CaseFile.txt";

    File::Raw::spew($lower, "lowercase");

    SKIP: {
        # On case-insensitive systems (macOS default, Windows), these are same file
        skip "Case-insensitive filesystem", 2 if File::Raw::exists($upper) && !$is_unix;

        # On case-sensitive systems, these are different files
        if (!File::Raw::exists($upper)) {
            File::Raw::spew($upper, "UPPERCASE");
            ok(File::Raw::exists($lower), 'lowercase file exists');
            ok(File::Raw::exists($upper), 'uppercase file exists');
            isnt(File::Raw::slurp($lower), File::Raw::slurp($upper), 'different content');
        }
    }

    pass('case sensitivity test completed');
};

# ============================================
# Line ending handling
# ============================================

subtest 'line endings' => sub {
    my $unix_file = "$tmpdir/unix_lines.txt";
    my $win_file = "$tmpdir/win_lines.txt";
    my $mac_file = "$tmpdir/mac_lines.txt";

    # Unix: \n
    File::Raw::spew($unix_file, "line1\nline2\nline3");
    my $unix_lines = File::Raw::lines($unix_file);
    is(scalar(@$unix_lines), 3, 'unix line count');
    is($unix_lines->[0], 'line1', 'unix line 1');

    # Windows: \r\n (note: file module splits on \n only)
    File::Raw::spew($win_file, "line1\r\nline2\r\nline3");
    my $win_lines = File::Raw::lines($win_file);
    is(scalar(@$win_lines), 3, 'windows line count');
    # Lines will have \r at end
    like($win_lines->[0], qr/^line1/, 'windows line 1 starts correctly');

    # Old Mac: \r only
    File::Raw::spew($mac_file, "line1\rline2\rline3");
    my $mac_lines = File::Raw::lines($mac_file);
    is(scalar(@$mac_lines), 1, 'mac lines (no \\n) is one line');
};

# ============================================
# Binary mode consistency
# ============================================

subtest 'binary mode' => sub {
    my $file = "$tmpdir/binary_mode.dat";

    # Write binary data
    my $binary = join('', map { chr($_) } 0..255);
    File::Raw::spew($file, $binary);

    # Read with slurp
    my $read1 = File::Raw::slurp($file);
    is(length($read1), 256, 'slurp binary length');

    # Read with slurp_raw
    my $read2 = File::Raw::slurp_raw($file);
    is(length($read2), 256, 'slurp_raw binary length');

    # Both should be identical
    is($read1, $read2, 'slurp and slurp_raw identical for binary');
    is($read1, $binary, 'binary content preserved');
};

# ============================================
# Temporary directory behavior
# ============================================

subtest 'temp directory' => sub {
    ok(File::Raw::is_dir($tmpdir), 'temp directory exists');
    ok(File::Raw::is_writable($tmpdir), 'temp directory is writable');

    my $nested = "$tmpdir/nested/deep/dir";
    # File::Raw::mkdir doesn't do recursive mkdir
    ok(!File::Raw::mkdir($nested), 'mkdir fails for nested (no recursive)');

    # Create step by step
    ok(File::Raw::mkdir("$tmpdir/nested"), 'mkdir nested');
    ok(File::Raw::mkdir("$tmpdir/nested/deep"), 'mkdir nested/deep');
    ok(File::Raw::mkdir("$tmpdir/nested/deep/dir"), 'mkdir nested/deep/dir');
    ok(File::Raw::is_dir($nested), 'nested directory created');
};

# ============================================
# File size limits
# ============================================

subtest 'file sizes' => sub {
    # Empty file
    my $empty = "$tmpdir/size_empty.txt";
    File::Raw::spew($empty, "");
    is(File::Raw::size($empty), 0, 'empty file size');

    # Small file
    my $small = "$tmpdir/size_small.txt";
    File::Raw::spew($small, "hello");
    is(File::Raw::size($small), 5, 'small file size');

    # Medium file
    my $medium = "$tmpdir/size_medium.txt";
    File::Raw::spew($medium, "x" x 10000);
    is(File::Raw::size($medium), 10000, 'medium file size');

    SKIP: {
        skip "Large file test slow", 1 unless $ENV{TEST_LARGE_FILES};

        # Large file (10MB)
        my $large = "$tmpdir/size_large.txt";
        File::Raw::spew($large, "x" x (10 * 1024 * 1024));
        is(File::Raw::size($large), 10 * 1024 * 1024, 'large file size');
    }
};

# ============================================
# Special files (Unix only)
# ============================================

SKIP: {
    skip "Special file tests require Unix", 1 unless $is_unix;

    subtest 'special files' => sub {
        # /dev/null
        SKIP: {
            skip "/dev/null not available", 3 unless -e '/dev/null';

            ok(File::Raw::exists('/dev/null'), '/dev/null exists');
            # Can write to /dev/null
            ok(File::Raw::spew('/dev/null', "test"), 'can write to /dev/null');
            # Size of /dev/null is 0
            is(File::Raw::size('/dev/null'), 0, '/dev/null size is 0');
        }

        # /dev/zero - reading would be problematic, just check exists
        SKIP: {
            skip "/dev/zero not available", 1 unless -e '/dev/zero';

            ok(File::Raw::exists('/dev/zero'), '/dev/zero exists');
        }
    };
}

# ============================================
# Atomic operations across platforms
# ============================================

subtest 'atomic operations' => sub {
    my $file = "$tmpdir/atomic_platform.txt";

    # Multiple atomic writes
    for my $i (1..10) {
        ok(File::Raw::atomic_spew($file, "version $i"), "atomic write $i");
    }

    is(File::Raw::slurp($file), "version 10", 'final atomic content');

    # Verify no temp files left behind
    my $entries = File::Raw::readdir($tmpdir);
    my @temps = grep { /\.tmp\.\d+/ } @$entries;
    is(scalar(@temps), 0, 'no temp files left behind');
};

done_testing();
