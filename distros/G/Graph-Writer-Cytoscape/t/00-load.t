#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Graph::Writer::Cytoscape' ) || print "Bail out!
";
}

diag( "Testing Graph::Writer::Cytoscape $Graph::Writer::Cytoscape::VERSION, Perl $], $^X" );
