#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mail::Header::Generator' ) || print "Bail out!
";
}

diag( "Testing Mail::Header::Generator $Mail::Header::Generator::VERSION, Perl $], $^X" );
