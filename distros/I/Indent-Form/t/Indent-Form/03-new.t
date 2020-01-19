use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Indent::Form;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
eval {
	Indent::Form->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");
clean();

# Test.
eval {
	Indent::Form->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
eval {
	Indent::Form->new(
		'align' => 'bad_align',
	);
};
is($EVAL_ERROR, "'align' parameter must be a 'left' or 'right' string.\n",
	"'align' parameter must be a 'left' or 'right' string.");
clean();

# Test.
eval {
	Indent::Form->new(
		'line_size' => 'bad_length',
	);
};
is($EVAL_ERROR, "'line_size' parameter must be a number.\n",
	"'line_size' parameter must be a number.");
clean();

# Test.
eval {
	Indent::Form->new(
		'line_size' => -10,
	);
};
is($EVAL_ERROR, "'line_size' parameter must be a number.\n",
	"Error in negative line size parameter.");

# Test.
my $obj = Indent::Form->new;
isa_ok($obj, 'Indent::Form');
