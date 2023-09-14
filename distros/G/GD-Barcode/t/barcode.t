use Test2::V0;

use GD::Barcode;

is(GD::Barcode->new("notexisting", "123"), undef);
like($GD::Barcode::errStr, qr/^Can't load notexisting/);

done_testing();