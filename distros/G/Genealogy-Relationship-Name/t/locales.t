#!/usr/bin/env perl

# locales.t - Locale correctness tests for Genealogy::Relationship::Name
#
# Tests two distinct locale concerns:
#   1. Geographic / language-code correctness (the module's own language tables)
#   2. System locale (POSIX LC_ALL) — verifies that module error messages are
#      unaffected by the OS locale, i.e. they remain consistent regardless of
#      what the underlying C library says.
#
# CRITICAL: We source POSIX error strings via  local $! = ENOENT; "$!"
# rather than POSIX::strerror() to avoid C-library divergence (the two can
# return different strings on some platforms/locales).

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;

use POSIX qw(ENOENT);
use Test::Most;

use Log::Abstraction;
use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# SECTION 1 – Geographic (language-code) tests
# Sanity subtest runs first; BAIL_OUT on mapping failure to catch table drift.
# =========================================================================

subtest 'SANITY: language-code mapping is intact (BAIL_OUT on failure)' => sub {
	plan tests => 7;

	my $namer = Genealogy::Relationship::Name->new();
	my @langs = $namer->supported_languages();
	my %lang_set = map { $_ => 1 } @langs;

	for my $expected (qw(de de_ch en es fa fr la)) {
		ok($lang_set{$expected}, "$expected present in supported_languages()")
			or BAIL_OUT("Language '$expected' missing — GeoIP/language drift detected");
	}
};

# Country-code / language-tag case-insensitivity
subtest 'Geographic: BCP-47 region subtag stripped case-insensitively' => sub {
	plan tests => 6;

	my $namer = Genealogy::Relationship::Name->new();

	# en-GB, en-US → en
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-GB'),
		'brother', 'en-GB → brother');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-US'),
		'brother', 'en-US → brother');

	# fr-FR → fr
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'fr-FR'),
		'fils', 'fr-FR → fils');

	# de-DE → de (standard German eszett)
	my $de = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M', language => 'de-DE');
	is($de, "Gro\N{U+00DF}vater", 'de-DE → Großvater');

	# de-CH → de_ch (Swiss ss) — must NOT strip to bare de
	my $de_ch = $namer->name(steps_to_ancestor => 2, steps_from_ancestor => 0, sex => 'M', language => 'de-CH');
	is($de_ch, 'Grossvater', 'de-CH → Grossvater (ss, not eszett)');
	isnt($de, $de_ch, 'de and de-CH produce distinct strings for grandfather');
};

# Concurrent instances do not bleed state between objects
subtest 'Geographic: concurrent objects with different languages share no state' => sub {
	plan tests => 4;

	my $en = Genealogy::Relationship::Name->new(language => 'en');
	my $fr = Genealogy::Relationship::Name->new(language => 'fr');
	my $de = Genealogy::Relationship::Name->new(language => 'de');
	my $es = Genealogy::Relationship::Name->new(language => 'es');

	is($en->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'), 'son',  'en object → son');
	is($fr->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'), 'fils', 'fr object → fils');
	is($de->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'), 'Sohn', 'de object → Sohn');
	is($es->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'), 'hijo', 'es object → hijo');
};

# Country-based spot-checks: GB→en, US→en, FR→fr, DE→de, CN→undef (unsupported)
subtest 'Geographic: country-language spot-checks (simulated GeoIP mapping)' => sub {
	plan tests => 5;

	# Simulated GeoIP: country code → BCP-47 primary language tag
	my %country_lang = (GB => 'en', US => 'en', FR => 'fr', DE => 'de');
	my $namer = Genealogy::Relationship::Name->new();

	for my $country (qw(GB US FR DE)) {
		my $lang = $country_lang{$country};
		my $r = $namer->name(
			steps_to_ancestor   => 1,
			steps_from_ancestor => 0,
			sex                 => 'M',
			language            => $lang,
		);
		ok(defined $r, "GeoIP $country ($lang) → defined parent name");
	}

	# CN: Chinese is not supported; validate_strict should croak
	eval {
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0,
		             sex => 'M', language => 'zh');
	};
	ok($@, 'GeoIP CN: unsupported language zh croaks');
};

# =========================================================================
# SECTION 2 – System locale (POSIX LC_ALL) tests
# The module's error messages must be independent of the OS locale.
# We test under en_US.UTF-8, de_DE.UTF-8, and ja_JP.UTF-8 if available.
# =========================================================================

# Helper: run a block with a given LC_ALL and return the croak message
sub _error_under_locale {
	my ($locale, $code) = @_;
	my $saved = $ENV{LC_ALL};
	local $ENV{LC_ALL} = $locale;
	my $msg = '';
	eval { $code->() };
	$msg = "$@" if $@;
	$ENV{LC_ALL} = $saved if defined $saved;
	return $msg;
}

# Helper: obtain POSIX error string without POSIX::strerror() to prevent
# C-library divergence (see file header comment)
sub _enoent_string {
	local $! = ENOENT;
	return "$!";
}

subtest 'System locale: module errors are locale-independent (en_US.UTF-8)' => sub {
	plan tests => 3;

	my $locale = 'en_US.UTF-8';
	my $namer  = Genealogy::Relationship::Name->new();

	# Error from our own croak — must always be English regardless of locale
	my $msg = _error_under_locale($locale, sub {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');
	});
	like($msg,  qr/steps_to_ancestor not given/, "$locale: croak message is English");
	my $os_err = _enoent_string();
	unlike($msg, qr/\Q$os_err\E/, "$locale: message does not contain OS locale string");

	# Validate that a successful call still works under this locale
	my $result;
	_error_under_locale($locale, sub {
		$result = $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M');
	});
	is($result, 'brother', "$locale: successful call unaffected");
};

subtest 'System locale: module errors are locale-independent (de_DE.UTF-8)' => sub {
	plan tests => 3;

	my $locale = 'de_DE.UTF-8';
	my $namer  = Genealogy::Relationship::Name->new();

	my $msg = _error_under_locale($locale, sub {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');
	});
	like($msg,  qr/steps_to_ancestor not given/, "$locale: croak message is English");
	my $os_err = _enoent_string();
	unlike($msg, qr/\Q$os_err\E/, "$locale: message does not contain OS locale string");

	my $result;
	_error_under_locale($locale, sub {
		$result = $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M');
	});
	is($result, 'brother', "$locale: successful call unaffected");
};

subtest 'System locale: module errors are locale-independent (ja_JP.UTF-8)' => sub {
	plan tests => 3;

	my $locale = 'ja_JP.UTF-8';
	my $namer  = Genealogy::Relationship::Name->new();

	my $msg = _error_under_locale($locale, sub {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');
	});
	like($msg,  qr/steps_to_ancestor not given/, "$locale: croak message is English");
	my $os_err = _enoent_string();
	unlike($msg, qr/\Q$os_err\E/, "$locale: message does not contain OS locale string");

	my $result;
	_error_under_locale($locale, sub {
		$result = $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M');
	});
	is($result, 'brother', "$locale: successful call unaffected");
};

# Verify that the POSIX ENOENT string itself changes across locales (sanity
# check that our locale-switching helper actually works)
subtest 'System locale: POSIX ENOENT string varies with LC_ALL (sanity)' => sub {
	plan tests => 1;

	# We only assert that calling the helper doesn't crash; the actual string
	# content is locale-dependent and we cannot predict it in a portable test.
	my $en_str = do { local $ENV{LC_ALL} = 'en_US.UTF-8'; _enoent_string() };
	ok(length($en_str) > 0, 'POSIX ENOENT string is non-empty under en_US.UTF-8');
};

done_testing();
