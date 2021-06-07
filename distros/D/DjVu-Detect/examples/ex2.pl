#!/usr/bin/env perl

use strict;
use warnings;

use DjVu::Detect qw(detect_djvu_file);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 file\n";
        exit 1;
}
my $file = $ARGV[0];

# Check DjVu file.
my $is_djvu = detect_djvu_file($file);

# Print out.
if ($is_djvu) {
        print "File '$file' is DjVu file.\n";
} else {
        print "File '$file' isn't Djvu file.\n";
}

# Output:
# Usage: __SCRIPT__ file