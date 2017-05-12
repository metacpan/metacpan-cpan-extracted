#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Blarf' ) || print "Bail out!
";
}

diag( "Testing File::Blarf $File::Blarf::VERSION, Perl $], $^X" );
