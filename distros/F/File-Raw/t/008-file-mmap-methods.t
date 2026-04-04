#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempfile);

# Test mmap::data
my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh "Hello, World!";
close $fh;

my $mmap = File::Raw::mmap_open($filename);
isa_ok($mmap, 'File::Raw::mmap', 'mmap_open returns mmap object');

my $data = $mmap->data();
is($data, "Hello, World!", 'mmap::data returns file content');

# Test mmap::sync (no-op on read-only, but should not crash)
eval { $mmap->sync(); };
ok(!$@, 'mmap::sync does not crash');

# Test mmap::close (returns undef but should not crash)
eval { $mmap->close(); };
ok(!$@, 'mmap::close completes without error');

# Test double close (should be safe)
eval { $mmap->close(); };
ok(!$@, 'mmap::close double call is safe');

done_testing();
