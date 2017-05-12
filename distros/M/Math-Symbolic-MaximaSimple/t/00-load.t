#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Math::Symbolic::MaximaSimple' ) || print "Bail out!
";
}

diag( "Testing Math::Symbolic::MaximaSimple $Math::Symbolic::MaximaSimple::VERSION, Perl $], $^X" );
