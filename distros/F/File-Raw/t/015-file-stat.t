#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempfile tempdir);

# Create a test file
my ($fh, $test_file) = tempfile(UNLINK => 1);
print $fh "hello world\n";
close $fh;

# Test stat returns hashref
my $st = File::Raw::stat($test_file);
ok(defined $st, 'stat returns defined value');
is(ref $st, 'HASH', 'stat returns hashref');

# Test all expected keys exist
my @expected_keys = qw(size mtime atime ctime mode is_file is_dir dev ino nlink uid gid);
for my $key (@expected_keys) {
    ok(exists $st->{$key}, "stat has key: $key");
}

# Test values are correct
is($st->{size}, 12, 'size is correct');
ok($st->{mtime} > 0, 'mtime is positive epoch');
ok($st->{atime} > 0, 'atime is positive epoch');
ok($st->{ctime} > 0, 'ctime is positive epoch');
ok($st->{mode} >= 0 && $st->{mode} <= 0777, 'mode is valid permission bits');
ok($st->{is_file}, 'is_file is true');
ok(!$st->{is_dir}, 'is_dir is false');
ok($st->{ino} > 0, 'ino is positive');
ok($st->{nlink} >= 1, 'nlink is at least 1');

# Test stat on directory
my $test_dir = tempdir(CLEANUP => 1);
my $st_dir = File::Raw::stat($test_dir);
ok(defined $st_dir, 'stat on dir returns defined value');
ok(!$st_dir->{is_file}, 'dir is_file is false');
ok($st_dir->{is_dir}, 'dir is_dir is true');

# Test stat on non-existent file
my $st_none = File::Raw::stat('/nonexistent/file/path/12345');
ok(!defined $st_none, 'stat on non-existent file returns undef');

# Test that stat values match individual function calls
my $size  = File::Raw::size($test_file);
my $mtime = File::Raw::mtime($test_file);
my $atime = File::Raw::atime($test_file);
my $ctime = File::Raw::ctime($test_file);
my $mode  = File::Raw::mode($test_file);

$st = File::Raw::stat($test_file);
is($st->{size}, $size, 'stat size matches size()');
is($st->{mtime}, $mtime, 'stat mtime matches mtime()');
is($st->{atime}, $atime, 'stat atime matches atime()');
is($st->{ctime}, $ctime, 'stat ctime matches ctime()');
is($st->{mode}, $mode, 'stat mode matches mode()');

# Test stat cache invalidation on write
subtest 'stat cache invalidation' => sub {
    my ($fh2, $cache_file) = tempfile(UNLINK => 1);
    print $fh2 "initial";
    close $fh2;
    
    my $size_before = File::Raw::size($cache_file);
    is($size_before, 7, 'initial size is 7');
    
    # Write more data using File::Raw::spew (should invalidate cache)
    File::Raw::spew($cache_file, "much longer content here");
    
    my $size_after = File::Raw::size($cache_file);
    is($size_after, 24, 'size updated after spew (cache invalidated)');
    
    # Test append also invalidates cache
    File::Raw::append($cache_file, "!");
    my $size_appended = File::Raw::size($cache_file);
    is($size_appended, 25, 'size updated after append');
};

# Test clear_stat_cache function
subtest 'clear_stat_cache' => sub {
    my ($fh3, $clear_file) = tempfile(UNLINK => 1);
    print $fh3 "test";
    close $fh3;
    
    my $size1 = File::Raw::size($clear_file);
    is($size1, 4, 'initial size is 4');
    
    # Write directly bypassing File::Raw (simulating external process)
    open my $ext_fh, '>', $clear_file or die $!;
    print $ext_fh "longer content";
    close $ext_fh;
    
    # Size should still be cached (wrong value)
    my $cached_size = File::Raw::size($clear_file);
    is($cached_size, 4, 'cached size still returns old value');
    
    # Clear the cache
    File::Raw::clear_stat_cache($clear_file);
    
    # Now should get fresh value
    my $fresh_size = File::Raw::size($clear_file);
    is($fresh_size, 14, 'fresh size after clear_stat_cache');
    
    # Test clear_stat_cache with no args
    open $ext_fh, '>', $clear_file or die $!;
    print $ext_fh "x";
    close $ext_fh;
    
    File::Raw::clear_stat_cache();  # Clear all
    my $size_all = File::Raw::size($clear_file);
    is($size_all, 1, 'size correct after clear_stat_cache() with no args');
};

done_testing();
