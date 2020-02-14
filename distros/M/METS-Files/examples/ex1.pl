#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use METS::Files;
use Perl6::Slurp qw(slurp);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 mets_file\n";
        exit 1;
}
my $mets_file = $ARGV[0];

# Get mets data.
my $mets_data = slurp($mets_file);

# Object.
my $obj = METS::Files->new(
        'mets_data' => $mets_data,
);

# Get files.
my $files_hr;
foreach my $use ($obj->get_use_types) {
        $files_hr->{$use} = [$obj->get_use_files($use)];
}

# Dump to output.
p $files_hr;

# Output without arguments like:
# Usage: __SCRIPT__ mets_file