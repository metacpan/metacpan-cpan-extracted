use strict;
use GD::Barcode::EAN8;
use GD::Barcode::EAN13;
use GD::Barcode::UPCA;
use GD::Barcode::UPCE;
use GD::Barcode::NW7;
use GD::Barcode::Code39;
use GD::Barcode::ITF;
use GD::Barcode::Industrial2of5;
use GD::Barcode::Matrix2of5;
use GD::Barcode::IATA2of5;
use GD::Barcode::COOP2of5;
use GD::Barcode::QRcode;

my $oGdBar;
#1)EAN13
#1.1 NORMAL
print "=======================\nEAN13: NORMAL\n";
$oGdBar = GD::Barcode::EAN13->new('123456789012');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>EAN13.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#1.2 Error
print "EAN13: ERROR\n";
$oGdBar = GD::Barcode::EAN13->new('12345678901');
print "ERROR:", $GD::Barcode::EAN13::errStr, "\n";
undef $oGdBar;

#2)EAN8
#2.1 NORMAL
print "=======================\nEAN8: NORMAL\n";
$oGdBar = GD::Barcode::EAN8->new('1234567');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>EAN8.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#2.2 Error
print "EAN8: ERROR\n";
$oGdBar = GD::Barcode::EAN8->new('A1234567');
print "ERROR:", $GD::Barcode::EAN8::errStr, "\n";
undef $oGdBar;

#3)UPC-A
#3.1 NORMAL
print "=======================\nUPCA: NORMAL\n";
$oGdBar = GD::Barcode::UPCA->new('12345678901');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>UPCA.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#3.2 Error
print "UPCA: ERROR\n";
$oGdBar = GD::Barcode::UPCA->new('12345678901132');
print "ERROR:", $GD::Barcode::UPCA::errStr, "\n";
undef $oGdBar;

#4)UPC-E
#4.1 NORMAL
print "=======================\nUPCE: NORMAL\n";
$oGdBar = GD::Barcode::UPCE->new('1234567');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>UPCE.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#4.2 Error
print "UPCE: ERROR\n";
$oGdBar = GD::Barcode::UPCE->new('123456788');
print "ERROR:", $GD::Barcode::UPCE::errStr, "\n";
undef $oGdBar;

#5)NW7
#5.1 NORMAL
print "=======================\nNW7: NORMAL\n";
$oGdBar = GD::Barcode::NW7->new('12345678');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>NW7.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#5.2 Error
print "NW7: ERROR\n";
$oGdBar = GD::Barcode::NW7->new('NW7ERROR');
print "ERROR:", $GD::Barcode::NW7::errStr, "\n";
undef $oGdBar;

#6)CODE-39
#6.1 NORMAL
print "=======================\nCode39: NORMAL\n";
$oGdBar = GD::Barcode::Code39->new('*123456789012*');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>Code39.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#6.2 Error
print "Code39: ERROR\n";
$oGdBar = GD::Barcode::Code39->new('*12345678901;*');
print "ERROR:", $GD::Barcode::Code39::errStr, "\n";
undef $oGdBar;

#7)ITF
#7.1 NORMAL
print "=======================\nITF: NORMAL\n";
$oGdBar = GD::Barcode::Code39->new('1234567890*');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>ITF.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#7.2 Error
print "ITF: ERROR\n";
$oGdBar = GD::Barcode::ITF->new('*1234567');
print "ERROR:", $GD::Barcode::ITF::errStr, "\n";
undef $oGdBar;

#8. Industrial2of5
#8.1 NORMAL
print "=======================\nIndustrial2of5: NORMAL\n";
$oGdBar = GD::Barcode::Industrial2of5->new('0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>Industrial2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#8.2 Error
print "Industrial2of5: ERROR\n";
$oGdBar = GD::Barcode::Industrial2of5->new('A12345678901');
print "ERROR:", $GD::Barcode::Industrial2of5::errStr, "\n";
undef $oGdBar;

#9. IATA2of5
#9.1 NORMAL
print "=======================\nIATA2of5: NORMAL\n";
$oGdBar = GD::Barcode::IATA2of5->new('0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>IATA2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#10.2 Error
print "IATA2of5: ERROR\n";
$oGdBar = GD::Barcode::IATA2of5->new('A12345678901');
print "ERROR:", $GD::Barcode::IATA2of5::errStr, "\n";
undef $oGdBar;

#10. Matrix2of5
#10.1 NORMAL
print "=======================\nMatrix2of5: NORMAL\n";
$oGdBar = GD::Barcode::Matrix2of5->new('0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>Matrix2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#10.2 Error
print "Matrix2of5: ERROR\n";
$oGdBar = GD::Barcode::Matrix2of5->new('A12345678901');
print "ERROR:", $GD::Barcode::Matrix2of5::errStr, "\n";
undef $oGdBar;

#11. COOP2of5
#11.1 NORMAL
print "=======================\nCOOP2of5: NORMAL\n";
$oGdBar = GD::Barcode::COOP2of5->new('0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>COOP2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#11.2 Error
print "COOP2of5: ERROR\n";
$oGdBar = GD::Barcode::COOP2of5->new('A12345678901');
print "ERROR:", $GD::Barcode::COOP2of5::errStr, "\n";
undef $oGdBar;

#12. QRcode
#12.1 NORMAL
print "=======================\nQRcode: NORMAL\n";
$oGdBar = GD::Barcode->new('QRcode', '123456789012',
                    { Ecc => 'M',
                      ModuleSize => 2,
                    });
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>QRcode.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;
