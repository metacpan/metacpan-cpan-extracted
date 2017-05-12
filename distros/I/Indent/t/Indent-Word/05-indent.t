# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Word;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Indent::Word->new(
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
$data = 'abcdefghijklmnopqrstuvwxyz' x 3;
$ret = $obj->indent($data, $act_indent, $set_no_indent);
is($ret, '---abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdef'.
	'ghijklmnopqrstuvwxyz');

# Test.
$data = 'text';
$obj = Indent::Word->new(
	'next_indent' => '',
	'line_size' => '5',
);
$ret = $obj->indent($data, '<-->');
is($ret, '<-->text');

# Test.
$data = 'text text';
$obj = Indent::Word->new(
	'next_indent' => ' ',
	'line_size' => '5',
);
my @right_ret = (
	'<->text',
	'<-> text',
);
@ret = $obj->indent($data, '<->');
is_deeply(\@ret, \@right_ret);

# Test.
my $next_indent = '  ';
$obj = Indent::Word->new(
	'next_indent' => $next_indent,
	'line_size' => 0,
);
$ret = $obj->indent('word1 word2 word3');
is($ret, "word1\n".$next_indent."word2\n".$next_indent."word3");

# Test.
$obj = Indent::Word->new(
	'next_indent' => '',
	'line_size' => 2,
);
@ret = $obj->indent('aa    ');
is_deeply(
	\@ret,
	[
		'aa',
	],
	'Word with equal characters as line_size and trailing whitespace.',
);

# Test
$obj = Indent::Word->new(
	'next_indent' => '',
	'line_size' => 1,
);
@ret = $obj->indent('aa    ');
is_deeply(
	\@ret,
	[
		'aa',
	],
	'Word with more characters than line_size and trailing whitespace.',
);

# Test.
@ret = $obj->indent('');
is_deeply(
	\@ret,
	[],
	'No string to indent.',
);
