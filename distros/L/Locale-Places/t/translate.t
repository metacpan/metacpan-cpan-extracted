#!perl -wT

use strict;
use warnings;
use Test::Most tests => 7;

BEGIN {
	use_ok('Locale::Places');
}

TRANSLATE: {
	my $places = new_ok('Locale::Places');

	like($places->translate(place => 'London', from => 'en', to => 'fr'), qr/Londres$/, 'French for London is Londres');
	like($places->translate(place => 'Londres', from => 'fr', to => 'en'), qr/London$/, 'English for Londres is London');
	is($places->translate({ place => 'foo', from => 'bar' }), undef, 'Translating gibberish returns undef');

	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LANG'};

	$ENV{'LANGUAGE'} = 'en';
	is($places->translate({ place => 'Dover', 'from' => 'en' }), 'Dover', 'LANGUAGE set to English');

	delete $ENV{'LANGUAGE'};

	$ENV{'LANG'} = 'fr_FR';
	is($places->translate(place => 'Dover', 'from' => 'en'), 'Douvres', 'LANG set to French');

}
