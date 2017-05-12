#!/usr/bin/perl

## Stamdard Example

use lib '../blib';                    
use Image::OrgChart;

use strict;

my %hash = ();
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
my $t = Image::OrgChart->new();
$t->set_hashref(\%hash);

my $file = $0 . $t->data_type;

open(OUT,"> $file") || die "Could not open output file : $1";
binmode(OUT);
print OUT $t->draw();
close(OUT);
