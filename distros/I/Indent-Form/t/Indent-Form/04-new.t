# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Indent::Form;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Indent::Form->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");

# Test.
eval {
	Indent::Form->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");

# Test.
my $obj = Indent::Form->new;
isa_ok($obj, 'Indent::Form');
