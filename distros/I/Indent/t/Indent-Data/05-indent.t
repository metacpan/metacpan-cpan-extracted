# Pragmas.
use strict;
use warnings;

# Modules.
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
is(length $ret, length($data) + 3);

# Test.
$set_no_indent = 0;
my @ret = $obj->indent($data, $act_indent, $set_no_indent);
my $log = 0;
foreach my $line (@ret) {
	if (length $line > 20) {
		$log = 1;
	}
}
is($#ret, 6);
is($log, 0);

# Test.
@ret = $obj->indent($data);
$log = 0;
foreach my $line (@ret) {
	if (length $line > 20) {
		$log = 1;
	}
}
is($log, 0);
is($#ret, 5);

# Test.
$ret = $obj->indent($data);
is(length $ret, 117);

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
is_deeply(\@ret, \@right_ret);

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
is_deeply(\@ret, \@right_ret);

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
is_deeply(\@ret, \@right_ret);

# Test.
$obj = Indent::Data->new(
	'next_indent' => '',
	'line_size' => 5,
);
eval {
	$obj->indent('text', '<--->');
};
is($EVAL_ERROR, "Bad actual indent value. Length is greater then ".
	"('line_size' - 'size of next_indent' - 1).\n");

# Test.
$obj = Indent::Data->new(
	'next_indent' => ' ',
	'line_size' => 5,
);
eval {
	$obj->indent('text', '<-->');
};
is($EVAL_ERROR, "Bad actual indent value. Length is greater then ".
	"('line_size' - 'size of next_indent' - 1).\n");

# Test.
$obj = Indent::Data->new(
	'next_indent' => '',
	'line_size' => '1',
	'output_separator' => '-'
);
$ret = $obj->indent('abcd');
is($ret, 'a-b-c-d');
