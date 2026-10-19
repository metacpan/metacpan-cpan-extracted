#!perl -w

# The rule under locales.
#
# Geo::Location::Predicate does no GeoIP lookup and raises no error, so the two
# questions a locale test usually asks have narrower answers here.  The
# geographic one is whether the strings a caller would pass for a country - an
# ISO 3166 code in either case - are locations; they must be, or every caller
# filtering by country would skip the lookup.  The system one is whether the
# answer, and the caller's $!, are the same whatever LC_ALL says.  The rule
# compiles its pattern without "use locale", so \d must mean Unicode Nd in every
# locale and in a caller's "use locale" scope; a rule whose answer moved with
# the locale would refuse a column on one machine and look it up on another.

use strict;
use warnings;

use Errno qw(ENOENT);
use POSIX qw(setlocale LC_ALL);
use Test::Most;

use Geo::Location::Predicate qw(_valid_location);

# The countries the callers are tested against, in every case a caller might
# write them.
my @COUNTRIES = qw(GB US FR DE CN);

# The system locales to try.  One East Asian locale is enough to cover a
# multibyte LC_CTYPE; more than one is tried because few machines have them all.
my @LOCALES = ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8', 'zh_CN.UTF-8', 'ko_KR.UTF-8');

# A fixed set of values with the answers the C locale gives.  Each locale must
# give the same answers.
my @CORPUS = (
	['London', 1], ['0044', 0], ['', 0], ['3.14', 1], ["\x{0661}\x{0662}", 0],
	["\x{FF11}\x{FF12}", 0], ["M\x{fc}nchen", 1], ["\x{6771}\x{4eac}", 1], ['1e3', 1],
);

# Purpose: the answers to the corpus, in order.
# Entry: none.
# Exit: an arrayref of 1s and 0s, one per entry of @CORPUS.
# Side effects: none.
sub _answers {
	return [ map { _valid_location($_->[0]) } @CORPUS ];
}

# If the base cases are wrong, everything else here is noise: stop at once.
subtest 'sanity' => sub {
	my $ok = is_deeply(_answers(), [ map { $_->[1] } @CORPUS ], 'the C locale gives the documented answers');
	$ok &&= ok(_valid_location('GB'), 'a country code is a location');
	BAIL_OUT('the rule does not give its documented answers; the locale tests cannot be trusted') unless $ok;
};

subtest 'country codes are locations in any case' => sub {
	for my $code (@COUNTRIES) {
		for my $spelling ($code, lc($code), ucfirst(lc($code))) {
			is(_valid_location($spelling), 1, "'$spelling' can be looked up");
		}
	}
};

# There are no instances to share state between, but callers interleave calls
# from several geocoders.  Asking about every country in a different order must
# give the same answers each time.
subtest 'interleaved calls do not affect each other' => sub {
	my @forwards = map { _valid_location($_) } (@COUNTRIES, '0044');
	my @backwards = reverse map { _valid_location($_) } reverse(@COUNTRIES, '0044');
	is_deeply(\@backwards, \@forwards, 'the order of the questions does not matter');
};

# Purpose: run a test block with LC_ALL set to a locale, restoring it after.
# Entry: a locale name and a code reference.
# Exit: true if the locale could be set and the block ran, false if the
#	locale is not installed (the caller skips).
# Side effects: changes the process locale for the duration of the block.
sub _in_locale {
	my ($locale, $code) = @_;

	my $saved = setlocale(LC_ALL);
	local $ENV{LC_ALL} = $locale;
	my $set = setlocale(LC_ALL, $locale);
	$code->() if defined($set);
	setlocale(LC_ALL, $saved);

	return defined($set);
}

my $locales_tried = 0;
for my $locale (@LOCALES) {
	subtest "under LC_ALL=$locale" => sub {
		my $ran = _in_locale($locale, sub {
			is_deeply(_answers(), [ map { $_->[1] } @CORPUS ], 'the same answers as the C locale');

			# A caller's "use locale" does not reach the rule's pattern.
			{
				use locale;
				is(_valid_location('0044'), 0, 'digits are refused inside "use locale"');
				is(_valid_location('London'), 1, 'a name is accepted inside "use locale"');
			}

			# The predicate may be asked from an error handler; $! must survive
			# it.  The message comes from perl's own $!, not POSIX::strerror, so
			# it is the string the caller would see.
			local $! = ENOENT;
			my $message = "$!";
			ok(length($message), "\$! has a message in $locale");
			_valid_location('0044');
			_valid_location('London');
			is(0 + $!, ENOENT, '$! is still ENOENT');
			is("$!", $message, 'and its message is unchanged');
		});
		$locales_tried++ if $ran;
		plan(skip_all => "$locale is not installed") unless $ran;
	};
}

# At least one locale other than C must have been tried, or this test proved
# nothing about locales.  Not a failure - a minimal container may have none.
note($locales_tried ? "$locales_tried locale(s) tried" : 'no UTF-8 locale is installed; only the C locale was tested');

done_testing();
