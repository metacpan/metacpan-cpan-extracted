#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Linux::ACL' ) || print "Bail out!
";
}

diag( "Testing Linux::ACL $Linux::ACL::VERSION, Perl $], $^X" );
