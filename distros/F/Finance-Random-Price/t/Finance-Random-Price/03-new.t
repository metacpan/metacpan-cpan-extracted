use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Finance::Random::Price;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
eval {
	Finance::Random::Price->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Finance::Random::Price->new;
isa_ok($obj, 'Finance::Random::Price');

# Test.
eval {
	Finance::Random::Price->new(
		'min' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'min' is required.\n", "Parameter 'min' is required.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'min' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'min' must be a number.\n", "Parameter 'min' must be a number.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'max' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'max' is required.\n", "Parameter 'max' is required.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'max' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'max' must be a number.\n", "Parameter 'max' must be a number.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'min' => 100,
		'max' => 99,
	);
};
is($EVAL_ERROR, "Parameter 'max' must be greater than parameter 'min'.\n",
	"Parameter 'max' must be greater than parameter 'min'.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'decimal_num' => 'bar',
	);
};
is($EVAL_ERROR, "Parameter 'decimal_num' must be a number.\n",
	"Parameter 'decimal_num' must be a number.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'decimal_num' => -1,
	);
};
is($EVAL_ERROR, "Parameter 'decimal_num' must be greater than 0.\n",
	"Parameter 'decimal_num' must be greater than 0.");
clean();

# Test.
eval {
	Finance::Random::Price->new(
		'decimal_num' => 3,
	);
};
is($EVAL_ERROR, "Parameter 'decimal_num' must be lesser than 3.\n",
	"Parameter 'decimal_num' must be lesser than 3.");
clean();
