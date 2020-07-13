#!perl -wT

use strict;
use warnings;
use Test::Most tests => 12;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::CA');
}

NEW: {
	my $code = 'NB';
	my $province_en = 'NEW BRUNSWICK';
	my $province_fr = 'NOUVEAU-BRUNSWICK';

	$ENV{'LANG'} = 'fr_FR';
	my $u = new_ok('Locale::CA');

	ok(defined($u->{code2province}{$code}));
	ok($u->{code2province}{$code} eq $province_fr);

	ok(defined($u->{province2code}{$province_fr}));
	ok($u->{province2code}{$province_fr} eq $code);

	delete($ENV{'LANG'});
	$u = new_ok('Locale::CA');

	ok(defined($u->{code2province}{$code}));
	ok($u->{code2province}{$code} eq $province_en);

	ok(defined($u->{province2code}{$province_en}));
	ok($u->{province2code}{$province_en} eq $code);
}
