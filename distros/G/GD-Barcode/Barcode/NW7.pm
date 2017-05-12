package GD::Barcode::NW7;
use strict;
BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=1.10;
my $nw7Bar = {
 '0' => '0000011',
 '1' => '0000110',
 '2' => '0001001',
 '3' => '1100000',
 '4' => '0010010',
 '5' => '1000010',
 '6' => '0100001',
 '7' => '0100100',
 '8' => '0110000',
 '9' => '1001000',
 '-' => '0001100',
 '$' => '0011000',
 ':' => '1000101',
 '/' => '1010001',
 '.' => '1010100',
 '+' => '0010101',
 'A' => '0011010',
 'B' => '0101001',
 'C' => '0001011',
 'D' => '0001110'
};
#------------------------------------------------------------------------------
# new (for GD::Barcode::NW7)
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
# init (for GD::Barcode::NW7)
#------------------------------------------------------------------------------
sub init($$\%){
        my($oThis, $sTxt) =@_;
#Check
    return 'Invalid Characters' if($sTxt =~ /[^0-9\-\$:\/.+ABCD]/);

#CalcCd
        $oThis->{text} = $sTxt;
        return '';
}
#------------------------------------------------------------------------------
# barcode (for GD::Barcode::NW7)
#------------------------------------------------------------------------------
sub barcode($) {
        my($oThis) = @_;
    my($sWk, $sRes);

        my $sTxt = $oThis->{text};
    $sRes = '';
    foreach $sWk (split(//, $sTxt)) {
      $sRes .= GD::Barcode::dumpCode( $nw7Bar->{$sWk} .'0' );
    }
    return $sRes;
}
#------------------------------------------------------------------------------
# plot (for GD::Barcode::NW7)
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
        my $iWidth = length($sPtn);
        #Bar Image
        ($oGd, $cBlack) = GD::Barcode::plot($sPtn, $iWidth, $iHeight, $fH, 0);

        #String
        $oGd->string(GD::Font->Small, (length($sPtn)-$fW*(length($sTxt)))/2, $iHeight - $fH, 
                                                $sTxt, $cBlack);
  }
  return $oGd;
}
1;
__END__



=head1 NAME

GD::Barcode::NW7 - Create NW7 barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::NW7;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::NW7->new('123456789012')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::NW7->new('123456789E');
  die $GD::Barcode::NW7::errStr unless($oGdBar);        #Invalid Characters

=head1 DESCRIPTION

GD::Barcode::NW7 is a subclass of GD::Barcode and allows you to
create NW7 barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$oGdBar> = GD::Barcode::NW7->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::NW7 object for I<$sTxt>.
I<$sTxt> has variable length string with (0-9, - $ / . + ABCD).

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::NW7->new('123456789012');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1' and '0'. 
'1' means black, '0' means white.

 ex.
  my $oGdB = GD::Barcode::NW7->new('123456789012');
  my $sPtn = $oGdB->barcode();
  # $sPtn = '';

=head2 $errStr

$GD::Barcode::NW7::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::NW7 module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
