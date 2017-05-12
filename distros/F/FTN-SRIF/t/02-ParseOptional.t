#!perl -T

use Test::More tests => 6;
use FTN::SRIF;

my $srif;

BEGIN {

    $srif = FTN::SRIF::parse_srif('t/FTN/BINKD.SRF');
    isnt( $srif, undef, "Hash reference containing the SRIF file contents." );

    like( ${$srif}{'Akas'}[1], qr/9\:99\/999\@testing/, "Second FTN AKA" );

    like( ${$srif}{'Akas'}[2], qr/9\:99\/999.9\@testing/, "Third FTN AKA(point)" );

    like( ${$srif}{'CallerID'}, qr/localhost/, "Caller ID" );

    like( ${$srif}{'Password'}, qr/Testing/, "Session Type" );

    like( ${$srif}{'SessionType'}, qr/OTHER/, "Session Type" );

};

done_testing();

diag( "Test parsing of some optional keywords from an S.R.I.F file using FTN::SRIF $FTN::SRIF::VERSION." );
