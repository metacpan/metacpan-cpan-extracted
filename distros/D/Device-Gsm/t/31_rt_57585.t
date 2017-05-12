# test pdu encoding/decoding functions for sms

use Test::More;
use Device::Gsm::Pdu;

BEGIN { plan tests => 5 };

# Test decoding unicode strings

is( Device::Gsm::Pdu::decode_text_UCS2('020041'), "A");

#1 U+0061	a	61	LATIN SMALL LETTER A
is( Device::Gsm::Pdu::decode_text_UCS2('020061'), "\x61");
#2 U+00C0	À	c3 80	LATIN CAPITAL LETTER A WITH GRAVE
is( Device::Gsm::Pdu::decode_text_UCS2('0200C0'), "\xC3\x80");
#3 U+0160	Š	c5 a0	LATIN CAPITAL LETTER S WITH CARON
is( Device::Gsm::Pdu::decode_text_UCS2('020160'), "\xC5\xA0");
#4 U+0202	Ȃ	c8 82	LATIN CAPITAL LETTER A WITH INVERTED BREVE
is( Device::Gsm::Pdu::decode_text_UCS2('020202'), "\xC8\x82");

