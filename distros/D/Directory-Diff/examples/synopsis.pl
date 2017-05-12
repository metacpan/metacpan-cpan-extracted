#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Directory::Diff 'directory_diff';

# Do a "diff" between "old_dir" and "new_dir"

directory_diff ('old_dir', 'new_dir', 
	    {diff => \& diff,
	     dir1_only => \& old_only});

# User-supplied callback for differing files

sub diff
{
    my ($data, $dir1, $dir2, $file) = @_;
    print "$dir1/$file is different from $dir2/$file.\n";
}

# User-supplied callback for files only in one of the directories

sub old_only
{
    my ($data, $dir1, $file) = @_;
    print "$file is only in the old directory.\n";
}

