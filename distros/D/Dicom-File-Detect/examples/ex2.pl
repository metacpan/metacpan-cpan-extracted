#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::File::Detect qw(dicom_detect_file);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 file\n";
        exit 1;
}
my $file = $ARGV[0];

# Check file.
my $dcm_flag = dicom_detect_file($file);

# Print out.
if ($dcm_flag) {
        print "File '$file' is DICOM file.\n";
} else {
        print "File '$file' isn't DICOM file.\n";
}

# Output:
# Usage: dicom-detect-file file