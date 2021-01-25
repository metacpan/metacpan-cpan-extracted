#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 6;

BEGIN {
	use_ok('Lingua::String');
}

CARP: {
	does_carp_that_matches(sub { Lingua::String->new('foo') }, qr/usage/);

	my $str = new_ok('Lingua::String');

	does_carp_that_matches(sub { $str->set() }, qr/usage/);

	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LANG'};
	$ENV{'LANGUAGE'} = 'x';	# Invalid locale

	$str = new_ok('Lingua::String' => [ \('en' => 'and', 'fr' => 'et', 'de' => 'und') ]);

	does_carp_that_matches(sub { $str->as_string() }, qr/usage/);
}
