#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::MtGox' ) || print "Bail out!
";
}

diag( "Testing Finance::MtGox $Finance::MtGox::VERSION, Perl $], $^X" );
