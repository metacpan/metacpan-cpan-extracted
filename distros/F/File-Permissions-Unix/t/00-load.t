#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Permissions::Unix' ) || print "Bail out!
";
}

diag( "Testing File::Permissions::Unix $File::Permissions::Unix::VERSION, Perl $], $^X" );
