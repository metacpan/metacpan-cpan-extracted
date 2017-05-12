#!/usr/bin/perl

## Color Example

require '../OrgChart.pm';
use strict;

print "OrgChart [v$Image::OrgChart::VERSION]\n";

my %hash = ();
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
my $t = Image::OrgChart->new(box_fill_color => [255,0,0],
                             fill_boxes => 1,

                             );
$t->set_hashref(\%hash);

my $file = $0 . $t->data_type;

open(OUT,"> $file") || die "Could not open output file : $1";
binmode(OUT);
print OUT $t->draw();
close(OUT);
