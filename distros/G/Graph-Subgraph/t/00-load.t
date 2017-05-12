#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Graph::Subgraph' ) || print "Bail out!
";
}

diag( "Testing Graph::Subgraph $Graph::Subgraph::VERSION, Perl $], $^X" );
