#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Kitko::Charts' ) || print "Bail out!\n";
}

diag( "Testing Finance::Kitko::Charts $Finance::Kitko::Charts::VERSION, Perl $], $^X" );
