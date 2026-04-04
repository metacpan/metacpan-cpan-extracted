#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Test the custom ops import functionality
use File::Raw qw(import);

my $tmpdir = tempdir(CLEANUP => 1);

# ============================================
# Test that all custom op functions are imported
# ============================================

subtest 'custom op functions imported' => sub {
    can_ok('main', 'file_slurp');
    can_ok('main', 'file_spew');
    can_ok('main', 'file_exists');
    can_ok('main', 'file_size');
    can_ok('main', 'file_is_file');
    can_ok('main', 'file_is_dir');
    can_ok('main', 'file_lines');
    can_ok('main', 'file_unlink');
    can_ok('main', 'file_mkdir');
    can_ok('main', 'file_rmdir');
    can_ok('main', 'file_touch');
    can_ok('main', 'file_basename');
    can_ok('main', 'file_dirname');
    can_ok('main', 'file_extname');
};

# ============================================
# Test file_slurp and file_spew
# ============================================

subtest 'file_slurp and file_spew' => sub {
    my $file = "$tmpdir/slurp_spew.txt";
    my $content = "Hello from custom ops!\nLine 2\nLine 3";

    ok(file_spew($file, $content), 'file_spew returns true');
    ok(file_exists($file), 'file_exists confirms file');

    my $read = file_slurp($file);
    is($read, $content, 'file_slurp returns correct content');
};

# ============================================
# Test file_exists and file_size
# ============================================

subtest 'file_exists and file_size' => sub {
    my $file = "$tmpdir/exists_size.txt";
    file_spew($file, "12345");

    ok(file_exists($file), 'file_exists returns true for existing file');
    ok(!file_exists("$tmpdir/nonexistent_xyz.txt"), 'file_exists returns false for nonexistent');

    is(file_size($file), 5, 'file_size returns correct size');
};

# ============================================
# Test file_is_file and file_is_dir
# ============================================

subtest 'file_is_file and file_is_dir' => sub {
    my $file = "$tmpdir/is_file_test.txt";
    file_spew($file, "test");

    ok(file_is_file($file), 'file_is_file returns true for file');
    ok(!file_is_file($tmpdir), 'file_is_file returns false for dir');
    ok(!file_is_file("$tmpdir/nonexistent.txt"), 'file_is_file returns false for nonexistent');

    ok(file_is_dir($tmpdir), 'file_is_dir returns true for dir');
    ok(!file_is_dir($file), 'file_is_dir returns false for file');
    ok(!file_is_dir("$tmpdir/nonexistent_dir"), 'file_is_dir returns false for nonexistent');
};

# ============================================
# Test file_lines
# ============================================

subtest 'file_lines' => sub {
    my $file = "$tmpdir/lines_test.txt";
    file_spew($file, "one\ntwo\nthree\nfour");

    my $lines = file_lines($file);
    is(ref($lines), 'ARRAY', 'file_lines returns arrayref');
    is(scalar(@$lines), 4, 'correct number of lines');
    is($lines->[0], 'one', 'first line correct');
    is($lines->[3], 'four', 'last line correct');
};

# ============================================
# Test file_unlink
# ============================================

subtest 'file_unlink' => sub {
    my $file = "$tmpdir/to_unlink.txt";
    file_spew($file, "delete me");

    ok(file_exists($file), 'file exists before unlink');
    ok(file_unlink($file), 'file_unlink returns true');
    ok(!file_exists($file), 'file gone after unlink');
    ok(!file_unlink($file), 'file_unlink returns false for nonexistent');
};

# ============================================
# Test file_mkdir and file_rmdir
# ============================================

subtest 'file_mkdir and file_rmdir' => sub {
    my $dir = "$tmpdir/mkdir_test";

    ok(file_mkdir($dir), 'file_mkdir returns true');
    ok(file_is_dir($dir), 'directory created');

    ok(file_rmdir($dir), 'file_rmdir returns true');
    ok(!file_is_dir($dir), 'directory removed');
};

