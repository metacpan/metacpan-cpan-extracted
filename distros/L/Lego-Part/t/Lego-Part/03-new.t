# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
eval {
	Lego::Part->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Lego::Part->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Lego::Part->new;
};
is($EVAL_ERROR, "Parameter 'element_id' or 'design_id' is required.\n",
	"Parameter 'element_id' or 'design_id' is required.");
clean();

# Test.
my $obj = Lego::Part->new(
	'element_id' => '300221',
);
isa_ok($obj, 'Lego::Part');

# Test.
$obj = Lego::Part->new(
	'design_id' => '3002',
);
isa_ok($obj, 'Lego::Part');
