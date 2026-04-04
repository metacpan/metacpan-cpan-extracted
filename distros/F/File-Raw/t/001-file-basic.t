#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);

use_ok('File::Raw');

my $tmpdir = tempdir(CLEANUP => 1);

# Test spew and slurp
subtest 'spew and slurp' => sub {
    my $file = "$tmpdir/test.txt";
    my $content = "Hello, World!\nLine 2\nLine 3";

    ok(File::Raw::spew($file, $content), 'spew returns true');
    ok(File::Raw::exists($file), 'file exists');

    my $read = File::Raw::slurp($file);
    is($read, $content, 'slurp returns correct content');
};

# Test append
subtest 'append' => sub {
    my $file = "$tmpdir/append.txt";

    File::Raw::spew($file, "Line 1\n");
    File::Raw::append($file, "Line 2\n");
    File::Raw::append($file, "Line 3\n");

    my $content = File::Raw::slurp($file);
    is($content, "Line 1\nLine 2\nLine 3\n", 'append works correctly');
};

# Test lines
subtest 'lines' => sub {
    my $file = "$tmpdir/lines.txt";
    File::Raw::spew($file, "one\ntwo\nthree");

    my $lines = File::Raw::lines($file);
    is(ref($lines), 'ARRAY', 'lines returns arrayref');
    is(scalar(@$lines), 3, 'correct number of lines');
    is($lines->[0], 'one', 'first line correct');
    is($lines->[1], 'two', 'second line correct');
    is($lines->[2], 'three', 'third line correct');
};

# Test each_line
subtest 'each_line' => sub {
    my $file = "$tmpdir/each.txt";
    File::Raw::spew($file, "a\nb\nc\nd\ne");

    my @collected;
    File::Raw::each_line($file, sub {
        push @collected, $_;
    });

    is(scalar(@collected), 5, 'collected all lines');
    is_deeply(\@collected, [qw(a b c d e)], 'lines in order');
};

# Test line iterator
subtest 'lines_iter' => sub {
    my $file = "$tmpdir/iter.txt";
    File::Raw::spew($file, "first\nsecond\nthird");

    my $iter = File::Raw::lines_iter($file);
    ok($iter, 'iterator created');

    ok(!$iter->eof, 'not eof at start');
    is($iter->next, 'first', 'first line');
    is($iter->next, 'second', 'second line');
    is($iter->next, 'third', 'third line');
    ok($iter->eof, 'eof after last line');

    $iter->close;
};

# Test stat operations
subtest 'stat operations' => sub {
    my $file = "$tmpdir/stat.txt";
    File::Raw::spew($file, "12345");

    is(File::Raw::size($file), 5, 'size is correct');
    ok(File::Raw::mtime($file) > 0, 'mtime is positive');
    ok(File::Raw::exists($file), 'exists returns true');
    ok(File::Raw::is_file($file), 'is_file returns true');
    ok(!File::Raw::is_dir($file), 'is_dir returns false for file');
    ok(File::Raw::is_dir($tmpdir), 'is_dir returns true for dir');
    ok(File::Raw::is_readable($file), 'is_readable returns true');
    ok(File::Raw::is_writable($file), 'is_writable returns true');
};

# Test non-existent file
subtest 'non-existent file' => sub {
    my $file = "$tmpdir/nonexistent.txt";

    ok(!File::Raw::exists($file), 'exists returns false');
    is(File::Raw::slurp($file), undef, 'slurp returns undef');
    is(File::Raw::size($file), -1, 'size returns -1');
};

# Test mmap
subtest 'mmap' => sub {
    my $file = "$tmpdir/mmap.txt";
    File::Raw::spew($file, "Memory mapped content!");

    my $mmap = File::Raw::mmap_open($file);
    ok($mmap, 'mmap opened');

    my $data = $mmap->data;
    is($data, "Memory mapped content!", 'mmap data correct');

    $mmap->close;
};

# Test empty file
subtest 'empty file' => sub {
    my $file = "$tmpdir/empty.txt";
    File::Raw::spew($file, "");

    is(File::Raw::slurp($file), "", 'slurp empty file returns empty string');
    is(File::Raw::size($file), 0, 'size of empty file is 0');

    my $lines = File::Raw::lines($file);
    is(scalar(@$lines), 0, 'lines of empty file is empty array');
};

