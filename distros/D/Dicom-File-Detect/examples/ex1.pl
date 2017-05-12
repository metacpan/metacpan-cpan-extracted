#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::File::Detect qw(dicom_detect_file);
use File::Temp qw(tempfile);
use IO::Barf qw(barf);
use MIME::Base64;

# Data in base64.
my $data = <<'END';
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAABESUNNCg==
END

# Temp file.
my (undef, $temp_file) = tempfile();

# Save data to file.
barf($temp_file, decode_base64($data));

# Check file.
my $dcm_flag = dicom_detect_file($temp_file);

# Print out.
if ($dcm_flag) {
        print "File '$temp_file' is DICOM file.\n";
} else {
        print "File '$temp_file' isn't DICOM file.\n";
}

# Output like:
# File '%s' is DICOM file.