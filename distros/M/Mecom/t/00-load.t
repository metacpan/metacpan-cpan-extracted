#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Mecom' ) || print "Bail out!\n";
    use_ok( 'Mecom::Contact' ) || print "Bail out!\n";
    use_ok( 'Mecom::Surface' ) || print "Bail out!\n";
    use_ok( 'Mecom::Subsets' ) || print "Bail out!\n";
    use_ok( 'Mecom::Report' ) || print "Bail out!\n";
    use_ok( 'Mecom::Align::Subset' ) || print "Bail out!\n";
    use_ok( 'Mecom::EasyYang' ) || print "Bail out!\n";
    use_ok( 'Mecom::Statistics::RatioVariance' ) || print "Bail out!\n";
}

diag( "Testing Mecom $Mecom::VERSION, Perl $], $^X" );
