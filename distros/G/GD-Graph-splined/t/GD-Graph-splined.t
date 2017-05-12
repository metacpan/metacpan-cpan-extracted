use Test::More tests => 5;
BEGIN {
	use_ok('GD::Graph') ;
	use_ok('GD::Polyline');
	use_ok('GD::Graph::splined');
};

use strict;

my @data = (
	["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
	[    5,   12,   24,   33,   19,undef,    6,    15,    21],
	[    1,    2,    5,    6,    3,  1.5,    1,     3,     4]
);

my $graph = GD::Graph::splined->new;
isa_ok($graph, 'GD::Graph::splined');
ok( $graph->plot(\@data), 'plot');

