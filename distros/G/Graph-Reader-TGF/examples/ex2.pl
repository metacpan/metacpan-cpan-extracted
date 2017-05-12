#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::TGF;
use IO::Barf qw(barf);
use File::Temp qw(tempfile);

# Example data.
my $data = <<'END';
1 Node #1
2 Node #2
3 Node #3
4 Node #4
5 Node #5
6 Node #6
7 Node #7
8 Node #8
9 Node #9
10 Node #10
#
1 2
1 3
1 5
1 6
1 10
3 4
6 7
6 8
6 9
END

# Temporary file.
my (undef, $tempfile) = tempfile();

# Save data to temp file.
barf($tempfile, $data);

# Reader object.
my $obj = Graph::Reader::TGF->new;

# Get graph from file.
my $g = $obj->read_graph($tempfile);

# Print to output.
print $g."\n";

# Clean temporary file.
unlink $tempfile;

# Output:
# 1-10,1-2,1-3,1-5,1-6,3-4,6-7,6-8,6-9