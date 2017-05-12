# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Indent::Form;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Indent::Form->new(
	'line_size' => 80,
	'output_separator' => "\n",
);
my $input = [
        ['Login', 'Michal Spacek'],
        ['Password', 'abcdefghijklmnopqrstuvw'],
        ['Info', 'This is big info.'],
];
my @right_ret = (
	'   Login: Michal Spacek',
	'Password: abcdefghijklmnopqrstuvw',
	'    Info: This is big info.',
);
my @ret = $obj->indent($input);
is_deeply(\@ret, \@right_ret);

# Test.
$obj = Indent::Form->new(
	'line_size' => 10,
	'output_separator' => "\n",
);
@right_ret = (
	'   Login: Michal',
	'          Spacek',
	'Password: abcdefghijklmnopqrstuvw',
	'    Info: This',
	'          is',
	'          big',
	'          info.',
);
@ret = $obj->indent($input);
is_deeply(\@ret, \@right_ret);

# Test.
eval {
	Indent::Form->new(
		'next_indent' => '  ',
		'line_size' => 'ko',
	);
};
is($EVAL_ERROR, "'line_size' parameter must be a number.\n");
