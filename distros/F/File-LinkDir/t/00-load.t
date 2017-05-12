#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::LinkDir' ) || print "Bail out!
";
}

diag( "Testing File::LinkDir $File::LinkDir::VERSION, Perl $], $^X" );
