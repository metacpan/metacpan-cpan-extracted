#! /usr/bin/env perl
#---------------------------------------------------------------------
# This example is hereby placed in the public domain.
# You may copy from it freely.
#
# Detect the encoding of files given on the command line
#---------------------------------------------------------------------

use strict;
use warnings;

use IO::HTML qw(html_file_and_encoding);

for my $filename (@ARGV) {
  my ($filehandle, $encoding, $bom) = html_file_and_encoding($filename);

  close $filehandle;
  $encoding .= " BOM=$bom" if defined $bom;
  print "$filename: $encoding\n";
}
