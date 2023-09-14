use Test2::V0;

use GD::Barcode::QRcode;

# it returns a hash
ok(GD::Barcode::QRcode->new('1234567'), 'Code39');

done_testing;