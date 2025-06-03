#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);

use File::Temp;
use Test::Most tests => 9;

# Check if the module loads
use_ok('File::Open::NoCache::ReadOnly');

# Create an object with a valid file
my $test_file = File::Temp->new(UNLINK => 1);
open my $fh, '>', $test_file or BAIL_OUT("Could not create test file: $!");
print $fh "Test content\n";
close $fh;

my $object = File::Open::NoCache::ReadOnly->new(filename => $test_file);
isa_ok($object, 'File::Open::NoCache::ReadOnly', 'Object created successfully');

# Ensure file descriptor is valid
my $fd = $object->fd();
ok(defined $fd, 'File descriptor is valid');
ok(fileno($fd), 'File descriptor has a file number');

# Test reading from the file
my $line = <$fd>;
is($line, "Test content\n", 'Read content matches expected');

# Close the object
$object->close();
ok(!$object->fd(), 'File descriptor closed');

# Attempting to close again should warn
warnings_like { $object->close() } [qr/Attempt to close object twice/], 'Warning on double close';

$object = File::Open::NoCache::ReadOnly->new($test_file);
isa_ok($object, 'File::Open::NoCache::ReadOnly', 'Object created successfully');

# Test reading from the file
$line = $object->readline();
is($line, "Test content\n", 'Read content matches expected');

# Close the object
$object->close();

# Cleanup
unlink $test_file;	# File::Temp should do this anyway
