use strict;
use warnings;

use Map::Tube::GraphViz::Utils qw(color_line);
use Map::Tube::Line;
use Test::MockObject;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Test::MockObject->new;
my $line1 = Map::Tube::Line->new(
	'id' => 'line1',
);
my $ret = color_line($obj, $line1);
is($ret, 'red', 'Get first color for line #1.');

# Test.
my $line2 = Map::Tube::Line->new(
	'id' => 'line2',
	'name' => 'Line #2',
);
$ret = color_line($obj, $line2);
is($ret, 'green', 'Get second color for line #2.');

# Test.
$ret = color_line($obj, $line1);
is($ret, 'red', 'Get first color for line #1.');

# Test.
my @ret;
foreach my $num (3 .. 25) {
	my $line = Map::Tube::Line->new(
		'id' => 'line'.$num,
	);
	$ret = color_line($obj, $line);
	push @ret, $ret;
}
is_deeply(
	\@ret,
	[
		'yellow',
		'cyan',
		'magenta',
		'blue',
		'grey',
		'orange',
		'brown',
		'white',
		'greenyellow',
		'red4',
		'violet',
		'tomato',
		'cadetblue',
		'aquamarine',
		'lawngreen',
		'indigo',
		'deeppink',
		'darkslategrey',
		'khaki',
		'thistle',
		'peru',
		'darkgreen',
		# Cycle from begin.
		'red',
	],
	'Get colors for next lines.',
);

# Test.
my $line_w_color = Map::Tube::Line->new(
	'color' => 'black',
	'id' => 'foo',
	'name' => 'bar',
);
$ret = color_line($obj, $line_w_color);
is($ret, 'black', 'Get color from line object.');
