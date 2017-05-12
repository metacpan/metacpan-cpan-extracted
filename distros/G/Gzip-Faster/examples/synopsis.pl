#!/home/ben/software/install/perl
use warnings;
use strict;
# Make a random input string
my $input = join '', map {int (rand (10))} 0..0x1000;
use Gzip::Faster;
# Compress the random string.
my $gzipped = gzip ($input);
# Uncompress it again.
my $roundtrip = gunzip ($gzipped);
# Put it into a file.
gzip_to_file ($input, 'file.gz');
# Retrieve it again from the file.
$roundtrip = gunzip_file ('file.gz');
