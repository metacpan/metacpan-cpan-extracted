# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Block;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Indent::Block->new;
my @data = ('text', 'text');
my @ret = $obj->indent(\@data);
is_deeply(
	\@ret, 
	[
		'texttext',
	],
	'Two string blocks.',
);

# Test.
@ret = $obj->indent(\@data, '<--->');
is_deeply(
	\@ret,
	[
		'<--->texttext',
	],
	'Two string blocks with explicit indent.',
);

# Test.
$obj = Indent::Block->new(
	'line_size' => 4,
	'next_indent' => '',
);
@ret = $obj->indent(\@data);
is_deeply(
	\@ret,
	[
		'text',
		'text',
	],
	'Two string blocks with \'line_size\' lesser than block size.',
);

# Test.
my $ret = $obj->indent(\@data);
is($ret, "text\ntext", 'Return value as string.');

# Test.
@ret = $obj->indent(\@data, undef, 1);
is_deeply(
	\@ret,
	['texttext'],
	'Two string blocks with \'line_size\' lesser than block size.'.
		'With no_indent flag.',
);
