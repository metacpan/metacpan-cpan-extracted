use strict;
use warnings;

use English qw(-no_match_vars);
use Indent::Data;
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $obj = Indent::Data->new(
	'next_indent' => '  ',
	'line_size' => '20',
);
my $set_no_indent = 1;
my $act_indent = '---';
my $data = 'a b c d e f g h i j k l m n o p q r s t u v w x y z' x 2;
my $ret = $obj->indent($data, $act_indent, $set_no_indent);
is(length $ret, length($data) + 3,
	'Length of indented string is +3 characters for actual indentation.');

# Test.
$set_no_indent = 0;
my @ret = $obj->indent($data, $act_indent, $set_no_indent);
my $log = 0;
foreach my $line (@ret) {
	if (length $line > 20) {
		$log = 1;
	}
}
is($#ret, 6, 'Number of indented lines (6 lines).');
is($log, 0, 'No returned lines with length > 20.');

# Test.
@ret = $obj->indent($data);
$log = 0;
foreach my $line (@ret) {
	if (length $line > 20) {
		$log = 1;
	}
}
is($#ret, 5, 'Number of indented lines (5 lines).');
is($log, 0, 'No returned lines with length > 20.');

# Test.
$ret = $obj->indent($data);
is(length $ret, 117, 'Full length of indented text (117 characters).');

# Test.
$data = 'text text text texttexttex';
$obj = Indent::Data->new(
	'next_indent' => '  ',
	'line_size' => '10',
);
my @right_ret = (
	'text text ',
	'  text tex',
	'  ttexttex',
);
@ret = $obj->indent($data);
is_deeply(\@ret, \@right_ret, 'Compare indented string (default indent).');

# Test.
$data = 'text';
$obj = Indent::Data->new(
	'next_indent' => '',
	'line_size' => '5',
);
@right_ret = (
	'<-->t',
	'<-->e',
	'<-->x',
	'<-->t',
);
@ret = $obj->indent($data, '<-->');
is_deeply(\@ret, \@right_ret,
	'Compare indented string (no default indent, explicit indent).');

# Test.
$data = 'text';
$obj = Indent::Data->new(
	'next_indent' => ' ',
	'line_size' => '5',
);
@right_ret = (
	'<->te',
	'<-> x',
	'<-> t',
);
@ret = $obj->indent($data, '<->');
is_deeply(\@ret, \@right_ret,
	'Compare indented string (default indent plus explicit indent).');

# Test.
$obj = Indent::Data->new(
	'next_indent' => '',
	'line_size' => 5,
);
eval {
	$obj->indent('text', '<--->');
};
is($EVAL_ERROR, "Bad actual indent value. Length is greater then ".
	"('line_size' - 'size of next_indent' - 1).\n",
	'Bad actual indent value (no default indent).');

# Test.
$obj = Indent::Data->new(
	'next_indent' => ' ',
	'line_size' => 5,
);
eval {
	$obj->indent('text', '<-->');
};
is($EVAL_ERROR, "Bad actual indent value. Length is greater then ".
	"('line_size' - 'size of next_indent' - 1).\n",
	'Bad actual indent value (with default indent).');

# Test.
$obj = Indent::Data->new(
	'next_indent' => '',
	'line_size' => '1',
	'output_separator' => '-'
);
$ret = $obj->indent('abcd');
is($ret, 'a-b-c-d', 'Test of output separator.');