# ============================================
# Test file_touch
# ============================================

subtest 'file_touch' => sub {
    my $file = "$tmpdir/touch_test.txt";

    ok(file_touch($file), 'file_touch new file returns true');
    ok(file_exists($file), 'touched file exists');
    is(file_size($file), 0, 'touched file is empty');
};

# ============================================
# Test path manipulation
# ============================================

subtest 'file_basename' => sub {
    is(file_basename('/path/to/file.txt'), 'file.txt', 'basename extracts filename');
    is(file_basename('/path/to/dir/'), 'dir', 'basename handles trailing slash');
    is(file_basename('filename.txt'), 'filename.txt', 'basename with no path');
};

subtest 'file_dirname' => sub {
    is(file_dirname('/path/to/file.txt'), '/path/to', 'dirname extracts directory');
    is(file_dirname('file.txt'), '.', 'dirname defaults to .');
    is(file_dirname('/file.txt'), '/', 'dirname of root-level file');
};

subtest 'file_extname' => sub {
    is(file_extname('/path/to/file.txt'), '.txt', 'extname extracts extension');
    is(file_extname('file.tar.gz'), '.gz', 'extname gets last extension');
    is(file_extname('noext'), '', 'extname with no extension');
};

# ============================================
# Test custom ops vs method calls
# ============================================

subtest 'custom ops match method calls' => sub {
    my $file = "$tmpdir/compare.txt";
    my $content = "comparison test\nline 2";

    # Using method calls
    File::Raw::spew($file, $content);
    my $method_slurp = File::Raw::slurp($file);
    my $method_exists = File::Raw::exists($file);
    my $method_size = File::Raw::size($file);
    my $method_is_file = File::Raw::is_file($file);
    my $method_basename = File::Raw::basename($file);

    # Using custom ops
    my $op_slurp = file_slurp($file);
    my $op_exists = file_exists($file);
    my $op_size = file_size($file);
    my $op_is_file = file_is_file($file);
    my $op_basename = file_basename($file);

    is($op_slurp, $method_slurp, 'slurp results match');
    is($op_exists, $method_exists, 'exists results match');
    is($op_size, $method_size, 'size results match');
    is($op_is_file, $method_is_file, 'is_file results match');
    is($op_basename, $method_basename, 'basename results match');
};

# ============================================
# Performance sanity check (just verify they work, not actual speed)
# ============================================

subtest 'custom ops in loops' => sub {
    my $file = "$tmpdir/loop_test.txt";
    file_spew($file, "loop content");

    # Verify custom ops work in tight loops
    my $count = 0;
    for (1..100) {
        if (file_exists($file)) {
            $count++;
        }
    }
    is($count, 100, 'custom ops work in loops');

    # Multiple reads
    my @contents;
    for (1..10) {
        push @contents, file_slurp($file);
    }
    is(scalar(@contents), 10, 'multiple slurps work');
    ok((grep { $_ eq 'loop content' } @contents) == 10, 'all slurps correct');
};

# ============================================
# Edge cases
# ============================================

subtest 'empty file handling' => sub {
    my $file = "$tmpdir/empty_custom.txt";
    file_spew($file, "");

    is(file_slurp($file), "", 'slurp empty file');
    is(file_size($file), 0, 'size of empty file');

    my $lines = file_lines($file);
    is(scalar(@$lines), 0, 'lines of empty file');
};

subtest 'binary data' => sub {
    my $file = "$tmpdir/binary_custom.dat";
    my $binary = join('', map { chr($_) } 0..255);

    file_spew($file, $binary);
    my $read = file_slurp($file);

    is(length($read), 256, 'binary data length');
    is($read, $binary, 'binary data content');
};

subtest 'special characters in content' => sub {
    my $file = "$tmpdir/special_custom.txt";
    my $content = "line with \t tab\nline with \0 null\n\$var \@array %hash";

    file_spew($file, $content);
    my $read = file_slurp($file);

    is($read, $content, 'special characters preserved');
};

done_testing();
