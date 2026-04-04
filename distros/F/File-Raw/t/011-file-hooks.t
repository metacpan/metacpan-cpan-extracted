#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempfile tempdir);

# Test file hooks system

my $tempdir = tempdir(CLEANUP => 1);

# ============================================
# Basic hook registration
# ============================================

subtest 'hook registration functions exist' => sub {
    ok(defined(&File::Raw::register_read_hook), 'register_read_hook exists');
    ok(defined(&File::Raw::register_write_hook), 'register_write_hook exists');
    ok(defined(&File::Raw::clear_hooks), 'clear_hooks exists');
    ok(defined(&File::Raw::has_hooks), 'has_hooks exists');
};

subtest 'no hooks by default' => sub {
    ok(!File::Raw::has_hooks('read'), 'no read hooks initially');
    ok(!File::Raw::has_hooks('write'), 'no write hooks initially');
};

# ============================================
# Read hooks
# ============================================

subtest 'read hook transforms data' => sub {
    # Clear any existing hooks
    File::Raw::clear_hooks('read');

    # Register a hook that uppercases content
    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        return uc($data);
    });

    ok(File::Raw::has_hooks('read'), 'read hook registered');

    # Write test file (use slurp_raw to bypass hooks for setup)
    my $testfile = "$tempdir/read_hook_test.txt";
    File::Raw::spew($testfile, "hello world");

    # Clear and re-register to ensure clean state
    File::Raw::clear_hooks('read');
    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        return uc($data);
    });

    # Read should apply hook
    my $content = File::Raw::slurp($testfile);
    is($content, 'HELLO WORLD', 'read hook transformed content');

    File::Raw::clear_hooks('read');
};

subtest 'read hook receives path' => sub {
    File::Raw::clear_hooks('read');

    my $received_path;
    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        $received_path = $path;
        return $data;  # Pass through unchanged
    });

    my $testfile = "$tempdir/path_test.txt";
    File::Raw::spew($testfile, "test");

    File::Raw::clear_hooks('read');
    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        $received_path = $path;
        return $data;
    });

    File::Raw::slurp($testfile);
    is($received_path, $testfile, 'hook received correct path');

    File::Raw::clear_hooks('read');
};

# ============================================
# Write hooks
# ============================================

subtest 'write hook transforms data' => sub {
    File::Raw::clear_hooks('write');

    # Register a hook that lowercases content
    File::Raw::register_write_hook(sub {
        my ($path, $data) = @_;
        return lc($data);
    });

    ok(File::Raw::has_hooks('write'), 'write hook registered');

    my $testfile = "$tempdir/write_hook_test.txt";
    File::Raw::spew($testfile, "HELLO WORLD");

    File::Raw::clear_hooks('write');

    # Read raw to verify transformation
    my $content = File::Raw::slurp($testfile);
    is($content, 'hello world', 'write hook transformed content');
};

subtest 'write hook can add prefix' => sub {
    File::Raw::clear_hooks('write');

    File::Raw::register_write_hook(sub {
        my ($path, $data) = @_;
        return "PREFIX: $data";
    });

    my $testfile = "$tempdir/prefix_test.txt";
    File::Raw::spew($testfile, "content");

    File::Raw::clear_hooks('write');

    my $content = File::Raw::slurp($testfile);
    is($content, 'PREFIX: content', 'write hook added prefix');
};

# ============================================
# Hook clearing
# ============================================

subtest 'clear_hooks removes hooks' => sub {
    File::Raw::clear_hooks('read');
    File::Raw::clear_hooks('write');

    File::Raw::register_read_hook(sub { uc($_[1]) });
    File::Raw::register_write_hook(sub { lc($_[1]) });

    ok(File::Raw::has_hooks('read'), 'read hook present');
    ok(File::Raw::has_hooks('write'), 'write hook present');

    File::Raw::clear_hooks('read');
    ok(!File::Raw::has_hooks('read'), 'read hook cleared');
    ok(File::Raw::has_hooks('write'), 'write hook still present');

    File::Raw::clear_hooks('write');
    ok(!File::Raw::has_hooks('write'), 'write hook cleared');
};

# ============================================
# No hooks = no overhead path
# ============================================

subtest 'operations work without hooks' => sub {
    File::Raw::clear_hooks('read');
    File::Raw::clear_hooks('write');

    my $testfile = "$tempdir/no_hooks.txt";
    my $data = "test data without hooks";

    File::Raw::spew($testfile, $data);
    my $read = File::Raw::slurp($testfile);

    is($read, $data, 'read/write work without hooks');
};

# ============================================
# slurp_raw bypasses hooks
# ============================================

subtest 'slurp_raw bypasses read hooks' => sub {
    File::Raw::clear_hooks('read');

    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        return uc($data);
    });

    my $testfile = "$tempdir/raw_test.txt";
    File::Raw::spew($testfile, "lowercase");

    File::Raw::clear_hooks('read');
    File::Raw::register_read_hook(sub { uc($_[1]) });

    # slurp_raw should bypass hooks
    my $raw = File::Raw::slurp_raw($testfile);
    is($raw, 'lowercase', 'slurp_raw bypasses read hooks');

    # regular slurp should use hooks
    my $hooked = File::Raw::slurp($testfile);
    is($hooked, 'LOWERCASE', 'slurp uses read hooks');

    File::Raw::clear_hooks('read');
};

# ============================================
# Multiple operations with same hook
# ============================================

subtest 'hook persists across multiple operations' => sub {
    File::Raw::clear_hooks('read');

    my $call_count = 0;
    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        $call_count++;
        return $data;
    });

    my $testfile = "$tempdir/persist_test.txt";
    File::Raw::spew($testfile, "data");

    File::Raw::slurp($testfile);
    File::Raw::slurp($testfile);
    File::Raw::slurp($testfile);

    is($call_count, 3, 'hook called for each read');

    File::Raw::clear_hooks('read');
};

# ============================================
# Encoding-style hook example
# ============================================

subtest 'encoding hook example' => sub {
    File::Raw::clear_hooks('read');
    File::Raw::clear_hooks('write');

    # Simulate base64-like encoding (just reverse for simplicity)
    File::Raw::register_write_hook(sub {
        my ($path, $data) = @_;
        return scalar(reverse($data));
    });

    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        return scalar(reverse($data));
    });

    my $testfile = "$tempdir/encoding_test.txt";
    my $original = "Hello, World!";

    File::Raw::spew($testfile, $original);

    # File on disk should be reversed
    File::Raw::clear_hooks('read');
    my $on_disk = File::Raw::slurp($testfile);
    is($on_disk, '!dlroW ,olleH', 'data encoded on disk');

    # Re-register read hook
    File::Raw::register_read_hook(sub {
        my ($path, $data) = @_;
        return scalar(reverse($data));
    });

    # Reading should decode
    my $decoded = File::Raw::slurp($testfile);
    is($decoded, $original, 'data decoded on read');

    File::Raw::clear_hooks('read');
    File::Raw::clear_hooks('write');
};

done_testing();
