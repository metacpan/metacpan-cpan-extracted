#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::TTX' ) || print "Bail out!
";
}

diag( "Testing File::TTX $File::TTX::VERSION, Perl $], $^X" );
