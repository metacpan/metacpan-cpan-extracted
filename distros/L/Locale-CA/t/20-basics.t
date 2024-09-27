#!perl -wT

use strict;
use warnings;
use Test::Most tests => 24;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::CA');
}

BASICS: {
	my $code = 'NB';
	my $province_en = 'NEW BRUNSWICK';
	my $province_fr = 'NOUVEAU-BRUNSWICK';

	delete $ENV{'LC_ALL'};
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_MESSAGES'};	# http://www.cpantesters.org/cpan/report/147792c2-7b94-11ef-9c4f-aa1bc4b6c371
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

	$u = new_ok('Locale::CA' => [
		lang => 'fr'
	]);

	ok(defined($u->{code2province}{$code}));
	ok($u->{code2province}{$code} eq $province_fr);
	ok($u->{province2code}{'QUÉBEC'} eq 'QC');

	ok(defined($u->{province2code}{$province_fr}));
	ok($u->{province2code}{$province_fr} eq $code);

	$u = new_ok('Locale::CA' => [ 'fr' ]);

	ok(defined($u->{code2province}{$code}));
	ok($u->{code2province}{$code} eq $province_fr);
	ok($u->{province2code}{'QUÉBEC'} eq 'QC');

	ok(defined($u->{province2code}{$province_fr}));
	ok($u->{province2code}{$province_fr} eq $code);
}
