#!perl -wT

use strict;
use warnings;
use Test::Most tests => 17;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::CA');
}

ALL: {
	my $u = new_ok('Locale::CA');

	my @p = $u->all_province_codes();

	cmp_ok(scalar(@p), '==', 12, 'There are 12 provinces');

	foreach my $p(@p) {
		cmp_ok(length($p), '==', 2, "$p should be two letters");
	}

	@p = $u->all_province_names();

	cmp_ok(scalar(@p), '==', 12, 'There are 12 provinces');
}
