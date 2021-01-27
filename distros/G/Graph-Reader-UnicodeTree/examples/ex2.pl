#!/usr/bin/env perl

use strict;
use warnings;

use Graph::Reader::UnicodeTree;

if (@ARGV < 1) {
        print STDERR "Usage: $0 data_file\n";
        exit 1;
}
my $data_file = $ARGV[0];

# Reader object.
my $obj = Graph::Reader::UnicodeTree->new;

# Get graph from file.
my $g = $obj->read_graph($data_file);

# Print to output.
print $g."\n";

# Output like:
# 1-10,1-2,1-3,1-5,1-6,3-4,6-7,6-8,6-9