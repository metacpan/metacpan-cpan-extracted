#!/usr/bin/perl

#### Arrowhead Example

require '../OrgChart.pm';
use strict;
$|=1;

print "OrgChart [v$Image::OrgChart::VERSION]\n";

my %hash = ();
$hash{bar} = {
	      'foo1' => {},
	      'foo234567891011' => {
                                    a => {},
                                    b => {
                                      222 => {},
                                      553 => {},
                                      554 => {},
                                      555 => {},
                                    },
                                    c => {
                                    },
                                    },
             };
my $t = Image::OrgChart->new(
                             font        => 'gdGiantFont',
                             arrow_heads => 1,
                             );
$t->set_hashref(\%hash);

my $file = $0 . $t->data_type;

open(OUT,"> $file") || die "Could not open output file : $1";
binmode(OUT);
print OUT $t->draw();
close(OUT);
