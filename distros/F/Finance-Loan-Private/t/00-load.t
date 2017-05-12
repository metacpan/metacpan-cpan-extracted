#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Loan::Private' ) || print "Bail out!
";
}

diag( "Testing Finance::Loan::Private $Finance::Loan::Private::VERSION, Perl $], $^X" );
