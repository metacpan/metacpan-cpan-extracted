use strict;
use warnings;

use English qw(-no_match_vars);
use Indent::Utils qw(line_size_check);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
eval {
	line_size_check({
		'line_size' => 'bad',
	});
};
is($EVAL_ERROR, "'line_size' parameter must be a positive number.\n",
	'Bad \'line_size\' = \'bad\'.');

# Test.
eval {
	line_size_check({
		'line_size' => '',
	});
};
is($EVAL_ERROR, "'line_size' parameter must be a positive number.\n",
	'Bad \'line_size\' = \'\'.');

# Test.
eval {
	line_size_check({
		'line_size' => -1,
	});
};
is($EVAL_ERROR, "'line_size' parameter must be a positive number.\n",
	'Bad \'line_size\' = -1.');

# Test.
eval {
	line_size_check({
		'line_size' => undef,
	});
};
is($EVAL_ERROR, "'line_size' parameter must be a positive number.\n",
	'Bad \'line_size\' = undef.');

# Test.
my $ret = line_size_check({
	'line_size' => 80,
});
is($ret, undef, 'Check is ok.');
