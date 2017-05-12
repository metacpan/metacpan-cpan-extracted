#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JSON::SL' ) || print "Bail out!
";
}

diag( "Testing JSON::SL $JSON::SL::VERSION, Perl $], $^X" );
