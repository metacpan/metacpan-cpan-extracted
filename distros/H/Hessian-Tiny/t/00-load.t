#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hessian::Tiny::Client' ) || print "Bail out!
";
}

diag( "Testing Hessian::Tiny::Client $Hessian::Tiny::Client::VERSION, Perl $], $^X" );
