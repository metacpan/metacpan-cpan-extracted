package GD::Barcode::Code39;
use strict;
#use GD;
BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=1.10;
my $code39Bar = {
 '0' => '000110100',
 '1' => '100100001',
 '2' => '001100001',
 '3' => '101100000',
 '4' => '000110001',
 '5' => '100110000',
 '6' => '001110000',
 '7' => '000100101',
 '8' => '100100100',
 '9' => '001100100',
 'A' => '100001001',
 'B' => '001001001',
 'C' => '101001000',
 'D' => '000011001',
 'E' => '100011000',
 'F' => '001011000',
 'G' => '000001101',
 'H' => '100001100',
 'I' => '001001100',
 'J' => '000011100',
 'K' => '100000011',
 'L' => '001000011',
 'M' => '101000010',
 'N' => '000010011',
 'O' => '100010010',
 'P' => '001010010',
 'Q' => '000000111',
 'R' => '100000110',
 'S' => '001000110',
 'T' => '000010110',
 'U' => '110000001',
 'V' => '011000001',
 'W' => '111000000',
 'X' => '010010001',
 'Y' => '110010000',
 'Z' => '011010000',
 '-' => '010000101',
 '*' => '010010100',
 '+' => '010001010',
 '$' => '010101000',
 '%' => '000101010',
 '/' => '010100010',
 '.' => '110000100',
 ' ' => '011000100'
};
#------------------------------------------------------------------------------
# new (for GD::Barcode::Code39)
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
# init (for GD::Barcode::Code39)
#------------------------------------------------------------------------------
sub init($$){
        my($oThis, $sTxt) =@_;
#Check
    return 'Invalid Characters' if($sTxt =~ /[^0-9A-Z\-*+\$%\/. ]/);
        $oThis->{text} = $sTxt;
        return '';
}
#------------------------------------------------------------------------------
# barcode (for GD::Barcode::Code39)
#------------------------------------------------------------------------------
sub barcode($) {
        my($oThis) = @_;
        my($sTxt);
    my($sWk, $sRes);

#       $sTxt = '*'. $oThis->{text} . '*';
        $sTxt = $oThis->{text};
    $sRes = '';
    foreach $sWk (split(//, $sTxt)) {
      $sRes .= GD::Barcode::dumpCode( $code39Bar->{$sWk} .'0' );
    }
    return $sRes;
}
#------------------------------------------------------------------------------
# plot (for GD::Barcode::Code39)
#------------------------------------------------------------------------------
sub plot($;%) {
  my($oThis, %hParam) = @_;

#Barcode Pattern
#  my $sTxtWk = '*' . $oThis->{text} . '*';
  my $sTxtWk = $oThis->{text};
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
        $oGd->string(GD::Font->Small, (length($sPtn)-$fW*(length($sTxtWk)))/2, $iHeight - $fH, 
                        $sTxtWk, $cBlack);
  }
  return $oGd;
}
1;
__END__


=head1 NAME

GD::Barcode::Code39 - Create Code39 barcode image with GD 

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::Code39;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::Code39->new('*CODE39IMG*')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::Code39->new('*123456789;*');
  die $GD::Barcode::Code39::errStr unless($oGdBar);     #Invalid Characters


=head1 DESCRIPTION

GD::Barcode::Code39 is a subclass of GD::Barcode and allows you to
create CODE-39 barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$oGdBar> = GD::Barcode::Code39->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::Code39 object for I<$sTxt>.

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::Code39->new('*12345*');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1' and '0'. 
'1' means black, '0' means white.

 ex.
  my $oGdB = GD::Barcode::Code39->new('*12345*');
  my $sPtn = $oGdB->barcode();
  # $sPtn = '';

=head2 $errStr

$GD::Barcode::Code39::errStr

has error message.

=head2 $text

$oGdBar->{text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::Code39 module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
