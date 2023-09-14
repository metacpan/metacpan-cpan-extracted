use Test2::V0;

use GD::Barcode;

# 11 numbers, with check digit 12

my $barcode = 'G0G0GGG0GG001001101100010010011011101100100110G0G010001001000010111001010001001110010G0G0000G0G';

is(GD::Barcode->new("UPCA", "72527273070")->barcode(), $barcode, 'UPCA wo/check');
is(GD::Barcode->new("UPCA", "725272730706")->barcode(), $barcode, 'UPCA w/check');

done_testing;