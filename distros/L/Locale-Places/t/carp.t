#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 11;

BEGIN {
	use_ok('Locale::Places');
}

CARP: {
	my $places = new_ok('Locale::Places');

	does_croak_that_matches(sub { $places->translate() }, qr/Usage/);
	does_carp_that_matches(sub { $places->translate('me' => 'tulip') }, qr/usage/);
	does_carp_that_matches(sub { $places->translate({ from => 'en' }) }, qr/usage/);
	does_carp_that_matches(sub { $places->translate({ from => 'x' }) }, qr/usage/);
	does_croak_that_matches(sub { Locale::Places->translate({ from => 'x' }) }, qr/must be called on an object/);

	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LANG'};
	$ENV{'LANGUAGE'} = 'x';	# Invalid locale

	does_carp_that_matches(sub { $places->translate('London') }, qr/can't work out which language to translate to/);
	does_carp_that_matches(sub { $places->translate({ place => 'London', from => 'y' }) }, qr/can't work out which language to translate to/);

	delete $ENV{'LANGUAGE'};

	does_carp_that_matches(sub { $places->translate('London') }, qr/can't work out which language to translate to/);

	does_carp_that_matches(sub { $places->translate(place => 'Dover', from => undef) }, qr/usage/);
}
