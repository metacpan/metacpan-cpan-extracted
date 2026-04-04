#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('File::Raw');

my $tmpdir = tempdir(CLEANUP => 1);

# ============================================
# Error handling for nonexistent files
# ============================================

subtest 'nonexistent file operations' => sub {
    my $nonexistent = "$tmpdir/does_not_exist.txt";

    is(File::Raw::slurp($nonexistent), undef, 'slurp nonexistent returns undef');
    is(File::Raw::size($nonexistent), -1, 'size nonexistent returns -1');
    is(File::Raw::mtime($nonexistent), -1, 'mtime nonexistent returns -1');
    is(File::Raw::atime($nonexistent), -1, 'atime nonexistent returns -1');
    is(File::Raw::ctime($nonexistent), -1, 'ctime nonexistent returns -1');
    is(File::Raw::mode($nonexistent), -1, 'mode nonexistent returns -1');

    ok(!File::Raw::exists($nonexistent), 'exists nonexistent returns false');
    ok(!File::Raw::is_file($nonexistent), 'is_file nonexistent returns false');
    ok(!File::Raw::is_dir($nonexistent), 'is_dir nonexistent returns false');
    ok(!File::Raw::is_readable($nonexistent), 'is_readable nonexistent returns false');
    ok(!File::Raw::is_writable($nonexistent), 'is_writable nonexistent returns false');
    ok(!File::Raw::is_link($nonexistent), 'is_link nonexistent returns false');

    ok(!File::Raw::unlink($nonexistent), 'unlink nonexistent returns false');
    ok(!File::Raw::rmdir($nonexistent), 'rmdir nonexistent returns false');

    my $lines = File::Raw::lines($nonexistent);
    is(ref($lines), 'ARRAY', 'lines returns arrayref');
    is(scalar(@$lines), 0, 'lines of nonexistent is empty');
};

# ============================================
# Path manipulation edge cases
# ============================================

subtest 'path edge cases' => sub {
    # Empty string
    is(File::Raw::basename(''), '', 'basename of empty');
    is(File::Raw::dirname(''), '.', 'dirname of empty');
    is(File::Raw::extname(''), '', 'extname of empty');

    # Root only
    is(File::Raw::basename('/'), '', 'basename of root');
    is(File::Raw::dirname('/'), '/', 'dirname of root');

    # Multiple slashes
    is(File::Raw::basename('//'), '', 'basename of double slash');
    is(File::Raw::basename('/a//b//c'), 'c', 'basename with double slashes');
    is(File::Raw::dirname('/a//b//c'), '/a//b', 'dirname with double slashes');

    # Trailing slashes
    is(File::Raw::basename('/path/dir/'), 'dir', 'basename with trailing slash');
    is(File::Raw::dirname('/path/dir/'), '/path', 'dirname with trailing slash');

    # Hidden files
    is(File::Raw::basename('.hidden'), '.hidden', 'basename of hidden');
    is(File::Raw::extname('.hidden'), '', 'extname of hidden (no ext)');
    is(File::Raw::extname('.hidden.txt'), '.txt', 'extname of hidden with ext');

    # Multiple extensions
    is(File::Raw::extname('file.tar.gz'), '.gz', 'extname of tar.gz');
    is(File::Raw::extname('file.min.js'), '.js', 'extname of min.js');

    # No extension
    is(File::Raw::extname('Makefile'), '', 'extname of Makefile');
    is(File::Raw::extname('/path/to/README'), '', 'extname of README');

    # Dot at end
    is(File::Raw::extname('file.'), '.', 'extname of file.');
};

# ============================================
# join path edge cases
# ============================================

