#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Gzip::Zopfli 'ZopfliCompress';
my $in = 'something' x 1000;
my $out = ZopfliCompress ($in);
print length ($out), ' ', length ($in), "\n";

