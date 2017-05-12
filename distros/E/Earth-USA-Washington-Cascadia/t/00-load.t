#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Earth::USA::Washington::Cascadia' ) || print "Bail out!
";
}

diag( "Testing Earth::USA::Washington::Cascadia $Earth::USA::Washington::Cascadia::VERSION, Perl $], $^X" );
