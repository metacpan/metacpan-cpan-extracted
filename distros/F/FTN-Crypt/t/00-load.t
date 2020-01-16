#!perl -T
use v5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'FTN::Crypt' ) || print "Bail out!\n";
    use_ok( 'FTN::Crypt::Constants' ) || print "Bail out!\n";
    use_ok( 'FTN::Crypt::Error' ) || print "Bail out!\n";
    use_ok( 'FTN::Crypt::Msg' ) || print "Bail out!\n";
    use_ok( 'FTN::Crypt::Nodelist' ) || print "Bail out!\n";
}

diag( "Testing FTN::Crypt $FTN::Crypt::VERSION, Perl $], $^X" );
