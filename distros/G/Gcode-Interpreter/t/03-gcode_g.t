use Test::More;
use strict;
use warnings;

BEGIN { plan tests => 10 };

my @begin_gcode = (
	'G28 X0 Y0 Z0 E0',
);

# This mammoth data structure means we test every possible "G"
# command and check it moves us to the right location, or
# adds the right amount to the duration or extruded length.
# We check a few things in each calculation 'method'.
my $tests = {
	'fast' => {
		'G0 X10.1 Y20.2 Z30.3 E40.4' => [ [10.1,20.2,30.3,40.4], {'duration' => 0.376404776212465, 'extruded' => 40.4} ],
		'G1 X10.2 Y20.3 Z30.4 E40.5' => [ [10.2,20.3,30.4,40.5], {'duration' => 0.378641577807357, 'extruded' => 40.5} ],
		'G4 S10' => [undef, {'duration' => 10, 'extruded' => 0} ],
		'G4 P1000' => [undef, {'duration' => 1, 'extruded' => 0} ],
	},
	'table' => {
	},
};

use Gcode::Interpreter;

foreach my $method (sort keys %$tests) {
	foreach my $test (sort keys %{$tests->{$method}}) {
		# This is all tested explicitly elsewhere...
		my $obj = Gcode::Interpreter->new();
		$obj->set_method($method);
		foreach my $start (@begin_gcode) {
			$obj->parse_line($start);
		}

		my ($expected_position, $expected_stats) = @{$tests->{$method}->{$test}};

		# Now do the actual testing...
		ok($obj->parse_line($test));
		my $pos = $obj->position();
		my $stats = $obj->stats();
		is_deeply($pos, $expected_position) if($expected_position);
		is_deeply($stats, $expected_stats) if($expected_stats);
	}
}

