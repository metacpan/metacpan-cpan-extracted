use Test2::V0;

use GD::Barcode;
use File::Temp qw(tempfile);
use File::stat;

use Test2::Require::Module 'GD';


my $oGdBar = GD::Barcode->new("EAN13", "123456789012");

my ($fh, $filename) = tempfile();
binmode $fh;
print $fh $oGdBar->plot->png;
close $fh;

my $filesize = stat($filename)->size;
ok($filesize > 0, 'Generated PNG file is not empty');

unlink $filename or diag "Could not unlink $filename: $!";

done_testing();
