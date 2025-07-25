use Test2::V0;
use Test2::Require::Module 'GD';

use GD::Barcode::QRcode;
use File::Temp qw(tempfile);
use File::stat;

my $qrcode = GD::Barcode::QRcode->new('https://github.com/mbeijen/GD-Barcode/commit/af0ac08c05df03c2088e3f472633d9249c4883ca',
{ModuleSize => 1});
ok($qrcode, 'QRcode');

my ($fh, $filename) = tempfile();
binmode $fh;
print $fh $qrcode->plot->png;
close $fh;

my $filesize = stat($filename)->size;
ok($filesize > 0, 'Generated PNG file is not empty');

unlink $filename or diag "Could not unlink $filename: $!";

done_testing();
