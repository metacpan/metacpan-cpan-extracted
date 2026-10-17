#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::RequiresInternet;
use Test::Most tests => 8;

BEGIN {
	use_ok('Locale::Places');
}

CARP: {
	my $places = new_ok('Locale::Places');

	throws_ok(sub { $places->translate() }, qr/Usage/, 'translate() with no arguments dies with usage');
	does_croak_that_matches(sub { Locale::Places->translate({ from => 'fr' }) }, qr/must be called on an object/);

	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LANG'};
	$ENV{'LANGUAGE'} = 'x';	# Invalid locale

	does_carp_that_matches(sub { $places->translate('London') }, qr/can't work out which language to translate to/);
	does_carp_that_matches(sub { $places->translate({ place => 'London', from => 'en' }) }, qr/can't work out which language to translate to/);

	delete $ENV{'LANGUAGE'};

	does_carp_that_matches(sub { $places->translate('London') }, qr/can't work out which language to translate to/);

	does_carp_that_matches(sub { $places->translate(place => 'Dover', from => undef) }, qr/usage/);
}
