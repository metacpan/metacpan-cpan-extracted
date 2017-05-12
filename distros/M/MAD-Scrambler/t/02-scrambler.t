#!perl

use Test::Most;
use MAD::Scrambler;

my ( $scrambler, $number, $code );

$scrambler = MAD::Scrambler->new(
    scrambler => [ 1, 3, 5, 7, 0, 2, 4, 6 ],
    bit_mask  => 0xFDB97531,
);

## Encoding a number
$code = $scrambler->encode(0x0000002A);
is $code, 0xFDB37533, 'encode(0x0000002A) -> 0xFDB37533';

$number = $scrambler->decode($code);
is $number, 0x0000002A, 'decode(0xFDB37533) -> 0x0000002A';

## Encoding 0
$code = $scrambler->encode(0x00000000);
is $code, 0xFDB97531, 'encode(0x00000000) -> 0xFDB97531';

$number = $scrambler->decode($code);
is $number, 0x00000000, 'decode(0xFDB97531) -> 0x00000000';

## Encoding to 0
$code = $scrambler->encode(0x7F5D3B19);
is $code, 0x00000000, 'encode(0x7F5D3B19) -> 0x00000000';

$number = $scrambler->decode($code);
is $number, 0x7F5D3B19, 'decode(0x00000000) -> 0x7F5D3B19';

done_testing;

