package GD::Barcode::EAN13;
use strict;
BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=1.10;
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
my $rightBar = {
 '0' => '1110010',
 '1' => '1100110',
 '2' => '1101100',
 '3' => '1000010',
 '4' => '1011100',
 '5' => '1001110',
 '6' => '1010000',
 '7' => '1000100',
 '8' => '1001000',
 '9' => '1110100'
};
my $guardBar = 'G0G';
my $centerBar = '0G0G0';
my $oddEven4EAN = {
 0 => 'OOOOOO',
 1 => 'OOEOEE',
 2 => 'OOEEOE',
 3 => 'OOEEEO',
 4 => 'OEOOEE',
 5 => 'OEEOOE',
 6 => 'OEEEOO',
 7 => 'OEOEOE',
 8 => 'OEOEEO',
 9 => 'OEEOEO'
};
#------------------------------------------------------------------------------
# new (for GD::Barcode::EAN13)
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
# init (for GD::Barcode::EAN13)
#------------------------------------------------------------------------------
sub init($$){
        my($oThis, $sTxt) =@_;
#Check
    return 'Invalid Characters' if($sTxt =~ /[^0-9]/);
#CalcCd
        if( length($sTxt) == 12 ) {
                $sTxt .= calcEAN13CD( $sTxt ) ;
        }
        elsif(length($sTxt) == 13) {
                ;
        }
        else {
                return 'Invalid Length';
        }
        $oThis->{text} = $sTxt;
        return '';
}
#==================================================================
# Check digit for EAN13
#==================================================================
sub calcEAN13CD($) {
  my( $sTxt ) =@_;
  my( $i, $iSum);
  my @aWeight = (1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1, 3);
  $iSum = 0;
  for( $i = 0; $i < 12; $i++ ){
      $iSum += substr($sTxt, $i, 1)  * $aWeight[$i];
  }
  $iSum %= 10;
  $iSum = ($iSum == 0)? 0: (10 - $iSum);
  return "$iSum";
}
#------------------------------------------------------------------------------
# barcode (for GD::Barcode::EAN13)
#------------------------------------------------------------------------------
sub barcode($) {
  my ($oThis) = @_;
  my ($sTxt);
  my ($oddEven, $i, $sBar);
  my ($sRes);

#(1)Init
  $sTxt = $oThis->{text};
  $sRes = $guardBar;            #GUARD

#(2)Left 7 letters
  $oddEven = $oddEven4EAN->{substr($sTxt, 0, 1)};
  for( $i = 1; $i < 7; $i++ ) {
          $sBar = ( substr($oddEven, $i-1, 1) eq 'O')?
                        $leftOddBar : $leftEvenBar;
          $sRes .= GD::Barcode::barPtn(
                                substr($sTxt, $i, 1), $sBar);
  }
#(4)Center
  $sRes .= $centerBar;

#(5)Right
    for( $i = 7; $i < 13; $i++ ) {
          $sRes .= GD::Barcode::barPtn( substr($sTxt, $i, 1), $rightBar );
    }
#(6)GUARD
  $sRes .= $guardBar;
  return $sRes;
}
#------------------------------------------------------------------------------
# plot (for GD::Barcode::EAN13)
#------------------------------------------------------------------------------
sub plot($;%) {
  my($oThis, %hParam) = @_;

#Barcode Pattern
  my $sPtn = $oThis->barcode();

#Create Image
  my $iHeight = ($hParam{Height})? $hParam{Height} : 50;
  my($oGd, $cBlack);
  if($hParam{NoText}) {
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, length($sPtn), $iHeight, 0, 0);
  }
  else {
        my($fW,$fH) = (GD::Font->Small->width,GD::Font->Small->height);
        my $iWidth = length($sPtn)+$fW+1;
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, $iWidth, $iHeight, $fH, $fW+1);
        $oGd->string(GD::Font->Small,       0, $iHeight - $fH, substr($oThis->{text}, 0, 1), $cBlack);
        $oGd->string(GD::Font->Small, $fW +8 , $iHeight - $fH, substr($oThis->{text}, 1, 6), $cBlack);
        $oGd->string(GD::Font->Small, $fW +55, $iHeight - $fH, substr($oThis->{text}, 7, 6), $cBlack);
  }
  return $oGd;
}
1;
__END__


=head1 NAME

GD::Barcode::EAN13 - Create EAN13(JAN13) barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::EAN13;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::EAN13->new('123456789012')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::EAN13->new('123456789');
  die $GD::Barcode::EAN13::errStr unless($oGdBar);      #Invalid Length


=head1 DESCRIPTION

GD::Barcode::EAN13 is a subclass of GD::Barcode and allows you to
create EAN13(JAN13) barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$oGdBar> = GD::Barcode::EAN13->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::EAN13 object for I<$sTxt>.
I<$sTxt> has 12 or 13 numeric characters([0-9]).
If I<$sTxt> has 12 characters, this module calacurates CD for you.

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::EAN13->new('123456789012');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1', 'G' and '0'. 
'1' means black, 'G' also means black but little bit long, 
'0' means white.

 ex.
  my $oGdB = GD::Barcode::EAN13->new('123456789012');
  my $sPtn = $oGdB->barcode();
  # $sPtn = '';

=head2 $errStr

$GD::Barcode::EAN13::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::EAN13 module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
