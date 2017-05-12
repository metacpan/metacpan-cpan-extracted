#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'FTN::JAM' );
    use_ok( 'FTN::JAM::Attr' );
    use_ok( 'FTN::JAM::Errnum' );
    use_ok( 'FTN::JAM::Subfields' );
}

diag( "Testing FTN::JAM $FTN::JAM::VERSION, Perl $], $^X" );
