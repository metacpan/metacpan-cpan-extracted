#!perl -T

use Test::More tests => 5;
use FTN::Packet;

my ( $netmail, $echomail, %header, @packet );

BEGIN {

    $netmail = FTN::Packet::read_ftn_packet('t/46926700.pkt');
    isnt( $netmail, undef, "Reference for netmail read packet." );

    $echomail = FTN::Packet::read_ftn_packet('t/46984d00.pkt');
    isnt( $echomail, undef, "Reference for echomail read packet." );

    push @packet, ${$netmail}[0];
    push @packet, ${$echomail}[0];

    note("A one here means the two messages to be written." );
    is( $#packet, q{1}, "Number of messages." );

    my %header = (
        origZone => q{1},
        origNet => q{99},
        origNode => q{100},
        origPoint => 0,
        destZone => q{1},
        destNet => q{99},
        destNode => q{200},
        destPoint => 0,
        Password => 'PassWord',
    );

}

TODO: {

    local $TODO = "write_ftn_packet not currently working.";

    fail("Calling write_ftn_packet fails.");

}

TODO: {

    local $TODO = "Comparing the contents of the messages needs to be implemented.";

    fail("Message contents not yet being compared.");

}

done_testing();

diag( "Test writing an netmail and an echomail message to a packet file using FTN::Packet $FTN::Packet::VERSION." );
