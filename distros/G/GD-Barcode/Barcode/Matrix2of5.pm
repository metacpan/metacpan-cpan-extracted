package GD::Barcode::Matrix2of5;
use strict;
BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=0.01;
#------------------------------------------------------------------------------
# new (for GD::Barcode::Matrix2of5)
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
# init (for GD::Barcode::Matrix2of5)
#------------------------------------------------------------------------------
sub init($$){
        my($oThis, $sTxt) =@_;
#Check
    return 'Invalid Characters' if($sTxt =~ /[^0-9]/);

        $oThis->{text} = $sTxt;
        return '';
}
#------------------------------------------------------------------------------
# new (for GD::Barcode::Matrix2of5)
#------------------------------------------------------------------------------
sub barcodeWk($) {
    my($sPtn) =@_;
    my $sRes = '';
    my $sClr = '1';
    for(my $i=0; $i< length($sPtn); $i++) {
      $sRes .= (substr($sPtn, $i, 1) eq '1')? $sClr x 3 : $sClr;
      $sClr = ($sClr eq '1')? '0': '1';
    }
        return $sRes;
}
sub barcode($) {
    my ($oThis) = @_;
    my $i;
    my $sRes;
    my $sTxt = $oThis->{text};
    my $rhPtn ={
        'START' => '10000',
        '0'     => '00110',
        '1'     => '10001',
        '2'     => '01001',
        '3'     => '11000',
        '4'     => '00101',
        '5'     => '10100',
        '6'     => '01100',
        '7'     => '00011',
        '8'     => '10010',
        '9'     => '01010',
        'STOP'  => '10000',
    };
  $sRes = barcodeWk($rhPtn->{START});
  for( $i = 0; $i < length($sTxt); $i++ ){
                $sRes .= '0'; #GAP
                $sRes .= barcodeWk($rhPtn->{substr($sTxt, $i, 1)});
  }
  $sRes .= '0'; #GAP
  $sRes .= barcodeWk($rhPtn->{STOP});
  return $sRes;
}

#------------------------------------------------------------------------------
# plot (for GD::Barcode::Matrix2of5)
#------------------------------------------------------------------------------
sub plot($;%) {
  my($oThis, %hParam) =@_;

  my $sTxtWk = $oThis->{text};
  my $sPtn = $oThis->barcode();

#Create Image
  my $iHeight = ($hParam{Height})? $hParam{Height} : 50;
  my($oGd, $cBlack);
  if($hParam{NoText}) {
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, length($sPtn), $iHeight, 0, 0);
  }
  else {
        my($fW,$fH) = (GD::Font->Small->width, GD::Font->Small->height);
        my $iWidth = length($sPtn);
        #Bar Image
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, $iWidth, $iHeight, $fH, 0);

        #String
        $oGd->string(GD::Font->Small, (length($sPtn)-$fW*(length($sTxtWk)))/2, $iHeight - $fH, 
                        $sTxtWk, $cBlack);
  }
  return $oGd;
}
1;
__END__



=head1 NAME

GD::Barcode::Matrix2of5 - Create Matrix2of5 barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::Matrix2of5;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::Matrix2of5->new('1234567890')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::Matrix2of5->new('A12345678');
  die $GD::Barcode::Matrix2of5::errStr unless($oGdBar); #Invalid Characters
  $oGdBar->plot->png;


=head1 DESCRIPTION

GD::Barcode::Matrix2of5 is a subclass of GD::Barcode and allows you to
create Matrix2of5 barcode image with GD.

=head2 new

I<$oGdBar> = GD::Barcode::Matrix2of5->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::Matrix2of5 object for I<$sTxt>.
I<$sTxt> has numeric characters([0-9]).

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::Matrix2of5->new('12345678');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1' and '0'. 
'1' means black, '0' means white.

 ex.
  my $oGdB = GD::Barcode::Matrix2of5->new('12345678');
  my $sPtn = $oGdB->barcode();

=head2 $errStr

$GD::Barcode::Matrix2of5::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::Matrix2of5 module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
