use Test2::V0;

use GD::Barcode::NW7;

# also called 'codabar'
# can have 1234567890ABCD-$#:/.+ but not EF!!
my $barcode = '10101110001010100010111011101011101110101110001000101000100010111011101011101110111010111011101010001000111010100011100010';
is(GD::Barcode::NW7->new("12:AB::CD")->barcode(), $barcode, 'NW7');

done_testing;