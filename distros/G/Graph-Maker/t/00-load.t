#!perl -T

use Test::More tests => 27;

BEGIN {
	use_ok( 'Graph::Maker' );
	use_ok( 'Graph::Maker::BalancedTree' );
	use_ok( 'Graph::Maker::Barbell' );
	use_ok( 'Graph::Maker::Bipartite' );
	use_ok( 'Graph::Maker::CircularLadder' );
	use_ok( 'Graph::Maker::Complete' );
	use_ok( 'Graph::Maker::CompleteBipartite' );
	use_ok( 'Graph::Maker::Cycle' );
	use_ok( 'Graph::Maker::Degree' );
	use_ok( 'Graph::Maker::Disconnected' );
	use_ok( 'Graph::Maker::Disk' );
	use_ok( 'Graph::Maker::Empty' );
	use_ok( 'Graph::Maker::Grid' );
	use_ok( 'Graph::Maker::Hypercube' );
	use_ok( 'Graph::Maker::Ladder' );
	use_ok( 'Graph::Maker::Linear' );
	use_ok( 'Graph::Maker::Lollipop' );
	use_ok( 'Graph::Maker::Random' );
	use_ok( 'Graph::Maker::Regular' );
	use_ok( 'Graph::Maker::SmallWorldBA' );
	use_ok( 'Graph::Maker::SmallWorldHK' );
	use_ok( 'Graph::Maker::SmallWorldK' );
	use_ok( 'Graph::Maker::SmallWorldWS' );
	use_ok( 'Graph::Maker::Star' );
	use_ok( 'Graph::Maker::Uniform' );
	use_ok( 'Graph::Maker::Utils' );
	use_ok( 'Graph::Maker::Wheel' );
}

diag( "Testing Graph::Maker $Graph::Maker::VERSION, Perl $], $^X" );
