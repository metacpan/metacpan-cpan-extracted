# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Indent::Word;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Indent::Word->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad parameter \'\'.');

# Test.
eval {
	Indent::Word->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad parameter \'something\'.');

# Test.
my $obj = Indent::Word->new;
isa_ok($obj, 'Indent::Word');
