#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Medical::ICD10' ) || print "Bail out!
";
}

diag( "Testing Medical::ICD10 $Medical::ICD10::VERSION, Perl $], $^X" );