subtest 'join edge cases' => sub {
    # Empty parts
    my $j1 = File::Raw::join('a', '', 'b');
    ok($j1 !~ m{//}, 'join handles empty middle part');

    # Single part
    is(File::Raw::join('single'), 'single', 'join single part');

    # Root handling
    my $j2 = File::Raw::join('/', 'path');
    like($j2, qr{^/.*path}, 'join with root');

    # Already has separator
    my $j3 = File::Raw::join('/path/', '/to/', '/file');
    ok($j3 !~ m{//}, 'join removes duplicate separators');
};

# ============================================
# head and tail edge cases
# ============================================

subtest 'head edge cases' => sub {
    my $file = "$tmpdir/head_edge.txt";

    # File with fewer lines than requested
    File::Raw::spew($file, "one\ntwo\nthree");
    my $h = File::Raw::head($file, 10);
    is(scalar(@$h), 3, 'head returns all lines when fewer than N');

    # Zero lines
    my $h0 = File::Raw::head($file, 0);
    is(scalar(@$h0), 0, 'head(0) returns empty');

    # Empty file
    File::Raw::spew($file, "");
    my $he = File::Raw::head($file);
    is(scalar(@$he), 0, 'head of empty file');

    # Nonexistent file
    my $hn = File::Raw::head("$tmpdir/nonexistent.txt", 5);
    is(scalar(@$hn), 0, 'head of nonexistent returns empty');
};

subtest 'tail edge cases' => sub {
    my $file = "$tmpdir/tail_edge.txt";

    # File with fewer lines than requested
    File::Raw::spew($file, "one\ntwo\nthree");
    my $t = File::Raw::tail($file, 10);
    is(scalar(@$t), 3, 'tail returns all lines when fewer than N');

    # Zero lines
    my $t0 = File::Raw::tail($file, 0);
    is(scalar(@$t0), 0, 'tail(0) returns empty');

    # Empty file
    File::Raw::spew($file, "");
    my $te = File::Raw::tail($file);
    is(scalar(@$te), 0, 'tail of empty file');

    # Nonexistent file
    my $tn = File::Raw::tail("$tmpdir/nonexistent.txt", 5);
    is(scalar(@$tn), 0, 'tail of nonexistent returns empty');
};

# ============================================
# Overwriting files
# ============================================

subtest 'overwrite behavior' => sub {
    my $file = "$tmpdir/overwrite.txt";

    File::Raw::spew($file, "original content that is quite long");
    is(File::Raw::slurp($file), "original content that is quite long", 'original content');

    File::Raw::spew($file, "short");
    is(File::Raw::slurp($file), "short", 'overwritten with shorter content');

    File::Raw::spew($file, "");
    is(File::Raw::slurp($file), "", 'overwritten with empty');
};

# ============================================
# Binary data edge cases
# ============================================

subtest 'binary edge cases' => sub {
    my $file = "$tmpdir/binary_edge.dat";

    # All null bytes
    my $nulls = "\0" x 100;
    File::Raw::spew($file, $nulls);
    my $read = File::Raw::slurp($file);
    is(length($read), 100, 'null bytes preserved');
    is($read, $nulls, 'null content matches');

    # All high bytes
    my $high = chr(255) x 100;
    File::Raw::spew($file, $high);
    $read = File::Raw::slurp($file);
    is($read, $high, 'high bytes preserved');

    # Mixed binary
    my $mixed = join('', map { chr($_) } 0..255);
    File::Raw::spew($file, $mixed);
    $read = File::Raw::slurp($file);
    is($read, $mixed, 'full byte range preserved');
};

# ============================================
# Copy edge cases
# ============================================

subtest 'copy edge cases' => sub {
    # Copy to self (should work but be no-op or fail gracefully)
    my $file = "$tmpdir/copy_self.txt";
    File::Raw::spew($file, "self copy test");

    # Copy empty file
    my $empty = "$tmpdir/copy_empty_src.txt";
    my $empty_dst = "$tmpdir/copy_empty_dst.txt";
    File::Raw::spew($empty, "");
    ok(File::Raw::copy($empty, $empty_dst), 'copy empty file');
    is(File::Raw::slurp($empty_dst), "", 'copied empty file is empty');

    # Copy nonexistent
    ok(!File::Raw::copy("$tmpdir/nonexistent.txt", "$tmpdir/copy_dst.txt"),
       'copy nonexistent returns false');
};

# ============================================
# Move edge cases
# ============================================

subtest 'move edge cases' => sub {
    # Move nonexistent
    ok(!File::Raw::move("$tmpdir/nonexistent.txt", "$tmpdir/move_dst.txt"),
       'move nonexistent returns false');

    # Move to existing (should overwrite)
    my $src = "$tmpdir/move_src.txt";
    my $dst = "$tmpdir/move_existing.txt";
    File::Raw::spew($src, "source content");
    File::Raw::spew($dst, "existing content");
    ok(File::Raw::move($src, $dst), 'move to existing file');
    is(File::Raw::slurp($dst), "source content", 'move overwrote existing');
    ok(!File::Raw::exists($src), 'source gone after move');
};

# ============================================
# mkdir edge cases
# ============================================

subtest 'mkdir edge cases' => sub {
    # mkdir existing directory
    my $dir = "$tmpdir/mkdir_existing";
    File::Raw::mkdir($dir);
    ok(!File::Raw::mkdir($dir), 'mkdir existing returns false');

    # mkdir over existing file
    my $file = "$tmpdir/mkdir_over_file";
    File::Raw::spew($file, "file");
    ok(!File::Raw::mkdir($file), 'mkdir over file returns false');
};

# ============================================
# rmdir edge cases
# ============================================

subtest 'rmdir edge cases' => sub {
    # rmdir non-empty directory
    my $dir = "$tmpdir/rmdir_nonempty";
    File::Raw::mkdir($dir);
    File::Raw::spew("$dir/file.txt", "content");
    ok(!File::Raw::rmdir($dir), 'rmdir non-empty returns false');

    # Clean up
    File::Raw::unlink("$dir/file.txt");
    File::Raw::rmdir($dir);

    # rmdir file
    my $file = "$tmpdir/rmdir_file.txt";
    File::Raw::spew($file, "content");
    ok(!File::Raw::rmdir($file), 'rmdir on file returns false');
};

# ============================================
# atomic_spew edge cases
# ============================================

subtest 'atomic_spew edge cases' => sub {
    my $file = "$tmpdir/atomic_edge.txt";

    # Atomic write empty
    ok(File::Raw::atomic_spew($file, ""), 'atomic_spew empty');
    is(File::Raw::slurp($file), "", 'atomic empty content');

    # Atomic overwrite
    File::Raw::atomic_spew($file, "first");
    File::Raw::atomic_spew($file, "second");
    is(File::Raw::slurp($file), "second", 'atomic overwrite works');
};

# ============================================
# readdir edge cases
# ============================================

subtest 'readdir edge cases' => sub {
    # Empty directory
    my $empty_dir = "$tmpdir/readdir_empty";
    File::Raw::mkdir($empty_dir);
    my $entries = File::Raw::readdir($empty_dir);
    is(scalar(@$entries), 0, 'readdir empty dir');

    # Nonexistent directory
    my $ne = File::Raw::readdir("$tmpdir/nonexistent_dir");
    is(ref($ne), 'ARRAY', 'readdir nonexistent returns arrayref');
    is(scalar(@$ne), 0, 'readdir nonexistent is empty');

    # readdir on file
    my $file = "$tmpdir/readdir_file.txt";
    File::Raw::spew($file, "content");
    my $rf = File::Raw::readdir($file);
    is(scalar(@$rf), 0, 'readdir on file returns empty');
};

# ============================================
# Large file operations
# ============================================

subtest 'large file operations' => sub {
    my $file = "$tmpdir/large_file.txt";
    my $size = 1024 * 1024;  # 1MB
    my $content = "x" x $size;

    File::Raw::spew($file, $content);
    is(File::Raw::size($file), $size, 'large file size');

    my $read = File::Raw::slurp($file);
    is(length($read), $size, 'large file slurp length');
    is($read, $content, 'large file content');
};

# ============================================
# Concurrent access (basic test)
# ============================================

subtest 'multiple readers' => sub {
    my $file = "$tmpdir/concurrent.txt";
    File::Raw::spew($file, "shared content");

    # Multiple slurps
    my $r1 = File::Raw::slurp($file);
    my $r2 = File::Raw::slurp($file);
    my $r3 = File::Raw::slurp($file);

    is($r1, $r2, 'concurrent reads match');
    is($r2, $r3, 'concurrent reads match');
};

done_testing();
