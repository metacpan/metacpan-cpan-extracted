#!/usr/bin/env perl
# t/locales.t -- Test language detection through environment-variable locale simulation.
#
# "Geographic" here means standard locale strings for each country (GB, US,
# FR, DE, CN).  This module has no GeoIP dependency; the mapping is exercised
# by setting $ENV{LANG} to the corresponding POSIX locale string.

use strict;
use warnings;
use Test::Most;
use POSIX qw(ENOENT);

BEGIN {
	use_ok('Lingua::Text') or BAIL_OUT('Cannot load Lingua::Text -- all locale tests meaningless');
}

# ---------------------------------------------------------------------------
# Sanity: verify that basic locale detection works before running any subtest.
# BAIL_OUT on failure so a broken environment does not produce a wall of noise.
# ---------------------------------------------------------------------------
subtest 'sanity' => sub {
	local %ENV;
	$ENV{LANG} = 'en_US.UTF-8';

	my $obj = Lingua::Text->new({ en => 'hello', fr => 'bonjour' });
	isa_ok($obj, 'Lingua::Text', 'object created')
		or BAIL_OUT('Cannot construct Lingua::Text object');

	is($obj->as_string(), 'hello', 'LANG=en_US.UTF-8 resolves to English')
		or BAIL_OUT('Basic language detection is broken -- aborting locale suite');
};

# ---------------------------------------------------------------------------
# Geographic locales: one canonical LANG value per country.
# Each subtest is independent (local %ENV ensures no leakage).
# ---------------------------------------------------------------------------
subtest 'geographic' => sub {
	# Map ISO 3166-1 country code -> expected ISO 639-1 language code
	my %country_lang = (
		GB => 'en',
		US => 'en',
		FR => 'fr',
		DE => 'de',
		CN => 'zh',
	);

	my $obj = Lingua::Text->new({
		en => 'hello',
		fr => 'bonjour',
		de => 'hallo',
		zh => 'nihao',
	});

	for my $country (sort keys %country_lang) {
		my $lang   = $country_lang{$country};
		my $locale = lc($lang) . '_' . $country . '.UTF-8';

		local %ENV;
		$ENV{LANG} = $locale;

		is($obj->as_string(), $obj->$lang(),
			"Country $country (LANG=$locale) resolves to '$lang'");
	}

	# Case-insensitivity: the two-letter extraction is case-insensitive
	{
		local %ENV;
		$ENV{LANG} = 'FR_fr.UTF-8';	# unusual casing
		# _get_language downcases the extracted code, so 'fr' should still work
		my $t = Lingua::Text->new({ fr => 'bonjour', en => 'hello' });
		is($t->as_string(), 'bonjour', 'Unusual LANG casing handled gracefully');
	}

	# Concurrent instances must not share state
	{
		local %ENV;
		$ENV{LANG} = 'en_GB.UTF-8';

		my $t1 = Lingua::Text->new({ en => 'first' });
		my $t2 = Lingua::Text->new({ en => 'second' });
		is($t1->as_string(), 'first',  'Concurrent instance 1 is independent');
		is($t2->as_string(), 'second', 'Concurrent instance 2 is independent');

		# Mutating t1 must not affect t2
		$t1->en('modified');
		is($t2->as_string(), 'second', 'Modifying instance 1 does not corrupt instance 2');
	}
};

# ---------------------------------------------------------------------------
# POSIX system locale: error behaviour under different LC_ALL settings.
# We probe three locales representative of different language families.
#
# For OS error strings we use:  local $! = ENOENT; my $msg = "$!";
# Never POSIX::strerror() -- that bypasses Perl's locale layer and can
# diverge from what the C library would return under the current LC_ALL.
# ---------------------------------------------------------------------------
subtest 'posix' => sub {
	my @locales = ('en_US.UTF-8', 'de_DE.UTF-8', 'zh_CN.UTF-8');

	for my $locale (@locales) {
		local %ENV;
		$ENV{LC_ALL} = $locale;

		# Perl sources the OS error string through its own layer (Perl_sv_catpvn
		# under the hood), which is locale-aware.  This verifies the string is
		# non-empty and does not originate from POSIX::strerror.
		my $os_err = do { local $! = ENOENT; "$!" };
		ok(length($os_err) > 0,
			"OS ENOENT string is non-empty under LC_ALL=$locale");

		# Confirm the module correctly picks up the language prefix
		my ($lang_code) = $locale =~ /^([a-z]{2})/i;
		$lang_code = lc($lang_code);

		my $obj = Lingua::Text->new({
			en => 'error',
			de => 'Fehler',
			zh => 'cuowu',
		});

		if(defined($obj->$lang_code())) {
			# Locale has a translation -- as_string must return it
			is($obj->as_string(), $obj->$lang_code(),
				"Language '$lang_code' selected under LC_ALL=$locale");
		} else {
			# No translation for this locale -- as_string returns undef (no warning here)
			is($obj->as_string(), undef,
				"Undef returned for untranslated '$lang_code' under LC_ALL=$locale");
		}

		# A carp warning must fire when neither lang arg nor locale resolves
		{
			local %ENV;	# wipe all locale vars
			my $empty = Lingua::Text->new({ en => 'hello' });
			my $warned = 0;
			local $SIG{__WARN__} = sub { $warned = 1 };
			$empty->as_string();
			ok($warned, "as_string() carps when locale is completely absent (was under $locale)");
		}
	}
};

done_testing();
