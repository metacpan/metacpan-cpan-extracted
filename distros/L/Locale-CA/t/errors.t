#!perl -wT

use strict;
use warnings;
use Test::Most tests => 3;

BEGIN {
	use_ok('Locale::CA');
}

ERRORS: {
	eval 'use Test::Exception';
	if($@) {
		plan(skip_all => 'Test::Exception required for testing errors');
	} else {
		dies_ok {
			my $u = Locale::CA->new({ lang => 'de' });
		} 'only supports en and fr';
		ok($@ =~ /lang can only be one of/);
	}
}
