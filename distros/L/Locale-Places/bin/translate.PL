#!/usr/bin/env perl

# Translate the given place into the given language
#	"translate.PL Dover fr" will print Douvres
#	"translate.PL England fr" will print Angleterre

use strict;
use warnings;
use Locale::Places;

die 'Arg count' unless(scalar(@ARGV) == 2);

my $place = ucfirst(lc($ARGV[0]));
my $language = lc($ARGV[1]);
if($language !~ /^[a-z]{2}$/) {
	die "$0: Usage place language-code";
}

print Locale::Places->new()->translate(place => $place, from => 'en', to => $language), "\n";
