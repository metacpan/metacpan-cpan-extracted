#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'FTN::Message::serialno' ) || print "Bail out!\n";
    use_ok( 'FTN::Message::serialno::File' ) || print "Bail out!\n";
}

diag( "Testing FTN::Message::serialno $FTN::Message::serialno::VERSION and FTN::Message::serialno::File $FTN::Message::serialno::File::VERSION, Perl $], $^X" );
