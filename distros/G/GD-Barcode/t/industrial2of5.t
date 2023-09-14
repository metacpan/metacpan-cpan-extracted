use Test2::V0;

use GD::Barcode;

is(GD::Barcode->new("Industrial2of5", "123")->barcode(), '1110111010111010101011101011101010111011101110101010111010111', 'Industrial2of5/3');

done_testing;