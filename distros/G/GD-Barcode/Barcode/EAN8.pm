package GD::Barcode::EAN8;
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
#------------------------------------------------------------------------------
# new (for GD::Barcode::EAN8)
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
# init (for GD::Barcode::EAN8)
#------------------------------------------------------------------------------
sub init($$){
        my($oThis, $sTxt) =@_;
#Check
    return 'Invalid Characters' if($sTxt =~ /[^0-9]/);

#CalcCd
        if( length($sTxt) == 7 ) {
                $sTxt .= calcEAN8CD( $sTxt ) ;
        }
        elsif(length($sTxt) == 8) {
                ;
        }
        else {
                return 'Invalid Length';
        }
        $oThis->{text} = $sTxt;
        return '';
}
#------------------------------------------------------------------------------
# calcEAN8CD (for GD::Barcode::EAN8)
#------------------------------------------------------------------------------
sub calcEAN8CD($) {
  my( $sTxt ) = @_;
  my( $i, $iSum);

  my @aWeight = (3, 1, 3, 1, 3, 1, 3);
  $iSum = 0;
  for( $i = 0; $i < 7; $i++ ){
      $iSum += substr($sTxt, $i, 1)  * $aWeight[$i];
  }
  $iSum %= 10;
  $iSum = ($iSum == 0)? 0: (10 - $iSum);
  return "$iSum";
}
#------------------------------------------------------------------------------
# new (for GD::Barcode::EAN8)
#------------------------------------------------------------------------------
sub barcode($) {
    my ($oThis) = @_;
    my($i, $sRes);
#(1) Init
  my $sTxt = $oThis->{text};
  $sRes = $guardBar;            #GUARD

#(2) Left 4
  for( $i = 0; $i < 4; $i++ ) {
      $sRes .= GD::Barcode::barPtn( substr($sTxt, $i, 1), $leftOddBar );
  }

#(3) Center
  $sRes .= $centerBar;

#(4) Right 4 bytes
  for( $i = 4; $i < 8; $i++ ) {
    $sRes .= GD::Barcode::barPtn( substr($sTxt, $i, 1), $rightBar );
  }
#(5)GUARD
  $sRes .= $guardBar;
  return $sRes;
}
#------------------------------------------------------------------------------
# plot (for GD::Barcode::EAN8)
#------------------------------------------------------------------------------
sub plot($;%) {
  my($oThis, %hParam) =@_;

  my $sPtn = $oThis->barcode();

#Create Image
  my $iHeight = ($hParam{Height})? $hParam{Height} : 50;
  my($oGd, $cBlack);
  if($hParam{NoText}) {
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, length($sPtn), $iHeight, 0, 0);
  }
  else {
        my($fW,$fH) = (GD::Font->Small->width,GD::Font->Small->height);
        my $iWidth = length($sPtn);
#$      ($oGd, $cBlack) = GD::Barcode::plot($sPtn, $iWidth, $iHeight, $fH, $fW+1);
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, $iWidth, $iHeight, $fH, 0);
        $oGd->string(GD::Font->Small, $fW +  1, $iHeight - $fH, substr($oThis->{text}, 0, 4), $cBlack);
        $oGd->string(GD::Font->Small, $fW + 33, $iHeight - $fH, substr($oThis->{text}, 4, 4), $cBlack);
  }
  return $oGd;
}
1;
__END__



=head1 NAME

GD::Barcode::EAN8 - Create EAN8(JAN8) barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::EAN8;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::EAN8->new('1234567')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::EAN8->new('123456789');
  die $GD::Barcode::EAN8::errStr unless($oGdBar);       #Invalid Length


=head1 DESCRIPTION

GD::Barcode::EAN8 is a subclass of GD::Barcode and allows you to
create EAN8(JAN8) barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$oGdBar> = GD::Barcode::EAN8->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::EAN8 object for I<$sTxt>.
I<$sTxt> has 7 or 8 numeric characters([0-9]).
If I<$sTxt> has 12 characters, this module calacurates CD for you.

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::EAN8->new('1234567');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1', 'G' and '0'. 
'1' means black, 'G' also means black but little bit long, 
'0' means white.

 ex.
  my $oGdB = GD::Barcode::EAN8->new('1234567');
  my $sPtn = $oGdB->barcode();
  # $sPtn = '';

=head2 $errStr

$GD::Barcode::EAN8::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::EAN8 module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
