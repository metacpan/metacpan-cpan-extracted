#!perl -wT

use strict;
use warnings;
use Test::Most tests => 34;
use Test::NoWarnings;

BEGIN {
	use_ok('Lingua::Text');
}

STRING: {
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LANG'};
	$ENV{'LC_MESSAGES'} = 'en_GB';

	my $str = new_ok('Lingua::Text');

	is($str->en('Hello'), 'Hello', 'Set English');

	is($str->as_string(), 'Hello', 'English');

	is($str->fr('Bonjour'), 'Bonjour', 'Set French');

	is($str->as_string(), 'Hello', 'English');
	is($str->fr(), 'Bonjour', 'French');

	is($str->as_string(), 'Hello', 'English');
	is($str->as_string(lang => 'fr'), 'Bonjour', 'French');
	is($str->as_string('fr'), 'Bonjour', 'French');
	is($str->as_string({ lang => 'es' }), undef, 'Spanish');

	is($str, 'Hello', 'calls as_string in English');
	$ENV{'LC_MESSAGES'} = 'fr_FR';
	is($str, 'Bonjour', 'calls as_string in French');
	$ENV{'LC_MESSAGES'} = 'en_GB';

	is($str->set({ lang => 'en', text => 'xyzzy' }), 'xyzzy', 'Set xyzzy hash ref');
	is($str->as_string(), 'xyzzy', 'Set works with explicit language');
	is($str->set(lang => 'en', text => 'Goodbye'), 'Goodbye', 'Set Goodbye hash');
	is($str->as_string(), 'Goodbye', 'Set works with explicit language');
	is($str->as_string(), 'Goodbye', 'Set works with explicit language');
	is($str->set('House'), 'House', 'Set House');
	is($str->as_string(), 'House', 'Set works with implicit language');
	$ENV{'LC_MESSAGES'} = 'fr_FR';
	is($str->as_string(), 'Bonjour', 'Implicit language sets the correct place');
	$ENV{'LC_MESSAGES'} = 'en_GB';

	$str = new_ok('Lingua::Text' => [ ('en' => 'and', 'fr' => 'et', 'de' => 'und') ]);
	is($str->de(), 'und', 'Initialisation list of strings works');
	is($str, 'and', 'Initialisation list works with overload');

	$str = new_ok('Lingua::Text' => [ ('en' => 'hotel', 'fr' => 'hôtel') ])->encode();
	is($str->fr(), 'h&ocirc;tel', 'HTML Entities encode - UTF8');
	$str = new_ok('Lingua::Text' => [ {'en' => 'hotel', 'fr' => "h\N{U+00F4}tel"} ])->encode();
	is($str->fr(), 'h&ocirc;tel', 'HTML Entities encode - Unicode');

	$str = new_ok('Lingua::Text' => [ 'One' ]);
	is($str->en(), 'One', 'Default language is set on single argument');
	is($str->as_string({ lang => 'de' }), undef, 'German');

	delete $ENV{'LC_MESSAGES'};
	$ENV{'LANGUAGE'} = 'en';
	$str = new_ok('Lingua::Text' => [ 'One' ]);
	$str->set('House');
	cmp_ok($str->en('House'), 'eq', 'House', 'Setting language from LANGUAGE works with AUTOLOAD');
}
