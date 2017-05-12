# test pdu encoding/decoding functions, specifically for CUSD responses from german eplus network

use strict;
use warnings;

use Test::More;
use Device::Gsm::Pdu;

BEGIN { plan tests => 2 };

# PDU without length...
my $pdu = "D37419840E8BCB6E10B92CD797D374D0BA9C7697414F383DFD7683CE65717D8CA6BB40DA7A1B544CBBE5E9319A5E7683CA6977590E7AC2E9E9B71B74DFA3D96537689A2E83C4693ABD0C2297DDA066D9ED87D7DD6B3A485C1FA3CB6E17";

my $plain = "Sie haben derzeit keine Option gebucht. Zum Einrichten einer Option w\xE4hlen Sie bitte den Men\xFCpunkt buchen.";

# Test en- and decoding of that message.

is(
    Device::Gsm::Pdu::pdu_to_latin1($pdu) => $plain,
    "Convert PDU '$pdu' to latin1 text"
);

is(
    Device::Gsm::Pdu::latin1_to_pdu($plain) => $pdu,
    "Convert latin1 text '$plain' to PDU"
);

# end of pdu library test
