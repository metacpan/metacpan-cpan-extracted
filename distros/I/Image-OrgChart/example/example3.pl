#!/usr/bin/perl

#### Font Example

require '../OrgChart.pm';
use strict;

print "OrgChart [v$Image::OrgChart::VERSION]\n";

my %hash = ();
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
my $t = Image::OrgChart->new(
                             font => 'gdGiantFont',
                             );
$t->set_hashref(\%hash);

my $file = $0 . $t->data_type;

open(OUT,"> $file") || die "Could not open output file : $1";
binmode(OUT);
print OUT $t->draw();
close(OUT);
