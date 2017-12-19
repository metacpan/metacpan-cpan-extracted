use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub test_encode {
    $duk->set_top(0);
    $duk->push_string("foo");
    $duk->push_int(123);  #  dummy */
    printf("hex encode: %s\n", $duk->hex_encode(-2));
    printf("top after: %ld\n", $duk->get_top());  #  value + dummy */
    return 0;
}

sub test_decode {
    $duk->set_top(0);
    $duk->push_string("7465737420737472696e67");
    $duk->push_int(321);  #  dummy */
    $duk->hex_decode(-2);  #  buffer */
    printf("hex decode: %s\n", $duk->buffer_to_string(-2));
    printf("top after: %ld\n", $duk->get_top());  #  value + dummy */
    $duk->set_top(0);
    return 0;
}

sub test_decode_odd_length {
    $duk->set_top(0);
    $duk->push_string("7465737420737472696e6");  #  odd length */
    $duk->push_int(321);  #  dummy */
    $duk->hex_decode(-2);  #  buffer */
    printf("hex decode: %s\n", $duk->buffer_to_string(-2));
    printf("top after: %ld\n", $duk->get_top());  #  value + dummy */
    $duk->set_top(0);
    return 0;
}

sub test_decode_invalid_char {
    $duk->set_top(0);
    $duk->push_string("7465737420737g72696e67");  #  invalid char */
    $duk->push_int(321);  #  dummy */
    $duk->hex_decode(-2);  #  buffer */
    printf("hex decode: %s\n", $duk->buffer_to_string(-2));
    printf("top after: %ld\n", $duk->get_top());  #  value + dummy */
    $duk->set_top(0);
    return 0;
}


TEST_SAFE_CALL($duk, \&test_encode, 'test_encode');
TEST_SAFE_CALL($duk, \&test_decode, 'test_decode');
TEST_SAFE_CALL($duk, \&test_decode_odd_length, 'test_decode_odd_length');
TEST_SAFE_CALL($duk, \&test_decode_invalid_char, 'test_decode_invalid_char');

test_stdout();

__DATA__
*** test_encode (duk_safe_call)
hex encode: 666f6f
top after: 2
==> rc=0, result='undefined'
*** test_decode (duk_safe_call)
hex decode: test string
top after: 2
==> rc=0, result='undefined'
*** test_decode_odd_length (duk_safe_call)
==> rc=1, result='TypeError: hex decode failed'
*** test_decode_invalid_char (duk_safe_call)
==> rc=1, result='TypeError: hex decode failed'
