use strict;
use GD::Barcode::QRcode;
# with GD::Barcode::QRcode;
my $oGDB = GD::Barcode::QRcode->new('A' x 10, 
                {Ecc=>'L', ModuleSize => 4 });
my $oGD = $oGDB->plot();
open OUT, '>', 'qrc4.png';
binmode OUT;
print OUT $oGD->png;
close OUT;

open OUT, '>', 'qrc4.txt';
print OUT $oGDB->barcode();
close OUT;

# with GD::Barcode;
use GD::Barcode;
my $oGDN = GD::Barcode->new('QRcode', 'A' x 10, 
                        {Ecc => 'L', ModuleSize => 2});

open OUT, '>', 'bar2.png';
binmode OUT;
print OUT $oGDN->plot()->png;
close OUT;
open OUT, '>', 'bar2.txt';
print OUT $oGDN->barcode();
close OUT;
