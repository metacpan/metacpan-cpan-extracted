#!perl -w

# The rule, by equivalence class.
#
# Geo::Location::Predicate answers one question - could this string be a
# location at all? - and its answer is a cheap syntactic test: true for anything
# with a non-digit character in it, false for undef, the empty string, a
# reference and a string of digits only.  What it is for is the string a numeric
# column holds when the wrong column has been read, which must not be looked up
# as a place; that is why the classes below are the ones that matter.
#
# Two of them are easy to get wrong and are here for it.  A string of Unicode
# digits is refused as well as an ASCII one, because the pattern is a negated
# digit class and Perl answers it with Unicode rules for a string that carries
# the UTF-8 flag - and a caller reading a column of such digits is in the same
# position as one reading '0044'.  A scalar reference is refused: passing the
# string it points at is a caller's job (Params::Get does it for the six), and
# the rule is not what does it.

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test::Most;

use Geo::Location::Predicate qw(_valid_location);

# Values that are not a location.  Held as pairs so a case cannot be confused
# with the assertion it feeds: '0' and 0 are different questions.
my @NOT_A_LOCATION = (
	['undef',                            undef],
	['the empty string',                 ''],
	['zero as a string',                 '0'],
	['zero as a number',                 0],
	['zero as a float',                  0.0],
	['a string of digits',               '0044'],
	['a long string of digits',          '1' x 200],
	['digits from another script',       "\x{0661}\x{0662}"],
	['fullwidth digits',                 "\x{FF11}\x{FF12}"],
	['a reference to an array',          [1, 2, 3]],
	['a reference to a hash',            { location => 'London' }],
	['a reference to a scalar',          \'London'],
	['a blessed reference',              bless({}, 'Geo::Location::Predicate::Test::Thing')],
);

# Values that could be.  A true answer means the string is not disqualified, not
# that anybody knows it: 'Ramsgate, Kent' is a location whether or not a backend
# has heard of it.
my @A_LOCATION = (
	['a city',                           'London'],
	['an address',                       'Ramsgate, Kent'],
	['a decimal',                        '3.14'],
	['a minus sign on its own',          '-'],
	['a space',                          ' '],
	['a negative number in a string',    '-0044'],
	['digits with a non-digit among them', '0 but true'],
	['a number in exponent form',        '1e3'],
	['a single letter',                  'a'],
);

for my $case (@NOT_A_LOCATION) {
	ok(!_valid_location($case->[1]), "$case->[0] is refused");
}

for my $case (@A_LOCATION) {
	ok(_valid_location($case->[1]), "$case->[0] can be looked up");
}

# The private name is the only one, and asking for it is how a caller gets it:
# a module that exported the rule by default would put it into a caller's
# namespace unasked.
is_deeply(\@Geo::Location::Predicate::EXPORT, [], 'the rule is not exported by default');
is_deeply(\@Geo::Location::Predicate::EXPORT_OK, ['_valid_location'],
	'it is available on request, under the name the callers use');

# The import is that sub, not a copy of it: a module that pasted the rule into
# its caller would answer the same and could still drift from this one.
is(refaddr(\&main::_valid_location), refaddr(\&Geo::Location::Predicate::_valid_location),
	'the imported name and the module\'s sub are the same code reference');

# The answer is exactly 1 or 0, not merely true or false: a sibling may compare
# it with == or store it, and the fuzz harness compares verdicts by value.
subtest 'the answer is exactly 1 or 0, and one value' => sub {
	is(_valid_location('London'), 1, 'a location answers 1');
	is(_valid_location('0044'), 0, 'digits answer 0');
	is(_valid_location(undef), 0, 'undef answers 0, not undef');
	is(_valid_location(), 0, 'no argument at all answers 0');

	# A bare "return;" would give () in list context, which is false in scalar
	# context but empty in a list - so a list of answers would lose entries.
	my @answers = map { _valid_location($_) } ('London', '0044', undef);
	is_deeply(\@answers, [1, 0, 0], 'one answer per value in list context');
};

# Cases where the rule is debatable.  They are pinned here so that a change of
# policy is a change to this file as well, and not an accident.  See
# LIMITATIONS in the POD.
subtest 'whitespace and stringification are taken as they are' => sub {
	is(_valid_location("0044\n"), 1, 'a line that was not chomped is accepted');
	is(_valid_location(' 0044 '), 1, 'a padded field is accepted');
	is(_valid_location(-44), 1, 'a negative number stringifies with a minus sign');
	is(_valid_location(1e3), 0, 'a numeric literal is judged by its stringification');
};

# Which bytes perl stores a string in must not change the answer: the same
# string, upgraded to UTF-8 internally, is the same question.
subtest 'the UTF-8 flag does not change the answer' => sub {
	for my $value ('0044', 'London', "caf\x{e9}") {
		my $upgraded = $value;
		utf8::upgrade($upgraded);
		is(_valid_location($upgraded), _valid_location($value), "'$value' upgraded or not");
	}
};

# An object is refused without being stringified, so an overload that dies
# cannot escape from the predicate.
{
	package Geo::Location::Predicate::Test::Place;
	use overload '""' => sub { die 'stringified' }, fallback => 1;
}

subtest 'an object is not stringified' => sub {
	my $place = bless({}, 'Geo::Location::Predicate::Test::Place');
	my $answer;
	lives_ok(sub { $answer = _valid_location($place) }, 'an overload that dies is not called');
	is($answer, 0, 'and the object is refused');
};

# The predicate is called in the middle of a caller's own work: it must leave
# the caller's argument, match variables and $_ as they were.
subtest 'no side effects on the caller' => sub {
	my $value = '0044';
	_valid_location($value);
	is($value, '0044', 'the argument is not changed');

	'Ramsgate, Kent' =~ /^(\w+)/;
	_valid_location('London');
	is($1, 'Ramsgate', "the caller's \$1 survives a match inside the rule");

	local $_ = 'unchanged';
	_valid_location('London');
	is($_, 'unchanged', '$_ is not used');
};

done_testing();
