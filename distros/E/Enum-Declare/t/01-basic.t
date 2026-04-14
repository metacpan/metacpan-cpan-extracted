use strict;
use warnings;
use Test::More;

use_ok('Enum::Declare');

{
	package MyApp;
	use Enum::Declare;

	enum Color { Red, Green, Blue };
}

# constant values
is(MyApp::Red(),   0, 'Red is 0');
is(MyApp::Green(), 1, 'Green is 1');
is(MyApp::Blue(),  2, 'Blue is 2');

# meta accessor
my $meta = MyApp::Color();
isa_ok($meta, 'Enum::Declare::Meta');

# meta methods
is($meta->count, 3, 'count is 3');

is_deeply($meta->names,  ['Red', 'Green', 'Blue'], 'names');
is_deeply($meta->values, [0, 1, 2],                'values');

is($meta->name(0), 'Red',   'name(0) is Red');
is($meta->name(1), 'Green', 'name(1) is Green');
is($meta->name(2), 'Blue',  'name(2) is Blue');

is($meta->value('Red'),   0, 'value(Red) is 0');
is($meta->value('Green'), 1, 'value(Green) is 1');
is($meta->value('Blue'),  2, 'value(Blue) is 2');

ok($meta->valid(0),  'valid(0)');
ok($meta->valid(1),  'valid(1)');
ok($meta->valid(2),  'valid(2)');
ok(!$meta->valid(3), 'not valid(3)');

is_deeply({$meta->pairs}, {Red => 0, Green => 1, Blue => 2}, 'pairs');

# second enum in same package
{
	package MyApp;
	enum Direction { North, South, East, West };
}

is(MyApp::North(), 0, 'North is 0');
is(MyApp::West(),  3, 'West is 3');

my $dir_meta = MyApp::Direction();
is($dir_meta->count, 4, 'Direction count is 4');

done_testing();
