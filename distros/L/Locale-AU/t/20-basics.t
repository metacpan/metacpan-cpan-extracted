#!perl -wT

use strict;
use warnings;
use Test::Most tests => 7;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::AU');
}

NEW: {
	my $u = new_ok('Locale::AU');

	my $code = 'NSW';
	my $state = 'NEW SOUTH WALES';

	ok(defined($u->{code2state}{$code}));
	ok($u->{code2state}{$code} eq $state);

	ok(defined($u->{state2code}{$state}));
	ok($u->{state2code}{$state} eq $code);
}
