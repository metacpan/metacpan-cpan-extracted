#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;

# Object with directory path.
my $obj = File::Object->new(
        'dir' => ['path', 'to', 'subdir'],
);

# Relative path to dir1.
print $obj->dir('dir1')->s."\n";

# Relative path to dir2.
print $obj->reset->dir('dir2')->s."\n";

# Output:
# Unix:
# path/to/subdir/dir1
# path/to/subdir/dir2
# Windows:
# path\to\subdir\dir1
# path\to\subdir\dir2