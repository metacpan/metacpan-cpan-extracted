#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;
use Test::Most tests => 5;
use Test::NoWarnings;

use_ok('File::Print::Many');

# Create temporary files for testing
my $file1 = File::Temp->new();
my $file2 = File::Temp->new();

# Open file handles
open(my $fh1, '>', $file1->filename) or die "Cannot open file: $!";
open(my $fh2, '>', $file2->filename) or die "Cannot open file: $!";

# Create a File::Print::Many object
my $many;
eval { $many = File::Print::Many->new(fds => [$fh1, $fh2]) };
ok(defined $many, 'File::Print::Many object created successfully');

# Print to multiple file descriptors
$many->print("Hello, world!\n");
$many->print("Another line.\n");

# Close file handles
close($fh1);
close($fh2);

# Verify the contents of the files
open(my $rfh1, '<', $file1->filename()) or die "Cannot open file: $!";
open(my $rfh2, '<', $file2->filename()) or die "Cannot open file: $!";

my $content1 = do { local $/; <$rfh1> };
my $content2 = do { local $/; <$rfh2> };

close($rfh1);
close($rfh2);

# Test: Contents of the first file
is($content1, "Hello, world!\nAnother line.\n", "File 1 contains the expected output");

# Test: Contents of the second file
is($content2, "Hello, world!\nAnother line.\n", "File 2 contains the expected output");
