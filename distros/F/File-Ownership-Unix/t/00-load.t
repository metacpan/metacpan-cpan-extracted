#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Ownership::Unix' ) || print "Bail out!
";
}

diag( "Testing File::Ownership::Unix $File::Ownership::Unix::VERSION, Perl $], $^X" );
