#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Temp qw(tempfile);
use Image::Checkerboard;

# Temporary file.
my (undef, $temp) = tempfile();

# Object.
my $obj = Image::Checkerboard->new;

# Create image.
my $type = $obj->create($temp);

# Print out type.
print $type."\n";

# Unlink file.
unlink $temp;

# Output:
# bmp