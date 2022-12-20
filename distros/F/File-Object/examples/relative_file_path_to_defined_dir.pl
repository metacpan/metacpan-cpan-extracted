#!/usr/bin/env perl

use strict;
use warnings;

use File::Object;

# Object with directory path.
my $obj = File::Object->new(
        'dir' => ['path', 'to', 'subdir'],
);

# Relative path to file1.
print $obj->file('file1')->s."\n";

# Relative path to file2.
print $obj->file('file2')->s."\n";

# Output:
# Unix:
# path/to/subdir/file1
# path/to/subdir/file2
# Windows:
# path\to\subdir\file1
# path\to\subdir\file2