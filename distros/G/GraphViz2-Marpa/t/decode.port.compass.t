#!/usr/bin/env perl

use File::Which 'which';

use GraphViz2::Marpa;

use Test::More;

# -------------------

sub test
{
	my($count, $graph, $name) = @_;
	my(@result)   = $graph -> decode_port_compass($name);
	my(%expected) =
	(
		'A'          => ['A', ''],
		'A:'         => ['A:', ''],
		'A::'        => ['A::', ''],
		'A::B'       => ['A::B', ''],
		'A::B::C'    => ['A::B::C', ''],
		'A:p'        => ['A', ':p'],
		'A:p:c'      => ['A', ':p:c'],
		'A::B:p'     => ['A::B', ':p'],
		'A::B:p:c'   => ['A::B', ':p:c'],
		'"A::B":p:c' => ['"A::B"', ':p:c'],
	);

	$$count++;

	is(@result, @{$expected{$name} }, "Test $name");

} # End of test.

# -------------------

if (! defined which('dot') )
{
	BAIL_OUT("Cannot find 'dot'. Please install Graphviz from http://www.graphviz.org/");
}

my($count) = 0;
my($graph) = GraphViz2::Marpa -> new;

test(\$count, $graph, 'A');
test(\$count, $graph, 'A:');
test(\$count, $graph, 'A::');
test(\$count, $graph, 'A::B');
test(\$count, $graph, 'A::B::C');
test(\$count, $graph, 'A:p');
test(\$count, $graph, 'A:p:c');
test(\$count, $graph, 'A::B:p');
test(\$count, $graph, 'A::B:p:c');
test(\$count, $graph, '"A::B":p:c');

print "# Internal test count: $count\n";

done_testing;
