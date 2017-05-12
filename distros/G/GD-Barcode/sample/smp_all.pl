use strict;
use GD::Barcode;

my $oGdBar;
#1)EAN13
#1.1 NORMAL
print "=======================\nEAN13: NORMAL\n";
$oGdBar = GD::Barcode->new('EAN13', '123456789012');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>EAN13.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#1.2 Error
print "EAN13: ERROR\n";
$oGdBar = GD::Barcode->new('EAN13', '12345678901');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#2)EAN8
#2.1 NORMAL
print "=======================\nEAN8: NORMAL\n";
$oGdBar = GD::Barcode->new('EAN8', '1234567');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>EAN8.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#2.2 Error
print "EAN8: ERROR\n";
$oGdBar = GD::Barcode->new('EAN8', 'A1234567');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#3)UPC-A
#3.1 NORMAL
print "=======================\nUPCA: NORMAL\n";
$oGdBar = GD::Barcode->new('UPCA', '12345678901');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>UPCA.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#3.2 Error
print "UPCA: ERROR\n";
$oGdBar = GD::Barcode->new('UPCA','12345678901132');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#4)UPC-E
#4.1 NORMAL
print "=======================\nUPCE: NORMAL\n";
$oGdBar = GD::Barcode->new('UPCE', '1234567');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>UPCE.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#4.2 Error
print "UPCE: ERROR\n";
$oGdBar = GD::Barcode->new('UPCE', '123456788');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#5)NW7
#5.1 NORMAL
print "=======================\nNW7: NORMAL\n";
$oGdBar = GD::Barcode->new('NW7', '12345678');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>NW7.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#5.2 Error
print "NW7: ERROR\n";
$oGdBar = GD::Barcode->new('NW7', 'NW7ERROR');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#6)CODE-39
#6.1 NORMAL
print "=======================\nCode39: NORMAL\n";
$oGdBar = GD::Barcode->new('Code39', '*123456789012*');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>Code39.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#6.2 Error
print "Code39: ERROR\n";
$oGdBar = GD::Barcode->new('Code39', '*12345678901;*');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#7)ITF(Interleaved 2 of 5)
#7.1 NORMAL
print "=======================\nITF: NORMAL\n";
$oGdBar = GD::Barcode->new('ITF', '0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>ITF.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#7.2 Error
print "ITF: ERROR\n";
$oGdBar = GD::Barcode->new('ITF', '123456788A');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#8)Industrial2of5
#8.1 NORMAL
print "=======================\nIndustrial2of5: NORMAL\n";
$oGdBar = GD::Barcode->new('Industrial2of5', '0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>Industrial2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#8.2 Error
print "Industrial2of5: ERROR\n";
$oGdBar = GD::Barcode->new('Industrial2of5', '123456788A');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#9)IATA2of5
#9.1 NORMAL
print "=======================\nIATA2of5: NORMAL\n";
$oGdBar = GD::Barcode->new('IATA2of5', '0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>IATA2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#9.2 Error
print "IATA2of5: ERROR\n";
$oGdBar = GD::Barcode->new('IATA2of5', '123456788A');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#10)Matrix2of5
#10.1 NORMAL
print "=======================\nMatrix2of5: NORMAL\n";
$oGdBar = GD::Barcode->new('Matrix2of5', '0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>Matrix2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#10.2 Error
print "Matrix2of5: ERROR\n";
$oGdBar = GD::Barcode->new('Matrix2of5', '123456788A');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#11)COOP2of5
#11.1 NORMAL
print "=======================\nCOOP2of5: NORMAL\n";
$oGdBar = GD::Barcode->new('COOP2of5', '0123456789');
print "PTN:", $oGdBar->{text}, ":" ,$oGdBar->barcode, "\n";
open(OUT, '>COOP2of5.png');
binmode OUT;                                    #for Windows
print OUT $oGdBar->plot->png;
close OUT;
undef $oGdBar;

#11.2 Error
print "COOP2of5: ERROR\n";
$oGdBar = GD::Barcode->new('COOP2of5', '123456788A');
print "ERROR:", $GD::Barcode::errStr, "\n";
undef $oGdBar;

#12)QRCode
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
