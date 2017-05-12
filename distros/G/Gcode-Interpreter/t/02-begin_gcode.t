use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 4 };

my $begin_gcode = {
	'G28 X0 Y0 Z0 E0' => [0,0,0,0],
	'G28 X10 Y11 Z12 E13' => [10,11,12,13],
};

use Gcode::Interpreter;

my $obj = Gcode::Interpreter->new();

foreach my $test (sort keys %$begin_gcode) {
	ok($obj->parse_line($test));
	my $pos = $obj->position();
	is_deeply($pos, $begin_gcode->{$test});
}
