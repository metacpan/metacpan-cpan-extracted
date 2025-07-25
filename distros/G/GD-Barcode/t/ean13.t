use Test2::V0;

use GD::Barcode;

is(GD::Barcode->new("EAN13", "123456789012")->barcode(), 'G0G0010011011110100111010110001000010100100010G0G0100100011101001110010110011011011001001000G0G', 'EAN13');

my $barcode = GD::Barcode->new("EAN13", "12345678901");
is($barcode, undef, 'EAN13 Invalid Length');
is($GD::Barcode::errStr, 'Invalid Length', 'EAN13 Invalid Length');

done_testing;
