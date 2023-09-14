use Test2::V0;

use GD::Barcode::ITF;

# ah, it calculates the check number automatically
# see for example https://www.gs1standards.info/itf-14-barcodes/
my $barcode = '101011101010001000111010001011101110100010001110001010111010001011100010111010101110001110001010101110001110001011101010100011100011101';
is(GD::Barcode::ITF->new("1001234500001")->barcode(), $barcode, 'ITF without check');
is(GD::Barcode::ITF->new("10012345000017")->barcode(), $barcode, 'ITF with check');

done_testing;