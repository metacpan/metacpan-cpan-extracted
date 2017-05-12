package GD::Barcode::UPCE;
use strict;
BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=1.10;
my $oddEven4UPCE = {
 0 => 'EEEOOO',
 1 => 'EEOEOO',
 2 => 'EEOOEO',
 3 => 'EEOOOE',
 4 => 'EOEEOO',
 5 => 'EOOEEO',
 6 => 'EOOOEE',
 7 => 'EOEOEO',
 8 => 'EOEOOE',
 9 => 'EOOEOE'
};
my $leftOddBar ={
 '0' => '0001101',
 '1' => '0011001',
 '2' => '0010011',
 '3' => '0111101',
 '4' => '0100011',
 '5' => '0110001',
 '6' => '0101111',
 '7' => '0111011',
 '8' => '0110111',
 '9' => '0001011'
};
my $leftEvenBar = {
 '0' => '0100111',
 '1' => '0110011',
 '2' => '0011011',
 '3' => '0100001',
 '4' => '0011101',
 '5' => '0111001',
 '6' => '0000101',
 '7' => '0010001',
 '8' => '0001001',
 '9' => '0010111'
};
my $guardBar = 'G0G';
my $UPCrightGuardBar = '0G0G0G';
#------------------------------------------------------------------------------
# new (for Spreadsheet::ParseExcel)
#------------------------------------------------------------------------------
sub new($$) {
  my($sClass, $sTxt) = @_;
  $errStr ='';
  my $oThis = {};
  bless $oThis;
  return undef if($errStr = $oThis->init($sTxt));
  return $oThis;
}
#------------------------------------------------------------------------------
# init (for Spreadsheet::ParseExcel)
#------------------------------------------------------------------------------
sub init($$){
        my($oThis, $sTxt) =@_;
        return 'Invalid characters' if($sTxt =~ /[^0-9]/); 

#Check
    my $iLen = length($sTxt);
        if( $iLen == 6 ) {
                $sTxt = '0' . $sTxt;
        $sTxt .= calcUPCECD( $sTxt );
        }
        elsif($iLen == 7) {
        $sTxt .= calcUPCECD( $sTxt );
        }
        elsif($iLen == 8) {
                ;
        }
        else {
                return 'Invalid Length';
        }
        $oThis->{text} = $sTxt;
        return '';
}
#------------------------------------------------------------------------------
# calcUPCACD (for GD::Barcode::UPCE)
#------------------------------------------------------------------------------
sub calcUPCACD {
  my( $sTxt ) = @_;
  my( $i, $iSum, @aWeight);

  @aWeight = (3,1,3,1,3,1,3,1,3,1,3);
  $iSum = 0;
  for( $i = 0; $i < 11; $i++ ) {
      $iSum += substr($sTxt, $i, 1)  * $aWeight[$i];
  }
  $iSum %= 10;
  $iSum = ($iSum == 0)? 0: (10 - $iSum);
  return "$iSum";
}
#------------------------------------------------------------------------------
# calcUPCECD (for GD::Barcode::UPCE)
#------------------------------------------------------------------------------
sub calcUPCECD {
  my( $sTxt ) =@_;
  my( $upcA );

  my $cLast = substr($sTxt, 6, 1);
  if ($cLast =~ /[0-2]/) {      #0,1,2
        $upcA = substr($sTxt, 0, 3). $cLast . '0' x 4 . substr($sTxt, 3, 3);
  }
  elsif ($cLast eq '3') {
        $upcA = substr($sTxt, 0, 4) . '0' x 5 . substr($sTxt, 4, 2);
  }
  elsif ($cLast eq '4') {
        $upcA = substr($sTxt, 0, 5) . '0' x 5 . substr($sTxt, 5, 1);
  }
  else  { # $cLast =~ /5-9/
        $upcA = substr($sTxt, 0, 6) . '0' x 4 . $cLast;
  }
  return &calcUPCACD( $upcA );
}
#------------------------------------------------------------------------------
# barcode (for GD::Barcode::UPCE)
#------------------------------------------------------------------------------
sub barcode($) {
  my ($oThis) = @_;
  my ($topDigit, $oddEven, $c, $i);
  my ($sRes);

#(1)Init
  my $sTxt = $oThis->{text};
  $sRes = $guardBar;            #GUARD
  $oddEven = $oddEven4UPCE->{substr($sTxt, 7, 1)};

#(2)Left 6 (Skip 1 character)
    for( $i = 1; $i < 7; $i++ ){
        $c = substr($sTxt, $i, 1);
                $sRes .= GD::Barcode::barPtn($c, 
                                ( substr($oddEven, $i-1, 1) eq 'O' )?
                                                $leftOddBar : $leftEvenBar);
    }
#
  $sRes .= $UPCrightGuardBar;
  return $sRes;

}
#------------------------------------------------------------------------------
# plot (for Spreadsheet::ParseExcel)
#------------------------------------------------------------------------------
sub plot($%) {
  my($oThis, %hParam) =@_;
  my $sTxt = $oThis->{text};
  my $sPtn = $oThis->barcode();

#Create Image
  my $iHeight = ($hParam{Height})? $hParam{Height} : 50;
  my ($oGd, $cBlack);
  if($hParam{NoText}) {
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, length($sPtn), $iHeight, 0, 0);
  }
  else {
        my($fW,$fH) = (GD::Font->Small->width, GD::Font->Small->height);
        my $iWidth = length($sPtn)+ 2*($fW+1);
        #Bar Image
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, $iWidth, $iHeight, $fH, $fW+1);
        #String
        $oGd->string(GD::Font->Small,        0, $iHeight - $fH, substr($sTxt, 0, 1), $cBlack);
        $oGd->string(GD::Font->Small, $fW +  8, $iHeight - $fH, substr($sTxt, 1, 6), $cBlack);
        $oGd->string(GD::Font->Small, $fW + 54, $iHeight - $fH, substr($sTxt, 7, 1), $cBlack);
  }
  return $oGd;

  return $oGd;
}
1;
__END__


=head1 NAME

GD::Barcode::UPCE - Create UPC-E barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::UPCE;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::UPCE->new('123456')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::UPCE->new('123456789');
  die $GD::Barcode::UPCE::errStr unless($oGdBar);       #Invalid Length

=head1 DESCRIPTION

GD::Barcode::UPCE is a subclass of GD::Barcode and allows you to
create UPC-E barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$oGdBar> = GD::Barcode::UPCE->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::UPCE object for I<$sTxt>.
I<$sTxt> has 6 or 7 or 8 numeric characters([0-9]).
If I<$sTxt> has 6 characters, this module adds '0' at the front of I<$sTxt>.
and calculates CD for you.
If I<$sTxt> has 7 characters, this module calaculates CD for you.

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::UPCE->new('123456');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1', 'G' and '0'. 
'1' means black, 'G' also means black but little bit long, 
'0' means white.

 ex.
  my $oGdB = GD::Barcode::UPCE->new('123456');
  my $sPtn = $oGdB->barcode();
  # $sPtn = '';

=head2 $errStr

$GD::Barcode::UPCE::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::UPCE module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
