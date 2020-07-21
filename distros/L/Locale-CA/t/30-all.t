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

	ok(scalar(@p) == 12);	# There are 12 provinces

	foreach my $p(@p) {
		ok(length($p) == 2);
	}

	@p = $u->all_province_names();

	ok(scalar(@p) == 12);
}
