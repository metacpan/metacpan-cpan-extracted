#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Bank::Halifax::Sharedealing' ) || print "Bail out!
";
}

diag( "Testing Finance::Bank::Halifax::Sharedealing $Finance::Bank::Halifax::Sharedealing::VERSION, Perl $], $^X" );
