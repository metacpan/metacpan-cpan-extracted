#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Gzip::Zopfli 'zopfli_compress';
my $in = 'something' x 1000;
my $out = zopfli_compress ($in);
print length ($out), ' ', length ($in), "\n";