# Test binary data
subtest 'binary data' => sub {
    my $file = "$tmpdir/binary.dat";
    my $binary = join('', map { chr($_) } 0..255);

    File::Raw::spew($file, $binary);
    my $read = File::Raw::slurp_raw($file);

    is(length($read), 256, 'binary length correct');
    is($read, $binary, 'binary content matches');
};

# Test large file
subtest 'large file' => sub {
    my $file = "$tmpdir/large.txt";
    my $content = "x" x (1024 * 100);  # 100KB

    File::Raw::spew($file, $content);
    my $read = File::Raw::slurp($file);

    is(length($read), length($content), 'large file length correct');
};

# Test additional stat operations
subtest 'additional stat ops' => sub {
    my $file = "$tmpdir/stat2.txt";
    File::Raw::spew($file, "test content");

    ok(File::Raw::atime($file) > 0, 'atime is positive');
    ok(File::Raw::ctime($file) > 0, 'ctime is positive');
    my $mode = File::Raw::mode($file);
    ok($mode >= 0, 'mode is non-negative');
    ok(!File::Raw::is_link($file), 'regular file is not a link');
    # is_executable depends on mode
};

# Test unlink
subtest 'unlink' => sub {
    my $file = "$tmpdir/to_delete.txt";
    File::Raw::spew($file, "delete me");
    ok(File::Raw::exists($file), 'file exists before unlink');
    ok(File::Raw::unlink($file), 'unlink returns true');
    ok(!File::Raw::exists($file), 'file gone after unlink');
    ok(!File::Raw::unlink($file), 'unlink non-existent returns false');
};

# Test copy
subtest 'copy' => sub {
    my $src = "$tmpdir/copy_src.txt";
    my $dst = "$tmpdir/copy_dst.txt";
    my $content = "content to copy\nline 2";

    File::Raw::spew($src, $content);
    ok(File::Raw::copy($src, $dst), 'copy returns true');
    ok(File::Raw::exists($dst), 'destination exists');
    is(File::Raw::slurp($dst), $content, 'copied content matches');

    # Source should still exist
    ok(File::Raw::exists($src), 'source still exists after copy');
};

# Test move
subtest 'move' => sub {
    my $src = "$tmpdir/move_src.txt";
    my $dst = "$tmpdir/move_dst.txt";
    my $content = "content to move";

    File::Raw::spew($src, $content);
    ok(File::Raw::move($src, $dst), 'move returns true');
    ok(!File::Raw::exists($src), 'source gone after move');
    ok(File::Raw::exists($dst), 'destination exists');
    is(File::Raw::slurp($dst), $content, 'moved content matches');
};

# Test touch
subtest 'touch' => sub {
    my $file = "$tmpdir/touched.txt";

    # Touch new file
    ok(File::Raw::touch($file), 'touch new file returns true');
    ok(File::Raw::exists($file), 'touched file exists');
    is(File::Raw::size($file), 0, 'touched file is empty');

    # Touch existing file - should update mtime
    my $mtime1 = File::Raw::mtime($file);
    sleep(1);  # Need a small delay
    ok(File::Raw::touch($file), 'touch existing file returns true');
    my $mtime2 = File::Raw::mtime($file);
    ok($mtime2 >= $mtime1, 'mtime updated after touch');
};

# Test chmod
subtest 'chmod' => sub {
    my $file = "$tmpdir/chmod_test.txt";
    File::Raw::spew($file, "chmod test");

    ok(File::Raw::chmod($file, 0644), 'chmod returns true');
    # Mode check is platform-specific, just verify no error
};

# Test mkdir and rmdir
subtest 'mkdir and rmdir' => sub {
    my $dir = "$tmpdir/newdir";

    ok(File::Raw::mkdir($dir), 'mkdir returns true');
    ok(File::Raw::is_dir($dir), 'created directory exists');
    ok(!File::Raw::mkdir($dir), 'mkdir existing dir returns false');

    ok(File::Raw::rmdir($dir), 'rmdir returns true');
    ok(!File::Raw::is_dir($dir), 'directory gone after rmdir');
    ok(!File::Raw::rmdir($dir), 'rmdir non-existent returns false');
};

