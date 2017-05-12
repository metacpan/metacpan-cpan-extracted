#!perl -T

use Test::More tests => 12;
use FTN::Packet;

my $message;

BEGIN {

    $message = FTN::Packet::read_ftn_packet('t/46984d00.pkt');
    isnt( $message, undef, "Reference for echomail packet read." );

    note("A one here means two messages." );
    is_deeply( $#{$message}, q{0}, "Number of messages." );

    like( ${$message}[0]{area}, qr/FIDOTEST/, "Area" );

    like( ${$message}[0]{ftscdate}, qr/04 Sep 12  20:09:49/, "Date" );

    like( ${$message}[0]{from}, qr/First Sysop/, "From" );
    like( ${$message}[0]{fromnode}, qr/1:99\/100/, "From Node" );

    like( ${$message}[0]{to}, qr/Second Sysop/, "To" );
    like( ${$message}[0]{tonode}, qr/1:99\/200/, "To Node" );

    like( ${$message}[0]{subj}, qr/Echomail Test Message/, "Subject" );

    like( ${$message}[0]{body}, qr/This is the body of a test echomail message./, "Message Body" );

    like( ${$message}[0]{msgid}, qr/1:99\/100.0 46984d00/, "Message ID" );
    like( ${$message}[0]{ctrlinfo}, qr/46984d00/, "Control Info" );

}


done_testing();

diag( "Test reading an echomail message from an FTN packet file using FTN::Packet $FTN::Packet::VERSION." );
