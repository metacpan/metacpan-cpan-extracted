#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTTP::Body::MultiPart::Extend' ) || print "Bail out!
";
}

diag( "Testing HTTP::Body::MultiPart::Extend $HTTP::Body::MultiPart::Extend::VERSION, Perl $], $^X" );
