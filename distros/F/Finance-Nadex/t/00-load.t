#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'Finance::Nadex' ) || print "Bail out!\n";
    use_ok( 'Finance::Nadex::Contract' ) || print "Bail out!\n";
    use_ok( 'Finance::Nadex::Order' ) || print "Bail out!\n";
    use_ok( 'Finance::Nadex::Position' ) || print "Bail out!\n";
}

diag( "Testing Finance::Nadex $Finance::Nadex::VERSION, Perl $], $^X" );

done_testing();
