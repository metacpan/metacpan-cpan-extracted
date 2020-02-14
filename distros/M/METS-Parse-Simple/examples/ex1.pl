#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use METS::Parse::Simple;
use Perl6::Slurp qw(slurp);

if (@ARGV < 1) {
        print STDERR "Usage: $0 mets_file\n";
        exit 1;
}
my $mets_file = $ARGV[0];

# Get mets data.
my $mets_data = slurp($mets_file);

# Object.
my $obj = METS::Parse::Simple->new;

# Parse data.
my $mets_hr = $obj->parse($mets_data);

# Dump to output.
p $mets_hr;

# Output without argument like:
# Usage: __SCRIPT__ mets_file