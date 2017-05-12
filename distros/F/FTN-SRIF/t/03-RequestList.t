#!perl -T

use Test::More tests => 2;
use FTN::SRIF;

my $srif;

BEGIN {

    $requests = FTN::SRIF::get_request_list('t/FTN/00000001.REQ');
    isnt( $requests, undef, "Array reference containing the request lines." );

    like( ${$requests}[0], qr/FILES/, "First request line." );

};

done_testing();

diag( "Test the reading of a requests file using FTN::SRIF $FTN::SRIF::VERSION." );
