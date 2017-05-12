#!/usr/bin/perl
# For simplified test responses
use Test;

BEGIN { $|=1; plan test => 15 }

# The modules we're testing
ok( eval "require GD::Graph::bars3d" );
ok( eval "require GD::Graph::lines3d" );
ok( eval "require GD::Graph::pie3d" );
ok( eval "require GD::Graph::cylinder" );
ok( eval "require GD::Graph::cylinder3d" );



$graph = new GD::Graph::bars3d();
ok( $graph );

@data = (
           ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
           [ 1203,  3500,  3973,  2859,  3012,  3423,  1230]
        );

ok( $graph->plot( \@data ) );



$graph = new GD::Graph::lines3d();
ok( $graph );

@data = (
           ["Jan 1", "Jan 2", "Jan 3", "Jan 4", "Jan 5", "Jan 6", "Jan 7"],
           [ 120,  350,  397,  540,  110,  287,  287]
        );
ok( $graph->plot( \@data ) );



$graph = new GD::Graph::pie3d();
ok( $graph );

@data = (
           [".com", ".net", ".gov", ".org", ".de", ".uk", "Other"],
           [ 37,  25,  9,  7,  11,  3,  8]
        );

ok( $graph->plot( \@data ) );



$graph = new GD::Graph::cylinder();
ok( $graph );

@data = (
           [".com", ".net", ".gov", ".org", ".de", ".uk", "Other"],
           [ 37,  25,  9,  7,  11,  3,  8]
        );

ok( $graph->plot( \@data ) );



$graph = new GD::Graph::cylinder3d();
ok( $graph );

@data = (
           [".com", ".net", ".gov", ".org", ".de", ".uk", "Other"],
           [ 37,  25,  9,  7,  11,  3,  8]
        );

ok( $graph->plot( \@data ) );



