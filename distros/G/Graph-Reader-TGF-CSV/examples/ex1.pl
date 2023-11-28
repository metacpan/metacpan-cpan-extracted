#!/usr/bin/env perl

use strict;
use warnings;

use Graph::Reader::TGF::CSV;
use IO::Barf qw(barf);
use File::Temp qw(tempfile);

# Example data.
my $data = <<'END';
1 label=First node,green=red
2 label=Second node,green=cyan
#
1 2 label=Edge between the two,color=green
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
# 1-2