#!perl -T

use Test::More tests => 9;
use FTN::SRIF;

my $srif;

BEGIN {

    $srif = FTN::SRIF::parse_srif('t/FTN/BINKD.SRF');
    isnt( $srif, undef, "Hash reference containing the SRIF file contents." );

    like( ${$srif}{'Sysop'}, qr/Sysop Name/, "Sysop Name" );

    like( ${$srif}{'Akas'}[0], qr/1\:99\/99\@fidonet/, "Main FTN AKA" );

    like( ${$srif}{'Baud'}, qr/9600/, "Baud" );

    like( ${$srif}{'Time'}, qr/-1/, "Time" );

    like( ${$srif}{'RequestList'}, qr/t\/FTN\/00000001.REQ/, "Request List file name" );

    like( ${$srif}{'ResponseList'}, qr/t\/FTN\/00000001.RSP/, "Response List file name" );

    like( ${$srif}{'RemoteStatus'}, qr/PROTECTED/, "Remote Status" );

    like( ${$srif}{'SystemStatus'}, qr/LISTED/, "System Status" );
};

done_testing();

diag( "Test parsing of required keywords from an S.R.I.F file using FTN::SRIF $FTN::SRIF::VERSION." );
