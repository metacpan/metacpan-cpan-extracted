#!/usr/local/bin/perl

use diagnostics;
use strict;
use warnings;
use Digest::Haval256;
use MIME::Base64;

my $file = "strings.pl";
open INFILE, $file or die "$file not found";

my $haval = new Digest::Haval256;
$haval->addfile(*INFILE);
my $hex_output = $haval->hexdigest();
my $base64_output = $haval->base64digest();
close INFILE;
print "$file\n";
print "$hex_output\n";
print "$base64_output\n";

