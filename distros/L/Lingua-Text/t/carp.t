#!perl -wT

use strict;
use warnings;
use Test::Carp;
use Test::Most tests => 9;

BEGIN {
	use_ok('Lingua::Text');
}

CARP: {
	my $str = new_ok('Lingua::Text');

	does_croak_that_matches(sub { $str->set() }, qr/Usage/);
	does_carp_that_matches(sub { $str->set('lang' => 'foo') }, qr/usage/);
	does_carp_that_matches(sub { $str->set('foo' => 'bar') }, qr/usage/);

	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LANG'};
	$ENV{'LANGUAGE'} = 'x';	# Invalid locale

	$str = new_ok('Lingua::Text' => [ \('en' => 'and', 'fr' => 'et', 'de' => 'und') ]);

	does_carp_that_matches(sub { $str->as_string() }, qr/usage/);

	does_carp_that_matches(sub { $str->set(lang => 'en', string => undef) }, qr/usage/);

	$ENV{'LANGUAGE'} = 'en_GB';

	does_croak_that_matches(sub { $str = Lingua::Text->new('one', 'two', 'three') }, qr/Usage/);
}
