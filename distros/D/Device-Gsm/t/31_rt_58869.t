# Test decode/encode text7 

use strict;
use warnings;
use utf8;
use Test::More;

plan tests => 6;
 
use Device::Gsm::Pdu;

my @case = (
    '1234567',
	join("", "A".."Z"),
	join("", "a".."z"),
	join("", 0..9),
	join("", map { chr } 0..127),
	reverse join("", map { chr } 0..127),
);

for (@case) {
    my $text = $_;

    # Roundtrip test
    is(
        $text,
        Device::Gsm::Pdu::decode_text7(
            Device::Gsm::Pdu::encode_text7($text)
        ),
        'Round trip text7 conversion of "' . $text . '"'
    );

}

