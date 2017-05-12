#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Graph::Reader::UnicodeTree;
use IO::Barf qw(barf);
use File::Temp qw(tempfile);

# Example data.
my $data = decode_utf8(<<'END');
1─┬─2
  ├─3───4
  ├─5
  ├─6─┬─7
  │   ├─8
  │   └─9
  └─10
END

# Temporary file.
my (undef, $tempfile) = tempfile();

# Save data to temp file.
barf($tempfile, encode_utf8($data));

# Reader object.
my $obj = Graph::Reader::UnicodeTree->new;

# Get graph from file.
my $g = $obj->read_graph($tempfile);

# Clean temporary file.
unlink $tempfile;

# Print to output.
print $g."\n";

# Output:
# 1-10,1-2,1-3,1-5,1-6,3-4,6-7,6-8,6-9