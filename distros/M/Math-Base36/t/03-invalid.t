#!perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Math::Base36 ':all';

throws_ok {
    encode_base36('apple')
} qr/^Invalid base10 number \(apple\)/,
    'descriptive error for invalid base10 number';

throws_ok {
    encode_base36(123456, 'carrot')
} qr/^Invalid padding length \(carrot\)/,
    'descriptive error for invalid padding length';

throws_ok {
    decode_base36('123,456')
} qr/^Invalid base36 number \(123,456\)/,
    'descriptive error for invalid base36 number';

done_testing;
