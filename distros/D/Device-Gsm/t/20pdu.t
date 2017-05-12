# test pdu encoding/decoding functions for sms

use Test::More;
use Device::Gsm::Pdu;

BEGIN { plan tests => 17 };

# Test encoding mobile numbers
is( Device::Gsm::Pdu::encode_address('3289287791'),    '0A812398827719'   ); #1
is( Device::Gsm::Pdu::encode_address('+393289287791'), '0C91932398827719' ); #2
is( Device::Gsm::Pdu::encode_address('347101010'),     '098143171010F0'   ); #3
is( Device::Gsm::Pdu::encode_address('+39347101010'),  '0B919343171010F0' ); #4

# Address decoding
is( Device::Gsm::Pdu::decode_address('0A812398827719'), '3289287791' );
is( Device::Gsm::Pdu::decode_address('0A811234567890'), '2143658709' );         #5
is( Device::Gsm::Pdu::decode_address('0C91731234567890'), '+372143658709' );    #6
is( Device::Gsm::Pdu::decode_address('0D91941234567890F1'), '+4921436587091' ); #7

# Test encoding some text (no test with international chars)
is( Device::Gsm::Pdu::encode_text7( 'hellohello' ), '0AE8329BFD4697D9EC37' );   #8
is( Device::Gsm::Pdu::encode_text7( 'The quick fox jumps over the lazy dog' ), '2554741914AFA7C76B90F98D07A9EB6DF81CF4B697E5203ABA0C6287F57910F97D06' ); #9

# Decoding the same text (no test with international chars)
is( Device::Gsm::Pdu::decode_text7( '0AE8329BFD4697D9EC37' ), 'hellohello' );   #10
is( Device::Gsm::Pdu::decode_text7( '2554741914AFA7C76B90F98D07A9EB6DF81CF4B697E5203ABA0C6287F57910F97D06'), 'The quick fox jumps over the lazy dog' ); #12

# Self-test on longer strings
is( Device::Gsm::Pdu::decode_text7( Device::Gsm::Pdu::encode_text7($_) ), $_ )
    for(
        'hellohello',
        'The quick brown fox jumps over the lazy dog',
        'La marianna la va in campagna, quando il sole tramontera\'... chissa\' quando, chissa\' quando ritornera\''
    );

# Alphabetical address decoding
is( Device::Gsm::Pdu::decode_address('10D06B7658DE7E8BD36C'), "klarmobil\0" ); #7

# CPAN Bug #24781 regression test
my $enc = Device::Gsm::Pdu::encode_address('+393289287791');
my $dec = Device::Gsm::Pdu::decode_address($enc);
is($dec, '+393289287791', 'intl address without ++ (CPAN Bug #24781)');

# end of pdu library test
