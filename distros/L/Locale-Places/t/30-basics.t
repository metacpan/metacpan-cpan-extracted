#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::Most;
use Locale::Places;

if((!defined($ENV{'AUTOMATED_TESTING'}) && (!defined($ENV{'NO_NETWORK_TESTING'})) && (-d 'lib/Locale/Places/data'))) {
	plan tests => 4;
} else {
	plan skip_all => 'Not testing live data';
}

subtest 'Instantiation' => sub {
	my $places = new_ok('Locale::Places');

	my $custom_dir = '/custom/path';
	my $places_with_dir = Locale::Places->new({ directory => $custom_dir });
	isa_ok($places_with_dir, 'Locale::Places', 'Object with custom directory');
	is($places_with_dir->{'directory'}, File::Spec->catfile($custom_dir, 'data'), 'Custom directory set correctly');
};

subtest 'Translation' => sub {
	my $places = Locale::Places->new();

	can_ok($places, 'translate');

	# Valid translation
	my $translated = $places->translate({
		place => 'London',
		from => 'en',
		to => 'fr',
		country => 'GB'
	});
	is($translated, 'Londres', 'Translation to French for London');

	# Invalid translation
	my $not_found = $places->translate({
		place => 'NonexistentPlace',
		from => 'en',
		to => 'fr',
		country => 'GB'
	});
	is($not_found, undef, 'Returns undef if translation not found');
};

subtest 'Language detection' => sub {
	local %ENV;
	local $ENV{'LANGUAGE'} = 'fr_FR.UTF-8';
	my $places = Locale::Places->new();
	is($places->_get_language(), 'fr', 'Detects LANGUAGE variable');

	local $ENV{'LANG'} = 'en_US.UTF-8';
	delete $ENV{'LANGUAGE'};
	is($places->_get_language(), 'en', 'Detects LANG variable');
};

subtest 'AUTOLOAD translations' => sub {
	my $places = Locale::Places->new();

	# Valid translation
	my $fr_translation = $places->fr({
		place => 'Dover',
		from => 'en',
		country => 'GB'
	});
	is($fr_translation, 'Douvres', 'AUTOLOAD translation to French works');

	# Invalid method
	ok(!defined($places->unknown_language({ place => 'Virginia' })));
};
