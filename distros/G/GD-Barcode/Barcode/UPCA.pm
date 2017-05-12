package GD::Barcode::UPCA;
use strict;
BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=1.10;
my $leftOddBar ={
 "0" => "0001101",
 "1" => "0011001",
 "2" => "0010011",
 "3" => "0111101",
 "4" => "0100011",
 "5" => "0110001",
 "6" => "0101111",
 "7" => "0111011",
 "8" => "0110111",
 "9" => "0001011"
};
my $rightBar = {
 "0" => "1110010",
 "1" => "1100110",
 "2" => "1101100",
 "3" => "1000010",
 "4" => "1011100",
 "5" => "1001110",
 "6" => "1010000",
 "7" => "1000100",
 "8" => "1001000",
 "9" => "1110100"
};
my $guardBar = "G0G";
my $centerBar = "0G0G0";
#------------------------------------------------------------------------------
# new (for GD::Barcode::UPCA)
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
# init (for GD::Barcode::UPCA)
#------------------------------------------------------------------------------
sub init($$){
        my($oThis, $sTxt) =@_;
        return 'Invalid characters' if($sTxt =~ /[^0-9]/); 

#Check
    my $iLen = length($sTxt);
        if($iLen == 11) {
        $sTxt .= calcUPCACD( $sTxt );
        }
        elsif($iLen == 12) {
                ;
        }
        else {
                return 'Invalid Length';
        }
        $oThis->{text} = $sTxt;
        return '';
}
#------------------------------------------------------------------------------
# calcUPCACD (for GD::Barcode::UPCA)
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
# new (for GD::Barcode::UPCA)
#------------------------------------------------------------------------------
sub barcode($) {
  my ($oThis) = @_;
  my ($topDigit, $oddEven, $c, $i);
  my ($sRes);

#(1)Init
  my $sTxt = $oThis->{text};
  $sRes = $guardBar;            #GUARD
#(2)Left 6 letters
  my $s1st = GD::Barcode::barPtn( substr($sTxt, 0, 1), $leftOddBar );
  $s1st =~ tr/1/G/;
  $sRes .= $s1st;
  for( $i = 1; $i < 6; $i++ ) {
      $sRes .= GD::Barcode::barPtn( substr($sTxt, $i, 1), $leftOddBar );
  }

#(4)Center
  $sRes .= $centerBar;

#(5)Right
  for( $i = 6; $i < 11; $i++ ) {
      $sRes .= GD::Barcode::barPtn( substr($sTxt, $i, 1), $rightBar );
  }
  my $sLast = GD::Barcode::barPtn( substr($sTxt, 11, 1), $rightBar );
  $sLast =~ tr/1/G/;
  $sRes .= $sLast;

#(6)GUARD
  $sRes .= $guardBar;
  return $sRes;
}
#------------------------------------------------------------------------------
# plot (for GD::Barcode::UPCA)
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
        $oGd->string(GD::Font->Small, $fW + 14, $iHeight - $fH, substr($sTxt, 1, 5), $cBlack);
        $oGd->string(GD::Font->Small, $fW + 53, $iHeight - $fH, substr($sTxt, 6, 5), $cBlack);
        $oGd->string(GD::Font->Small, $fW + 98, $iHeight - $fH, substr($sTxt,11, 1), $cBlack);
  }
  return $oGd;
}
1;
__END__


=head1 NAME

GD::Barcode::UPCA - Create UPC-A barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::UPCA;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::UPCA->new('12345678901')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::UPCA->new('123456789');
  die $GD::Barcode::UPCA::errStr unless($oGdBar);       #Invalid Length


=head1 DESCRIPTION

GD::Barcode::UPCA is a subclass of GD::Barcode and allows you to
create UPC-A barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$oGdBar> = GD::Barcode::UPCA->new(I<$sTxt>);

Constructor. 
Creates a GD::Barcode::UPCA object for I<$sTxt>.
I<$sTxt> has 11 or 12 numeric characters([0-9]).
If I<$sTxt> has 11 characters, this module calacurates CD for you.

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::UPCA->new('12345678901');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1', 'G' and '0'. 
'1' means black, 'G' also means black but little bit long, 
'0' means white.

 ex.
  my $oGdB = GD::Barcode::UPCA->new('12345678901');
  my $sPtn = $oGdB->barcode();
  # $sPtn = '';

=head2 $errStr

$GD::Barcode::UPCA::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.


=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::UPCA module is Copyright (c) 2000 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
