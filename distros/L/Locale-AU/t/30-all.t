#!perl -wT

use strict;
use warnings;
use Test::Most tests => 13;
use Test::NoWarnings;

BEGIN {
	use_ok('Locale::AU');
}

ALL: {
	my $u = new_ok('Locale::AU');

	my @s = $u->all_state_codes();

	ok(scalar(@s) == 8);

	foreach my $s(@s) {
		ok((length($s) == 2) || (length($s) == 3))
	}

	@s = $u->all_state_names();

	ok(scalar(@s) == 8);
}
