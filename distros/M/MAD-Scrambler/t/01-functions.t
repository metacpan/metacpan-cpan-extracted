#!perl

use Test::Most;
use MAD::Scrambler qw{ nibble_split nibble_join };

my @nibbles;
my $number;

@nibbles = nibble_split(0x12569ADE);
is_deeply \@nibbles, [ 14, 13, 10, 9, 6, 5, 2, 1 ], 'nibble_split';

@nibbles = qw{ 15 13 11 9 7 5 3 1 };
$number  = nibble_join(@nibbles);
is $number, 0x13579BDF, 'nibble_join';

done_testing;

