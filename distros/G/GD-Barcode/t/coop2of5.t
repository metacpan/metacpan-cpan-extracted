use Test2::V0;

use GD::Barcode;

is(GD::Barcode->new("COOP2of5", "123")->barcode(), '111011101010001110101110111010111000101000111');

done_testing;