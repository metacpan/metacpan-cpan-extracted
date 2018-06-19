#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::EN::PluralToSingular qw/to_singular is_plural/;
my @words = qw/knives sheep dog dogs cannabis/;
for my $word (@words) {
    if (is_plural ($word)) {
	my $sing = to_singular ($word);
	print "The singular of '$word' is '$sing'.\n";
    }
    else {
	print "'", ucfirst ($word), "' is not plural.\n";
    }
}
