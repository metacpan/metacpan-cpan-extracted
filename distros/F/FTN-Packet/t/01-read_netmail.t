#!perl -T

use Test::More tests => 12;
use FTN::Packet;

my $message;

BEGIN {

    $message = FTN::Packet::read_ftn_packet('t/46926700.pkt');
    isnt( $message, undef, "Reference for netmail packet read." );

    note("A zero here means one message." );
    is_deeply( $#{$message}, q{0}, "Number of messages." );

    like( ${$message}[0]{area}, qr/NETMAIL/, "Area" );

    like( ${$message}[0]{ftscdate}, qr/04 Sep 12  19:44:39/, "Date" );

    like( ${$message}[0]{from}, qr/First Sysop/, "From" );
    like( ${$message}[0]{fromnode}, qr/1:99\/100/, "From Node" );

    like( ${$message}[0]{to}, qr/Second Sysop/, "To" );
    like( ${$message}[0]{tonode}, qr/1:99\/200/, "To Node" );

    like( ${$message}[0]{subj}, qr/Netmail Test Message/, "Subject" );

    like( ${$message}[0]{body}, qr/This is the body of a test netmail message./, "Message Body" );

    like( ${$message}[0]{msgid}, qr/1:99\/100.0 46926700/, "Message ID" );
    like( ${$message}[0]{ctrlinfo}, qr/46926700/, "Control Info" );

}


done_testing();

diag( "Test reading a netmail message from an packet file using FTN::Packet $FTN::Packet::VERSION." );
