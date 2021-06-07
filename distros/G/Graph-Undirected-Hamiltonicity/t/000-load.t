#!perl
use Modern::Perl;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Graph::Undirected::Hamiltonicity' ) || say "Bail out Hamiltonicity!";
    use_ok( 'Graph::Undirected::Hamiltonicity::Output' ) || say "Bail out Output!";
    use_ok( 'Graph::Undirected::Hamiltonicity::Spoof' ) || say "Bail out Spoof!";
    use_ok( 'Graph::Undirected::Hamiltonicity::Transforms' ) || say "Bail out Transforms!";
    use_ok( 'Graph::Undirected::Hamiltonicity::Tests' ) || say "Bail out Tests!";
}

diag( "Testing Graph::Undirected::Hamiltonicity $Graph::Undirected::Hamiltonicity::VERSION, Perl $], $^X" );