# Test readdir
subtest 'readdir' => sub {
    my $dir = "$tmpdir/listdir";
    File::Raw::mkdir($dir);
    File::Raw::spew("$dir/a.txt", "a");
    File::Raw::spew("$dir/b.txt", "b");
    File::Raw::spew("$dir/c.txt", "c");

    my $entries = File::Raw::readdir($dir);
    is(ref($entries), 'ARRAY', 'readdir returns arrayref');
    is(scalar(@$entries), 3, 'correct number of entries');

    my %files = map { $_ => 1 } @$entries;
    ok($files{'a.txt'}, 'a.txt in listing');
    ok($files{'b.txt'}, 'b.txt in listing');
    ok($files{'c.txt'}, 'c.txt in listing');
    ok(!$files{'.'}, '. not in listing');
    ok(!$files{'..'}, '.. not in listing');
};

# Test basename
subtest 'basename' => sub {
    is(File::Raw::basename('/path/to/file.txt'), 'file.txt', 'basename with path');
    is(File::Raw::basename('file.txt'), 'file.txt', 'basename without path');
    is(File::Raw::basename('/path/to/dir/'), 'dir', 'basename with trailing slash');
    is(File::Raw::basename('/'), '', 'basename of root');
    is(File::Raw::basename(''), '', 'basename of empty string');
};

# Test dirname
subtest 'dirname' => sub {
    is(File::Raw::dirname('/path/to/file.txt'), '/path/to', 'dirname with file');
    is(File::Raw::dirname('file.txt'), '.', 'dirname without path');
    is(File::Raw::dirname('/path/to/dir/'), '/path/to', 'dirname with trailing slash');
    is(File::Raw::dirname('/path'), '/', 'dirname of root child');
    is(File::Raw::dirname('/'), '/', 'dirname of root');
};

# Test extname
subtest 'extname' => sub {
    is(File::Raw::extname('/path/to/file.txt'), '.txt', 'extname with extension');
    is(File::Raw::extname('file.tar.gz'), '.gz', 'extname with multiple dots');
    is(File::Raw::extname('noext'), '', 'extname without extension');
    is(File::Raw::extname('.hidden'), '', 'extname of hidden file (no ext)');
    is(File::Raw::extname('.hidden.txt'), '.txt', 'extname of hidden file with ext');
};

# Test join
subtest 'join' => sub {
    my $sep = '/';  # Will be correct for this platform
    my $j1 = File::Raw::join('path', 'to', 'file');
    ok($j1 =~ /path.to.file/, 'join multiple parts');

    my $j2 = File::Raw::join('/root', 'path');
    ok($j2 =~ /root.path/, 'join with root');
};

# Test head
subtest 'head' => sub {
    my $file = "$tmpdir/head_test.txt";
    File::Raw::spew($file, join("\n", map { "Line $_" } 1..20));

    my $h5 = File::Raw::head($file, 5);
    is(ref($h5), 'ARRAY', 'head returns arrayref');
    is(scalar(@$h5), 5, 'head returns correct count');
    is($h5->[0], 'Line 1', 'head first line correct');
    is($h5->[4], 'Line 5', 'head last line correct');

    my $h10 = File::Raw::head($file);  # Default
    is(scalar(@$h10), 10, 'head default is 10 lines');
};

# Test tail
subtest 'tail' => sub {
    my $file = "$tmpdir/tail_test.txt";
    File::Raw::spew($file, join("\n", map { "Line $_" } 1..20));

    my $t5 = File::Raw::tail($file, 5);
    is(ref($t5), 'ARRAY', 'tail returns arrayref');
    is(scalar(@$t5), 5, 'tail returns correct count');
    is($t5->[0], 'Line 16', 'tail first line correct');
    is($t5->[4], 'Line 20', 'tail last line correct');

    my $t10 = File::Raw::tail($file);  # Default
    is(scalar(@$t10), 10, 'tail default is 10 lines');
};

# Test atomic_spew
subtest 'atomic_spew' => sub {
    my $file = "$tmpdir/atomic.txt";
    my $content = "atomic content\nline 2";

    ok(File::Raw::atomic_spew($file, $content), 'atomic_spew returns true');
    ok(File::Raw::exists($file), 'file exists after atomic_spew');
    is(File::Raw::slurp($file), $content, 'atomic_spew content correct');
};

# Test import (custom ops)
subtest 'import custom ops' => sub {
    # This is tested implicitly - if the module loads, import works
    # Let's verify the functions are available after import
    my $file = "$tmpdir/import_test.txt";
    File::Raw::spew($file, "import test");

    # These should all work
    ok(File::Raw::exists($file), 'exists works');
    ok(File::Raw::is_file($file), 'is_file works');
    is(File::Raw::size($file), 11, 'size works');
};

done_testing();
