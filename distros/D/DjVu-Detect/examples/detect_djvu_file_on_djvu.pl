#!/usr/bin/env perl

use strict;
use warnings;

use DjVu::Detect qw(detect_djvu_file);
use File::Temp qw(tempfile);
use IO::Barf qw(barf);
use MIME::Base64;

# Data in base64.
my $data = <<'END';
QVQmVEZPUk0=
END

# Temp file.
my (undef, $temp_file) = tempfile();

# Save data to file.
barf($temp_file, decode_base64($data));

# Check file.
my $is_djvu = detect_djvu_file($temp_file);

# Print out.
if ($is_djvu) {
        print "File '$temp_file' is DjVu file.\n";
} else {
        print "File '$temp_file' isn't DjVu file.\n";
}

# Output like:
# File '%s' is DjVu file.