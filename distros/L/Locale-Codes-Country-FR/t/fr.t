#!perl -wT

use strict;
use warnings;
use Test::Most tests => 9;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::Codes::Country::FR');
}

FR: {
	ok(Locale::Codes::Country::FR::country2fr('England') eq 'Angleterre');
	ok(Locale::Codes::Country::FR::en_country2gender('England') eq 'F');
	my $l = new_ok('Locale::Codes::Country::FR');
	ok($l->country2fr('England') eq 'Angleterre');
	ok($l->en_country2gender('England') eq 'F');
	ok($l->en_country2gender('Canada') eq 'M');
	ok($l->en_country2gender('Mexico') eq 'M');
}
