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
1 First node
2 Second node
#
1 2 Edge between the two
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