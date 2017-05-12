#!perl -wT

use strict;
use warnings;
use Test::Most tests => 7;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::CA');
}

NEW: {
	my $u = new_ok('Locale::CA');

	my $code = 'ON';
	my $province = 'ONTARIO';

	ok(defined($u->{code2province}{$code}));
	ok($u->{code2province}{$code} eq $province);

	ok(defined($u->{province2code}{$province}));
	ok($u->{province2code}{$province} eq $code);
}
