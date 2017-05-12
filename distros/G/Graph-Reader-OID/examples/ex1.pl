#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Graph::Reader::OID;
use IO::Barf qw(barf);
use File::Temp qw(tempfile);

# Example data.
my $data = <<'END';
1.2.410.200047.11.2013.10234913023321120142141561581 Label #1
1.2.276.0.7230010.3.0.3.6.1 Label #2
END

# Temporary file.
my (undef, $tempfile) = tempfile();

# Save data to temp file.
barf($tempfile, $data);

# Reader object.
my $obj = Graph::Reader::OID->new;

# Get graph from file.
my $g = $obj->read_graph($tempfile);

# Print to output.
print $g."\n";

# Clean temporary file.
unlink $tempfile;

# Output:
# 1-1.2,1.2-1.2.276,1.2-1.2.410,1.2.276-1.2.276.0,1.2.276.0-1.2.276.0.7230010,1.2.276.0.7230010-1.2.276.0.7230010.3,1.2.276.0.7230010.3-1.2.276.0.7230010.3.0,1.2.276.0.7230010.3.0-1.2.276.0.7230010.3.0.3,1.2.276.0.7230010.3.0.3-1.2.276.0.7230010.3.0.3.6,1.2.276.0.7230010.3.0.3.6-1.2.276.0.7230010.3.0.3.6.1,1.2.410-1.2.410.200047,1.2.410.200047-1.2.410.200047.11,1.2.410.200047.11-1.2.410.200047.11.2013,1.2.410.200047.11.2013-1.2.410.200047.11.2013.10234913023321120142141561581