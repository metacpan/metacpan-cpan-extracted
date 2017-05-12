# GD::Barcode::QRcode 1.20 Edited (^^;;; by Hippo2000
#    based on QRcode image CGI    version 0.50   (C)2000-2002,Y.Swetake
use strict;
package GD::Barcode::QRcode;

BEGIN{eval {require 'GD.pm';};};
require Exporter;
use vars qw($VERSION @ISA $errStr);
@ISA = qw(GD::Barcode Exporter);
$VERSION=0.01;
#Prototype
sub _calcVersion($$$);
sub _calcMask($$$);
sub _cnv8bit($$$$);
sub _cnvAlphaNumeric($$$$);
sub _cnvNumeric($$$$);
sub _calcFrm($$$);

#------------------------------------------------------------------------------
# new (for GD::Barcode::QR)
#------------------------------------------------------------------------------
sub new($$;$) {
  my($sClass, $sTxt, $rhPrm) = @_;
  $errStr ='';
  my $oSelf = {};
  bless $oSelf;
  return undef if($errStr = $oSelf->init($sTxt, $rhPrm));
  return $oSelf;
}
#------------------------------------------------------------------------------
# init (for GD::Barcode::QR)
#------------------------------------------------------------------------------
sub init($$$){
    my($oSelf, $sTxt, $rhPrm) =@_;

#CalcCd
    $oSelf->{text} = $sTxt;
    $oSelf->{Ecc} = $rhPrm->{Ecc} || ' ';
    $oSelf->{Ecc} =~ tr/LMHQ/M/c;    #Not /LMQH/ => M
    $oSelf->{Version} = $rhPrm->{Version} || 1;
    $oSelf->{ModuleSize} = $rhPrm->{ModuleSize} || 1;
    $oSelf->{ModuleSize} = int($oSelf->{ModuleSize});

    my $iDatCnt = 0;
    my @aDatVal;
    my @aDatBit;
    my $raPlusWords;
    my $iWordsPos;
    $aDatBit[$iDatCnt]=4;
    # Determin Data Type(8Bit, AlphaNumeric, Numeric .. not supported Kanji-Mode)
    if ($oSelf->{text} =~ /\D/) {
        if ($oSelf->{text} =~ /[^0-9A-Z \$\*\%\+\-\.\/\:]/) {
         # --- 8bit byte mode
            ($iDatCnt, $raPlusWords) =
                $oSelf->_cnv8bit($iDatCnt, \@aDatVal, \@aDatBit,);
        }
        else {
         # ---- alphanumeric mode
            ($iDatCnt, $raPlusWords) =
                $oSelf->_cnvAlphaNumeric($iDatCnt, \@aDatVal, \@aDatBit);
        }
    }
    else {
     # ---- numeric mode
        ($iDatCnt, $raPlusWords) =
            $oSelf->_cnvNumeric($iDatCnt, \@aDatVal, \@aDatBit);
    }
    my $iTotalBits = 0;
    for(my $i=0;$i<$iDatCnt;++$i){
        $iTotalBits += $aDatBit[$i];
    }

    # Calc version(=Size)
    my ($iMaxDatBits, $iCdNumPlus, $iMaxCodeWords, $iRemainBits);
    ($iMaxDatBits, $iCdNumPlus, $iMaxCodeWords, $iRemainBits) = 
        $oSelf->_calcVersion($iTotalBits, $raPlusWords);
    $iTotalBits += $iCdNumPlus;

    $aDatBit[$oSelf->{WordsPos}] += $iCdNumPlus;
    $oSelf->{MaxModules}  = 17 + ($oSelf->{Version} * 4);
    my $iBitCnt = ($iMaxCodeWords * 8) + $iRemainBits;
    my $iMaxDatWords=($iMaxDatBits / 8);

    # ---- read version ECC data file.
    my ($sMatX, $sMatY, $sMasks, $sFmtInfX2, $sFmtInfY2, $sRsEccCodeWord, $sRso);
    my $sRec = do ('GD/Barcode/QRcode/qrv' . 
                    sprintf('%02d', $oSelf->{Version}) . $oSelf->{Ecc} . '.dat');

    ($sMatX, $sMatY, $sMasks, $sFmtInfX2, $sFmtInfY2, $sRsEccCodeWord, $sRso) = 
        unpack(("a$iBitCnt" x 3) . ('a15' x 2) . 'a1a128', pack('H*', $sRec));

    my $iRsEccWords = ord($sRsEccCodeWord);
    my @aMatrixX    = unpack("C*", $sMatX);
    my @aMatrixY    = unpack("C*", $sMatY);
    my @aMask       = unpack("C*", $sMasks);
    my @aRsBlockOrder  = unpack("C*", $sRso);
    my @aFmtInfX2      = unpack("C*", $sFmtInfX2);
    my @aFmtInfY2      = unpack("C*", $sFmtInfY2);

    $sRec = do ('GD/Barcode/QRcode/rsc' . sprintf('%02d', $iRsEccWords) . '.dat');
    my @aRsCalTbl = unpack("a$iRsEccWords" x 256, pack('H*', $sRec));

    # ----  set teminator 
    if ($iTotalBits <= ($iMaxDatBits-4)){
        $aDatVal[$iDatCnt] = 0;
        $aDatBit[$iDatCnt] = 4;
    } 
    elsif ($iTotalBits < $iMaxDatBits){
        $aDatVal[$iDatCnt] = 0;
        $aDatBit[$iDatCnt] = $iMaxDatBits-$iTotalBits;
    }
    elsif ($iTotalBits > $iMaxDatBits){
        die "Overflow error. version $oSelf->{Version}\n" . 
            "total bits: $iTotalBits  max bits: $iMaxDatBits\n";
    }
    # 8ビット単位に分割
    my $iCodeWords=0;
    my @aCodeWords;
    $aCodeWords[0]=0;
    my $iRestBits = 8;
    for(my $i=0;$i <= $iDatCnt; ++$i) {
        my $sBuff    = $aDatVal[$i];
        my $iBuffBit = $aDatBit[$i];

        my $iFlg=1;
        while ($iFlg) {
            if ($iRestBits > $iBuffBit) {
                $aCodeWords[$iCodeWords]=(($aCodeWords[$iCodeWords] << $iBuffBit) | $sBuff);
                $iRestBits -= $iBuffBit;
                $iFlg=0;
            }
            else {
                $iBuffBit -= $iRestBits;
                $aCodeWords[$iCodeWords]=(($aCodeWords[$iCodeWords] << $iRestBits) | ($sBuff >> $iBuffBit));
                if ($iBuffBit==0) {
                    $iFlg=0;
                }
                else {
                    $sBuff= ($sBuff & ((1 << $iBuffBit) -1 ));
                    $iFlg=1;   
                } 
                $iCodeWords++;
                if ($iCodeWords<$iMaxDatWords-1){
                    $aCodeWords[$iCodeWords]=0;
                }
                $iRestBits = 8;
            }
        }
    }
    if ($iRestBits != 8) {
        $aCodeWords[$iCodeWords] <<= $iRestBits;
    }
    else {
        --$iCodeWords;
    }
    # Padding data
    if ($iCodeWords < $iMaxDatWords - 1 ){
        my $iFlg=1;
        while ($iCodeWords < ($iMaxDatWords-1)){
            $aCodeWords[++$iCodeWords] = ($iFlg==1)? 0xEC : 0x11;
            $iFlg *= -1;
        }
    }

    # ----  RS-ECC prepare
    my $iRsBlock=0;
    my @aRsTmp=();
    my $j=0;
    # Divide RS-Blocks
    for(my $i = 0; $i < $iMaxDatWords; ++$i) {
        $aRsTmp[$iRsBlock] .= chr($aCodeWords[$i]);
        if (++$j >= $aRsBlockOrder[$iRsBlock]-$iRsEccWords){
            $j=0;
            ++$iRsBlock;
        }
    }
    # RS-ECC main
    for($iRsBlock=0; $iRsBlock <= scalar(@aRsBlockOrder); $iRsBlock++) {
        my $sRsCodeWords = $aRsBlockOrder[$iRsBlock];
        $sRsCodeWords ||= 0;
        $sRsCodeWords =~ s/\n//g;
        my $sRsTmp = ($aRsTmp[$iRsBlock] || ''). (chr(0) x $iRsEccWords);

        for($j = ($sRsCodeWords - $iRsEccWords); $j>0; $j--) {
            my $iFirst = ord(substr($sRsTmp, 0, 1));
            if ($iFirst != 0){
                $sRsTmp = substr($sRsTmp, 1) ^ $aRsCalTbl[$iFirst];
            }
            else {
                $sRsTmp = substr($sRsTmp, 1);
            }
        }
        push(@aCodeWords, unpack("C*", $sRsTmp));
    }
    # ---- put data
    # ---- flash matrix
    my @aCont;
    $oSelf->{Cont} = \@aCont;
    for(my $i=0;$i<$oSelf->{MaxModules};$i++) {
        $aCont[$i] = [ (0) x $oSelf->{MaxModules}];
    }
    for(my $i=0; $i<$iMaxCodeWords; $i++) {
        my $iCodeWord = $aCodeWords[$i];
        for(my $j = 7; $j >= 0; $j--) {
            my $iCodeWordBitNum = ($i * 8)+$j;
            $aCont[$aMatrixX[$iCodeWordBitNum] ][ $aMatrixY[$iCodeWordBitNum]]
                = ((255*($iCodeWord & 1)) ^ $aMask[$iCodeWordBitNum]); 
            $iCodeWord >>= 1;
        }
    }
    for(my $iMatrixRemain = $iRemainBits; $iMatrixRemain; $iMatrixRemain--) {
        my $iRemainBitTmp = $iMatrixRemain + ($iMaxCodeWords * 8);
        $aCont[$aMatrixX[$iRemainBitTmp]][$aMatrixY[$iRemainBitTmp]]  
            = (255 ^ $aMask[$iRemainBitTmp] );
    }

    # ---- mask select
    my $sHorMst='';
    my $sVerMst='';
    for(my $i=0; $i < $oSelf->{MaxModules}; ++$i) {
        for($j=0 ; $j < $oSelf->{MaxModules}; ++$j){
            $sHorMst .= chr($aCont[$j][$i]);
            $sVerMst .= chr($aCont[$i][$j]);
       }
    }
    my $iMask = $oSelf->_calcMask($sHorMst, $sVerMst);
    $oSelf->{MaskCont} = (1 << $iMask);

    # ---- format information
    my %hFmtInf =(
        'M' => [
          '101010000010010', '101000100100101', '101111001111100', '101101101001011',
          '100010111111001', '100000011001110', '100111110010111', '100101010100000',],
        'L' => [
          '111011111000100', '111001011110011', '111110110101010', '111100010011101',
          '110011000101111', '110001100011000', '110110001000001', '110100101110110',],
        'H' =>[
          '001011010001001', '001001110111110', '001110011100111', '001100111010000',
          '000011101100010', '000001001010101', '000110100001100', '000100000111011',],
        'Q' => [
          '011010101011111', '011000001101000', '011111100110001', '011101000000110',
          '010010010110100', '010000110000011', '010111011011010', '010101111101101',],
    );
    my @aFmtInfX1=( 0, 1, 2, 3, 4, 5, 7, 8, 8, 8, 8, 8, 8, 8, 8);
    my @aFmtInfY1=( 8, 8, 8, 8, 8, 8, 8, 8, 7, 5, 4, 3, 2, 1, 0);
    my @aContWk = split //, $hFmtInf{$oSelf->{Ecc}}->[$iMask];
    for(my $i = 0; $i < 15; ++$i) {
        $aCont[$aFmtInfX1[$i]][$aFmtInfY1[$i]] = $aContWk[$i] * 255;
        $aCont[$aFmtInfX2[$i]][$aFmtInfY2[$i]] = $aContWk[$i] * 255;
    }
    return '';
}
#------------------------------------------------------------------------------
# barcode (for GD::Barcode::QR)
#------------------------------------------------------------------------------
sub barcode($) {
    my ($oSelf) = @_;
    my $sBarL;
    my $iModSize = $oSelf->{ModuleSize};
    my $sBlack = '1' x $iModSize;
    my $sWhite = '0' x $iModSize;

    my $sPtn = '';
    $sPtn = (($sWhite x ($oSelf->{MaxModules} + 8)) . "\n") x (4 * $iModSize);
    my @aCont = @{$oSelf->{Cont}};

    for(my $iY=0; $iY < $oSelf->{MaxModules}; ++$iY) {
        $sBarL = $sWhite x 4;
        for(my $iX=0; $iX < $oSelf->{MaxModules}; ++$iX) {
            $sBarL .= ((_calcFrm($oSelf->{Version}, $iY, $iX)) || 
                     (($aCont[$iX][$iY] & $oSelf->{MaskCont})))? $sBlack : $sWhite;
        }
        $sBarL .= ($sWhite x 4) . "\n";
        $sPtn  .= $sBarL x $iModSize;
    }
    $sPtn .= ($sWhite x ($oSelf->{MaxModules}+8) . "\n") x (4 * $iModSize);
    return $sPtn;
}
#------------------------------------------------------------------------------
# plot (for GD::Barcode::QRcode)
#------------------------------------------------------------------------------
sub plot($;%) {
    my($oSelf, %hParam) =@_;
    my $iUnitSize = $oSelf->{ModuleSize};
    my $oOutImg = GD::Image->new(
            ($oSelf->{MaxModules} + 8) * $iUnitSize, 
            ($oSelf->{MaxModules} + 8) * $iUnitSize);
    my $cWhite = $oOutImg->colorAllocate(255, 255,255); #For BackColor
    my $cBlack = $oOutImg->colorAllocate(  0,   0,  0);
    my @aCont = @{$oSelf->{Cont}};
    for(my $iY=0; $iY < $oSelf->{MaxModules}; ++$iY){
        for(my $iX=0; $iX < $oSelf->{MaxModules}; ++$iX){
            if((_calcFrm($oSelf->{Version}, $iY, $iX)) || (($aCont[$iX][$iY] & $oSelf->{MaskCont}))) {
                if($oSelf->{ModuleSize} <= 1) {
                    $oOutImg->setPixel($iX+4, $iY+4, $cBlack)
                }
                else {
                    $oOutImg->filledRectangle(
                            ($iX+4)*$iUnitSize, ($iY+4)*$iUnitSize,
                            ($iX+4+1)*$oSelf->{ModuleSize} - 1,
                            ($iY+4+1)*$oSelf->{ModuleSize} - 1,
                            $cBlack);
                }
            }
        }
    }
    return $oOutImg;
}

sub _calcVersion($$$) {
    my ($oSelf, $iTtlBits, $raPlusWords) = @_;

    my %hMaxDatBits= (
        'M' =>[ 0,
          128,   224,   352,   512,   688,   864,   992,  1232,  1456,  1728,
         2032,  2320,  2672,  2920,  3320,  3624,  4056,  4504,  5016,  5352,
         5712,  6256,  6880,  7312,  8000,  8496,  9024,  9544, 10136, 10984,
        11640, 12328, 13048, 13800, 14496, 15312, 15936, 16816, 17728, 18672, ],
        'L' =>[ 0,
          152,   272,   440,   640,   864,  1088,  1248,  1552,  1856,  2192,
         2592,  2960,  3424,  3688,  4184,  4712,  5176,  5768,  6360,  6888,
         7456,  8048,  8752,  9392, 10208, 10960, 11744, 12248, 13048, 13880,
        14744, 15640, 16568, 17528, 18448, 19472, 20528, 21616, 22496, 23648, ],
        'H' => [ 0,
           72,   128,   208,   288,   368,   480,   528,   688,   800,   976,
         1120,  1264,  1440,  1576,  1784,  2024,  2264,  2504,  2728,  3080,
         3248,  3536,  3712,  4112,  4304,  4768,  5024,  5288,  5608,  5960,
         6344,  6760,  7208,  7688,  7888,  8432,  8768,  9136,  9776, 10208, ],
        'Q' =>[ 0,
          104,   176,   272,   384,   496,   608,   704,   880,  1056,  1232,
         1440,  1648,  1952,  2088,  2360,  2600,  2936,  3176,  3560,  3880,
         4096,  4544,  4912,  5312,  5744,  6032,  6464,  6968,  7288,  7880,
         8264,  8920,  9368,  9848, 10288, 10832, 11408, 12016, 12656, 13328,],
    );
    my @aMaxCodeWords=(
       0,
      26,   44,   70,  100,  134,  172,  196,  242,  292,  346,
     404,  466,  532,  581,  655,  733,  815,  901,  991, 1085,
    1156, 1258, 1364, 1474, 1588, 1706, 1828, 1921, 2051, 2185,
    2323, 2465, 2611, 2761, 2876, 3034, 3196, 3362, 3532, 3706 );

    my @aRemainBits=(
        0,
        0, 7, 7, 7, 7, 7, 0, 0, 0, 0,
        0, 0, 0, 3, 3, 3, 3, 3, 3, 3,
        4, 4, 4, 4, 4, 4, 4, 3, 3, 3,
        3, 3, 3, 3, 0, 0, 0, 0, 0, 0);

    if (!$oSelf->{Version}){        #--- auto version select
        for($oSelf->{Version}=1; $oSelf->{Version} <= 40; ++$oSelf->{Version}) {
            last if ($hMaxDatBits{$oSelf->{Ecc}}->[$oSelf->{Version}] 
                        >= $iTtlBits + $raPlusWords->[$oSelf->{Version}]);
        }
    }
    return( $hMaxDatBits{$oSelf->{Ecc}}->[$oSelf->{Version}], 
            $raPlusWords->[$oSelf->{Version}], 
            $aMaxCodeWords[$oSelf->{Version}], 
            $aRemainBits[$oSelf->{Version}],
        );
}
sub _calcMask($$$) {
    my($oSelf, $sHorMst, $sVerMst) = @_;
use constant SPCHAR => "\xAA";

    my $iMinDtmScore = 0;
    my $iAllMatrix   = $oSelf->{MaxModules} * $oSelf->{MaxModules};
    my $iMask = 0;
    for(my $i=0; $i < 8; ++$i){
        my $iBit  = 1 << $i;
        my $iBitR = (~$iBit) & 0xFF;

        my $iBitMask = chr($iBit) x $iAllMatrix;
        my $iHor = $sHorMst & $iBitMask;
        my $iVer = $sVerMst & $iBitMask;

        my $iVerAnd = ((SPCHAR x $oSelf->{MaxModules}) . $iVer) & ($iVer . (SPCHAR x $oSelf->{MaxModules}));
        my $iVerOr  = ((SPCHAR x $oSelf->{MaxModules}) . $iVer) | ($iVer . (SPCHAR x $oSelf->{MaxModules}));

        $iHor = ~$iHor;
        $iVer = ~$iVer;
        $iVerAnd = ~$iVerAnd;
        $iVerOr  = ~$iVerOr;

        substr($iVerAnd, $iAllMatrix, 0)  = SPCHAR;
        substr($iVerOr,  $iAllMatrix, 0)  = SPCHAR;
        for(my $k = ($oSelf->{MaxModules} - 1); $k > 0 ; $k--) {
            substr($iHor,    $k * $oSelf->{MaxModules}, 0) = SPCHAR;
            substr($iVer,    $k * $oSelf->{MaxModules}, 0) = SPCHAR;
            substr($iVerAnd, $k * $oSelf->{MaxModules}, 0) = SPCHAR;
            substr($iVerOr,  $k * $oSelf->{MaxModules}, 0) = SPCHAR;
        }

        $iHor .= (SPCHAR . $iVer);
        my $iN1Srch  = (chr(255) x 5) . "+|" . (chr($iBitR) x 5) . "+";
        my $iN2Srch1 = chr($iBitR).chr($iBitR)."+";
        my $iN2Srch2 = chr(255).chr(255)."+";
        my $iN3Srch  = chr($iBitR) . chr(255) . 
                      chr($iBitR) . chr($iBitR) . chr($iBitR) . chr(255) . chr($iBitR);
        my $iN4Srch  = chr($iBitR);

        my $iHorTmp = $iHor;
        my $iDemeritN3 = ( $iHorTmp =~ s/$iN3Srch//g ) * 40;
        my $iDemeritN4 = int(abs(((100* ( ($iVer=~s/$iN4Srch//g)/($iAllMatrix)))-50)/5))*10;

        my $iMatchBeforeNum = length($iVerAnd) + length($iVerOr);
        my $iMatchNum    = ($iVerAnd =~ s/$iN2Srch1//g ) + ($iVerOr =~ s/$iN2Srch2//g );
        my $iMatchAftNum =length($iVerAnd)+length($iVerOr);
        my $iDemeritN2=($iMatchBeforeNum-$iMatchAftNum-$iMatchNum)*3;

        my $iMatchBfrNum = length($iHor);
        $iMatchNum    = ( $iHor =~ s/$iN1Srch//g );
        $iMatchAftNum = length($iHor);
        my $iDemeritN1   = $iMatchBfrNum - $iMatchAftNum - ($iMatchNum * 2);

        my $iDemeritScore = $iDemeritN1 + $iDemeritN2 + $iDemeritN3 + $iDemeritN4;

        if ($iDemeritScore <= $iMinDtmScore || $i==0){
            $iMask  = $i;
            $iMinDtmScore = $iDemeritScore;
        }
    }
    return $iMask;
}
sub _cnv8bit($$$$) {
    my($oSelf, $iDatCnt, $raDatVal, $raDatBit) = @_;

    my $iDatLen = length($oSelf->{text});
    $raDatVal->[$iDatCnt]=4;   # 8bit byte mode
    ++$iDatCnt;
    $raDatBit->[$iDatCnt]=8;   # version 1-9
    $raDatVal->[$iDatCnt] =$iDatLen;
    $oSelf->{WordsPos}   =$iDatCnt;

    $iDatCnt++;
    for(my $i=0; $i < $iDatLen; ++$i) {
        $raDatVal->[$iDatCnt] = ord(substr($oSelf->{text},$i,1));
        $raDatBit->[$iDatCnt] = 8;
        $iDatCnt++;
    }
    return (
        $iDatCnt,
        [
            0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        ]);
}
sub _cnvAlphaNumeric($$$$) {
    my($oSelf, $iDatCnt, $raDatVal, $raDatBit) = @_;

    my $iDatLen = length($oSelf->{text});
    $raDatVal->[$iDatCnt]=2;            # alpha numeric mode
    $iDatCnt++;
    $raDatVal->[$iDatCnt] = $iDatLen;
    $raDatBit->[$iDatCnt] = 9;            #version 1-9
    $oSelf->{WordsPos}   = $iDatCnt;
    my %hAlphanumeric=(
            '0'=> 0, '1'=> 1, '2'=> 2, '3'=> 3, '4'=> 4,
            '5'=> 5, '6'=> 6, '7'=> 7, '8'=> 8, '9'=> 9,
            'A'=>10, 'B'=>11, 'C'=>12, 'D'=>13, 'E'=>14,
            'F'=>15, 'G'=>16, 'H'=>17, 'I'=>18, 'J'=>19,
            'K'=>20, 'L'=>21, 'M'=>22, 'N'=>23, 'O'=>24,
            'P'=>25, 'Q'=>26, 'R'=>27, 'S'=>28, 'T'=>29,
            'U'=>30, 'V'=>31, 'W'=>32, 'X'=>33, 'Y'=>34,
            'Z'=>35, ' '=>36, '$'=>37, '%'=>38, '*'=>39,
            '+'=>40, '-'=>41, '.'=>42, '/'=>43, ':'=>44);
    $iDatCnt++;
    for(my $i=0 ; $i < $iDatLen; ++$i){
        if (($i % 2)==0){
            $raDatVal->[$iDatCnt] = $hAlphanumeric{substr($oSelf->{text},$i,1)};
            $raDatBit->[$iDatCnt] = 6;
        }
        else {
            $raDatVal->[$iDatCnt] = $raDatVal->[$iDatCnt] * 45 +
                                     $hAlphanumeric{substr($oSelf->{text}, $i, 1)};
            $raDatBit->[$iDatCnt] = 11;
            $iDatCnt++;
        }
    }
    ++$iDatCnt if(($raDatBit->[$iDatCnt] || 0) > 0);
    return (
        $iDatCnt, 
        [   0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 4, 4, 4, 4,
            4, 4, 4, 4, 4, 4, 4, 4, 4, 4, ]
    );
}
sub _cnvNumeric($$$$) {
    my($oSelf, $iDatCnt, $raDatVal, $raDatBit) = @_;

    my $iDatLen = length($oSelf->{text});
    $raDatVal->[$iDatCnt] = 1;              # numeric mode
    $iDatCnt++;
    $raDatVal->[$iDatCnt] = $iDatLen;   # length
    $raDatBit->[$iDatCnt] = 10;             # version 1-9
    $oSelf->{WordsPos} = $iDatCnt;

    $iDatCnt++;
    for(my $i=0;$i < $iDatLen; ++$i){
        if (($i % 3)==0){
            $raDatVal->[$iDatCnt] = substr($oSelf->{text},$i,1);
            $raDatBit->[$iDatCnt] = 4;
        }
        else {
            $raDatVal->[$iDatCnt] = $raDatVal->[$iDatCnt] * 10 + 
                                    substr($oSelf->{text},$i,1);
            if (($i % 3)==1){
                $raDatBit->[$iDatCnt] = 7;
            }
            else {
                $raDatBit->[$iDatCnt] =10;
                $iDatCnt++;
            }
        }
    }
    ++$iDatCnt if(defined($raDatBit->[$iDatCnt]) && ($raDatBit->[$iDatCnt] > 0));
    return (
        $iDatCnt,
        [ 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
          2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
          2, 2, 2, 2, 2, 2, 4, 4, 4, 4,
          4, 4, 4, 4, 4, 4, 4, 4, 4, 4]);
}
sub _calcFrm($$$) {
    my($iV, $iR, $iC) = @_;
    my $iPosR = $iV*4+10;
    if($iR==0) {
        return 1 if(
            (($iC >= 0)      and ($iC <= 6)) or 
            (($iC >= $iPosR) and ($iC <= ($iPosR + 6))));
    }
    elsif($iR==6) {
        return 1 if(
            (($iC % 2)==0) or
            (($iC >= 0)      and ($iC <= 6)) or 
            (($iC >= $iPosR) and ($iC <= ($iPosR + 6))));
    }
    elsif(($iR == 1) or ($iR == 5)) {
        return 1 
            if (($iC == 0) or ($iC == 6) or
                ($iC == $iPosR) or ($iC == $iPosR+6));
    }
    elsif(($iR >= 2) and ($iR <= 4)) {
        return 1 
             if(($iC == 0) or 
                (($iC >= 2) and ($iC <= 4))or
                ($iC == 6) or
                ($iC == $iPosR) or 
                (($iC >= ($iPosR+2)) and ($iC <= ($iPosR+4))) or
                ($iC == $iPosR+6));
    }
    elsif(($iR == ($iPosR-2))) {
        return 1 if($iC == 6);
        if($iV > 1) {
            return 1 if(($iC>=($iPosR-2)) and 
                        ($iC<=($iPosR+2)));
        }
    }
    elsif(($iR == ($iPosR-1))) {
        return 1 if($iC == 8);
        if($iV > 1) {
            return 1 if(($iC==($iPosR-2)) or 
                        ($iC==($iPosR+2)));
        }
    }
    elsif ($iR == $iPosR) {
        return 1 if((($iC >= 0) and ($iC <= 6)));
        if($iV > 1) {
            return 1 if(($iC==($iPosR-2)) or 
                        ($iC== $iPosR )   or
                        ($iC==($iPosR+2)));
        }
    }
    elsif ($iR == ($iPosR+1)) {
        return 1 if(($iC == 0) or ($iC == 6));
        if($iV > 1) {
            return 1 if(($iC==($iPosR-2)) or 
                        ($iC==($iPosR+2)));
        }
    }
    elsif ($iR == ($iPosR+2)) {
        return 1 if(($iC == 0) or 
                  (($iC >= 2) and ($iC <= 4))or
                  ($iC == 6));
        if($iV > 1) {
            return 1 if(($iC>=($iPosR-2)) and 
                        ($iC<=($iPosR+2)));
        }
    }
    elsif(($iR > ($iPosR+2)) and ($iR <= ($iPosR+4))) {
        return 1 
            if (($iC == 0) or 
                (($iC >= 2) and ($iC <= 4))or
                ($iC == 6));
    }
    elsif($iR == ($iPosR+5)) {
        return 1 
            if(($iC == 0) or ($iC == 6));
    }
    elsif($iR == ($iPosR+6)) {
        return 1 if(($iC >= 0) and ($iC <= 6));
    }
    else {
        return 1 if((($iR % 2)==0) and ($iC ==6));
    }
  #2. Depend on Version
    return 0 if(($iV >= 1) and ($iV <= 6));
    if($iV == 7) {
        if($iR==35){
            return ((($iC >= 1) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 35) and ($iC <= 36)))? 1 : 0;
        }
        elsif($iR==36){
            return (($iC == 0) or (($iC >= 3) and ($iC <= 4)) or (($iC >= 20) and ($iC <= 24)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 20) and ($iC <= 24)) or (($iC >= 34) and ($iC <= 36)))? 1 : 0;
        }
        elsif($iR==38){
            return (($iC == 20) or ($iC == 22) or ($iC == 24))? 1 : 0;
        }
        elsif($iR==22){
            return (($iC == 4) or ($iC == 8) or ($iC == 20) or ($iC == 22) or ($iC == 24) or ($iC == 36) or ($iC == 38) or ($iC == 40))? 1 : 0;
        }
        elsif($iR==34){
            return (($iC == 4))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 36))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==40)){
            return ((($iC >= 20) and ($iC <= 24)))? 1 : 0;
        }
        elsif(($iR==21) or ($iR==23)){
            return (($iC == 4) or ($iC == 8) or ($iC == 20) or ($iC == 24) or ($iC == 36) or ($iC == 40))? 1 : 0;
        }
        elsif(($iR==1) or ($iR==2)){
            return (($iC == 35))? 1 : 0;
        }
        elsif(($iR==20) or ($iR==24)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 20) and ($iC <= 24)) or (($iC >= 36) and ($iC <= 40)))? 1 : 0;
        }
        elsif(($iR==5) or ($iR==7) or ($iR==37) or ($iR==39)){
            return (($iC == 20) or ($iC == 24))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 8) {
        if($iR==40){
            return ((($iC >= 0) and ($iC <= 2)) or (($iC >= 22) and ($iC <= 26)))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 40))? 1 : 0;
        }
        elsif($iR==38){
            return (($iC == 1) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 22) or ($iC == 26) or ($iC == 38))? 1 : 0;
        }
        elsif($iR==24){
            return (($iC == 4) or ($iC == 8) or ($iC == 22) or ($iC == 24) or ($iC == 26) or ($iC == 40) or ($iC == 42) or ($iC == 44))? 1 : 0;
        }
        elsif($iR==39){
            return ((($iC >= 1) and ($iC <= 3)))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 38) and ($iC <= 40)))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 39) and ($iC <= 40)))? 1 : 0;
        }
        elsif($iR==42){
            return (($iC == 22) or ($iC == 24) or ($iC == 26))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 39))? 1 : 0;
        }
        elsif(($iR==23) or ($iR==25)){
            return (($iC == 4) or ($iC == 8) or ($iC == 22) or ($iC == 26) or ($iC == 40) or ($iC == 44))? 1 : 0;
        }
        elsif(($iR==22) or ($iR==26)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 22) and ($iC <= 26)) or (($iC >= 40) and ($iC <= 44)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==41) or ($iR==43)){
            return (($iC == 22) or ($iC == 26))? 1 : 0;
        }
        elsif(($iR==4) or ($iR==8) or ($iR==44)){
            return ((($iC >= 22) and ($iC <= 26)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 9) {
        if($iR==26){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 44) or ($iC == 46) or ($iC == 48))? 1 : 0;
        }
        elsif($iR==46){
            return (($iC == 24) or ($iC == 26) or ($iC == 28))? 1 : 0;
        }
        elsif($iR==44){
            return (($iC == 3) or (($iC >= 24) and ($iC <= 28)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 42))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 42))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 42) and ($iC <= 43)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 43))? 1 : 0;
        }
        elsif($iR==43){
            return ((($iC >= 1) and ($iC <= 2)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or ($iC == 42))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 42) or ($iC == 44))? 1 : 0;
        }
        elsif($iR==42){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 3) and ($iC <= 5)))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 44) and ($iC <= 48)))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 44) or ($iC == 48))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==48)){
            return ((($iC >= 24) and ($iC <= 28)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==45) or ($iR==47)){
            return (($iC == 24) or ($iC == 28))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 10) {
        if($iR==28){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 48) or ($iC == 50) or ($iC == 52))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 26) or ($iC == 30) or ($iC == 46))? 1 : 0;
        }
        elsif($iR==46){
            return (($iC == 0) or ($iC == 2) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==50){
            return (($iC == 26) or ($iC == 28) or ($iC == 30))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 26) and ($iC <= 30)) or ($iC == 47))? 1 : 0;
        }
        elsif($iR==47){
            return ((($iC >= 0) and ($iC <= 4)))? 1 : 0;
        }
        elsif(($iR==27) or ($iR==29)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 30) or ($iC == 48) or ($iC == 52))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==2)){
            return ((($iC >= 46) and ($iC <= 47)))? 1 : 0;
        }
        elsif(($iR==1) or ($iR==3)){
            return (($iC == 47))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==30)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 48) and ($iC <= 52)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==49) or ($iR==51)){
            return (($iC == 26) or ($iC == 30))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==48) or ($iR==52)){
            return ((($iC >= 26) and ($iC <= 30)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 11) {
        if($iR==50){
            return ((($iC >= 2) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==52){
            return ((($iC >= 0) and ($iC <= 3)) or (($iC >= 28) and ($iC <= 32)))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 50) and ($iC <= 52)))? 1 : 0;
        }
        elsif($iR==30){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56))? 1 : 0;
        }
        elsif($iR==54){
            return (($iC == 28) or ($iC == 30) or ($iC == 32))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 50) and ($iC <= 51)))? 1 : 0;
        }
        elsif($iR==51){
            return ((($iC >= 0) and ($iC <= 2)) or ($iC == 4))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 50))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 50) or ($iC == 52))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==1)){
            return ((($iC >= 51) and ($iC <= 52)))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==56)){
            return ((($iC >= 28) and ($iC <= 32)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==53) or ($iR==55)){
            return (($iC == 28) or ($iC == 32))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 12) {
        if($iR==55){
            return (($iC == 0) or ($iC == 3))? 1 : 0;
        }
        elsif($iR==56){
            return ((($iC >= 1) and ($iC <= 2)) or ($iC == 4) or (($iC >= 30) and ($iC <= 34)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 30) or ($iC == 34) or ($iC == 54))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 56))? 1 : 0;
        }
        elsif($iR==32){
            return (($iC == 4) or ($iC == 8) or ($iC == 30) or ($iC == 32) or ($iC == 34) or ($iC == 56) or ($iC == 58) or ($iC == 60))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 30) and ($iC <= 34)) or ($iC == 56))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 54) and ($iC <= 55)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 54) or ($iC == 56))? 1 : 0;
        }
        elsif($iR==54){
            return ((($iC >= 2) and ($iC <= 3)) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 55))? 1 : 0;
        }
        elsif($iR==58){
            return (($iC == 30) or ($iC == 32) or ($iC == 34))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==34)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==60)){
            return ((($iC >= 30) and ($iC <= 34)))? 1 : 0;
        }
        elsif(($iR==31) or ($iR==33)){
            return (($iC == 4) or ($iC == 8) or ($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==57) or ($iR==59)){
            return (($iC == 30) or ($iC == 34))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 13) {
        if($iR==3){
            return (($iC == 60))? 1 : 0;
        }
        elsif($iR==58){
            return (($iC == 0) or ($iC == 2) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 58))? 1 : 0;
        }
        elsif($iR==62){
            return (($iC == 32) or ($iC == 34) or ($iC == 36))? 1 : 0;
        }
        elsif($iR==60){
            return (($iC == 0) or (($iC >= 3) and ($iC <= 4)) or (($iC >= 32) and ($iC <= 36)))? 1 : 0;
        }
        elsif($iR==34){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64))? 1 : 0;
        }
        elsif($iR==0){
            return ((($iC >= 58) and ($iC <= 60)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 32) and ($iC <= 36)) or ($iC == 58) or ($iC == 60))? 1 : 0;
        }
        elsif($iR==59){
            return (($iC == 0))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 32) or ($iC == 36) or ($iC == 58))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==36)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)))? 1 : 0;
        }
        elsif(($iR==33) or ($iR==35)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==64)){
            return ((($iC >= 32) and ($iC <= 36)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==61) or ($iR==63)){
            return (($iC == 32) or ($iC == 36))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 14) {
        if($iR==63){
            return ((($iC >= 3) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 44) and ($iC <= 48)) or (($iC >= 63) and ($iC <= 64)))? 1 : 0;
        }
        elsif($iR==66){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 44) or ($iC == 46) or ($iC == 48))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 62) and ($iC <= 63)))? 1 : 0;
        }
        elsif($iR==64){
            return (($iC == 0) or ($iC == 4) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 44) and ($iC <= 48)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 44) or ($iC == 48) or ($iC == 62))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 62) or ($iC == 64))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 62))? 1 : 0;
        }
        elsif($iR==62){
            return ((($iC >= 0) and ($iC <= 1)) or ($iC == 3) or ($iC == 5))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==68)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 44) and ($iC <= 48)))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==46)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 44) or ($iC == 46) or ($iC == 48) or ($iC == 64) or ($iC == 66) or ($iC == 68))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==65) or ($iR==67)){
            return (($iC == 24) or ($iC == 28) or ($iC == 44) or ($iC == 48))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==45) or ($iR==47)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 44) or ($iC == 48) or ($iC == 64) or ($iC == 68))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==44) or ($iR==48)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 44) and ($iC <= 48)) or (($iC >= 64) and ($iC <= 68)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 15) {
        if($iR==66){
            return (($iC == 1) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 46) and ($iC <= 50)) or (($iC >= 66) and ($iC <= 68)))? 1 : 0;
        }
        elsif($iR==68){
            return ((($iC >= 1) and ($iC <= 4)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 46) and ($iC <= 50)))? 1 : 0;
        }
        elsif($iR==67){
            return (($iC == 4))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 66) or ($iC == 68))? 1 : 0;
        }
        elsif($iR==70){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 46) or ($iC == 48) or ($iC == 50))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 46) or ($iC == 50) or ($iC == 66))? 1 : 0;
        }
        elsif(($iR==2) or ($iR==3)){
            return (($iC == 68))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==72)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 46) and ($iC <= 50)))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==48)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 46) or ($iC == 48) or ($iC == 50) or ($iC == 68) or ($iC == 70) or ($iC == 72))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==69) or ($iR==71)){
            return (($iC == 24) or ($iC == 28) or ($iC == 46) or ($iC == 50))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==46) or ($iR==50)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 46) and ($iC <= 50)) or (($iC >= 68) and ($iC <= 72)))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==47) or ($iR==49)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 46) or ($iC == 50) or ($iC == 68) or ($iC == 72))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 16) {
        if($iR==74){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 48) or ($iC == 50) or ($iC == 52))? 1 : 0;
        }
        elsif($iR==70){
            return ((($iC >= 1) and ($iC <= 3)))? 1 : 0;
        }
        elsif($iR==72){
            return ((($iC >= 1) and ($iC <= 3)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 70) and ($iC <= 72)))? 1 : 0;
        }
        elsif($iR==71){
            return (($iC == 1) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 71))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==50)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 72) or ($iC == 74) or ($iC == 76))? 1 : 0;
        }
        elsif(($iR==2) or ($iR==3)){
            return (($iC == 70) or ($iC == 72))? 1 : 0;
        }
        elsif(($iR==4) or ($iR==8) or ($iR==76)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==73) or ($iR==75)){
            return (($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==48) or ($iR==52)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==49) or ($iR==51)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 17) {
        if($iR==2){
            return (($iC == 74))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 75))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 74) or ($iC == 76))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or ($iC == 74))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 75))? 1 : 0;
        }
        elsif($iR==74){
            return ((($iC >= 0) and ($iC <= 2)) or ($iC == 4))? 1 : 0;
        }
        elsif($iR==78){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 74) and ($iC <= 75)))? 1 : 0;
        }
        elsif($iR==76){
            return (($iC == 0) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)))? 1 : 0;
        }
        elsif($iR==75){
            return (($iC == 1) or ($iC == 3) or ($iC == 5))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==54)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==80)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==77) or ($iR==79)){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==53) or ($iR==55)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==52) or ($iR==56)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 18) {
        if($iR==79){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==78){
            return (($iC == 0) or ($iC == 3))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 78) or ($iC == 80))? 1 : 0;
        }
        elsif($iR==80){
            return (($iC == 0) or ($iC == 3) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)))? 1 : 0;
        }
        elsif($iR==82){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 54) or ($iC == 56) or ($iC == 58))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 54) or ($iC == 58) or ($iC == 79))? 1 : 0;
        }
        elsif($iR==0){
            return ((($iC >= 78) and ($iC <= 80)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 79))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)) or ($iC == 79))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==84)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==56)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 54) or ($iC == 56) or ($iC == 58) or ($iC == 80) or ($iC == 82) or ($iC == 84))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==81) or ($iR==83)){
            return (($iC == 28) or ($iC == 32) or ($iC == 54) or ($iC == 58))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==55) or ($iR==57)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 54) or ($iC == 58) or ($iC == 80) or ($iC == 84))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==54) or ($iR==58)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)) or (($iC >= 80) and ($iC <= 84)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 19) {
        if($iR==1){
            return ((($iC >= 83) and ($iC <= 84)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 83)))? 1 : 0;
        }
        elsif($iR==84){
            return ((($iC >= 1) and ($iC <= 2)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)))? 1 : 0;
        }
        elsif($iR==83){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 3) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 84))? 1 : 0;
        }
        elsif($iR==86){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60))? 1 : 0;
        }
        elsif($iR==82){
            return (($iC == 4))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 83))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==3)){
            return (($iC == 83))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==58)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==88)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==85) or ($iR==87)){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==57) or ($iR==59)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==56) or ($iR==60)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 20) {
        if($iR==4){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or ($iC == 88))? 1 : 0;
        }
        elsif($iR==87){
            return (($iC == 0) or ($iC == 2) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==88){
            return ((($iC >= 0) and ($iC <= 4)) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)))? 1 : 0;
        }
        elsif($iR==90){
            return (($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 87))? 1 : 0;
        }
        elsif(($iR==1) or ($iR==3)){
            return (($iC == 88))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==2)){
            return ((($iC >= 87) and ($iC <= 88)))? 1 : 0;
        }
        elsif(($iR==34) or ($iR==62)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64) or ($iC == 88) or ($iC == 90) or ($iC == 92))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==92)){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==89) or ($iR==91)){
            return (($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==36) or ($iR==60) or ($iR==64)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)))? 1 : 0;
        }
        elsif(($iR==33) or ($iR==35) or ($iR==61) or ($iR==63)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 21) {
        if($iR==90){
            return (($iC == 0) or (($iC >= 3) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 91))? 1 : 0;
        }
        elsif($iR==91){
            return (($iC == 0) or (($iC >= 2) and ($iC <= 3)) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==94){
            return (($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 70) or ($iC == 72) or ($iC == 74))? 1 : 0;
        }
        elsif($iR==92){
            return (($iC == 4) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 70) and ($iC <= 74)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 26) or ($iC == 30) or ($iC == 48) or ($iC == 52) or ($iC == 70) or ($iC == 74) or ($iC == 91))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 26) and ($iC <= 30)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 70) and ($iC <= 74)) or ($iC == 90) or ($iC == 92))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==3)){
            return ((($iC >= 90) and ($iC <= 91)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==96)){
            return ((($iC >= 26) and ($iC <= 30)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 70) and ($iC <= 74)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==93) or ($iR==95)){
            return (($iC == 26) or ($iC == 30) or ($iC == 48) or ($iC == 52) or ($iC == 70) or ($iC == 74))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==50) or ($iR==72)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 70) or ($iC == 72) or ($iC == 74) or ($iC == 92) or ($iC == 94) or ($iC == 96))? 1 : 0;
        }
        elsif(($iR==27) or ($iR==29) or ($iR==49) or ($iR==51) or ($iR==71) or ($iR==73)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 30) or ($iC == 48) or ($iC == 52) or ($iC == 70) or ($iC == 74) or ($iC == 92) or ($iC == 96))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==30) or ($iR==48) or ($iR==52) or ($iR==70) or ($iR==74)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 70) and ($iC <= 74)) or (($iC >= 92) and ($iC <= 96)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 22) {
        if($iR==98){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 72) or ($iC == 74) or ($iC == 76))? 1 : 0;
        }
        elsif($iR==95){
            return (($iC == 2) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 96))? 1 : 0;
        }
        elsif($iR==96){
            return ((($iC >= 3) and ($iC <= 4)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)))? 1 : 0;
        }
        elsif($iR==94){
            return ((($iC >= 0) and ($iC <= 2)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)) or (($iC >= 95) and ($iC <= 96)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76) or ($iC == 95))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 94) and ($iC <= 95)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==100)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==1)){
            return (($iC == 94))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==50) or ($iR==74)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 72) or ($iC == 74) or ($iC == 76) or ($iC == 96) or ($iC == 98) or ($iC == 100))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==97) or ($iR==99)){
            return (($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==48) or ($iR==52) or ($iR==72) or ($iR==76)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)) or (($iC >= 96) and ($iC <= 100)))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==49) or ($iR==51) or ($iR==73) or ($iR==75)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76) or ($iC == 96) or ($iC == 100))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 23) {
        if($iR==3){
            return ((($iC >= 98) and ($iC <= 99)))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 98) and ($iC <= 100)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 98) or ($iC == 100))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 99))? 1 : 0;
        }
        elsif($iR==100){
            return ((($iC >= 0) and ($iC <= 2)) or ($iC == 4) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)))? 1 : 0;
        }
        elsif($iR==99){
            return ((($iC >= 2) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 98) and ($iC <= 100)))? 1 : 0;
        }
        elsif($iR==102){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 100))? 1 : 0;
        }
        elsif($iR==98){
            return ((($iC >= 1) and ($iC <= 4)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==104)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==101) or ($iR==103)){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==54) or ($iR==78)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 100) or ($iC == 102) or ($iC == 104))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==52) or ($iR==56) or ($iR==76) or ($iR==80)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==53) or ($iR==55) or ($iR==77) or ($iR==79)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 24) {
        if($iR==0){
            return (($iC == 104))? 1 : 0;
        }
        elsif($iR==106){
            return (($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 78) or ($iC == 80) or ($iC == 82))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 102) and ($iC <= 104)))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 102) and ($iC <= 103)))? 1 : 0;
        }
        elsif($iR==104){
            return (($iC == 0) or ($iC == 3) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 26) or ($iC == 30) or ($iC == 52) or ($iC == 56) or ($iC == 78) or ($iC == 82) or (($iC >= 102) and ($iC <= 103)))? 1 : 0;
        }
        elsif(($iR==102) or ($iR==103)){
            return ((($iC >= 2) and ($iC <= 3)) or ($iC == 5))? 1 : 0;
        }
        elsif(($iR==4) or ($iR==8) or ($iR==108)){
            return ((($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==105) or ($iR==107)){
            return (($iC == 26) or ($iC == 30) or ($iC == 52) or ($iC == 56) or ($iC == 78) or ($iC == 82))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==54) or ($iR==80)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 78) or ($iC == 80) or ($iC == 82) or ($iC == 104) or ($iC == 106) or ($iC == 108))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==30) or ($iR==52) or ($iR==56) or ($iR==78) or ($iR==82)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)) or (($iC >= 104) and ($iC <= 108)))? 1 : 0;
        }
        elsif(($iR==27) or ($iR==29) or ($iR==53) or ($iR==55) or ($iR==79) or ($iR==81)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 30) or ($iC == 52) or ($iC == 56) or ($iC == 78) or ($iC == 82) or ($iC == 104) or ($iC == 108))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 25) {
        if($iR==1){
            return (($iC == 108))? 1 : 0;
        }
        elsif($iR==106){
            return (($iC == 0) or ($iC == 2) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==108){
            return ((($iC >= 1) and ($iC <= 2)) or (($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60) or ($iC == 82) or ($iC == 86) or (($iC >= 106) and ($iC <= 107)))? 1 : 0;
        }
        elsif($iR==110){
            return (($iC == 30) or ($iC == 32) or ($iC == 34) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 82) or ($iC == 84) or ($iC == 86))? 1 : 0;
        }
        elsif($iR==107){
            return (($iC == 2) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 106) and ($iC <= 108)))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 106))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)) or ($iC == 106))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==112)){
            return ((($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==109) or ($iR==111)){
            return (($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60) or ($iC == 82) or ($iC == 86))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==58) or ($iR==84)){
            return (($iC == 4) or ($iC == 8) or ($iC == 30) or ($iC == 32) or ($iC == 34) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 82) or ($iC == 84) or ($iC == 86) or ($iC == 108) or ($iC == 110) or ($iC == 112))? 1 : 0;
        }
        elsif(($iR==31) or ($iR==33) or ($iR==57) or ($iR==59) or ($iR==83) or ($iR==85)){
            return (($iC == 4) or ($iC == 8) or ($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60) or ($iC == 82) or ($iC == 86) or ($iC == 108) or ($iC == 112))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==34) or ($iR==56) or ($iR==60) or ($iR==82) or ($iR==86)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)) or (($iC >= 108) and ($iC <= 112)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 26) {
        if($iR==112){
            return ((($iC >= 1) and ($iC <= 3)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)))? 1 : 0;
        }
        elsif($iR==0){
            return ((($iC >= 110) and ($iC <= 111)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 110) or ($iC == 112))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or ($iC == 111))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 110) and ($iC <= 112)))? 1 : 0;
        }
        elsif($iR==110){
            return ((($iC >= 0) and ($iC <= 1)) or ($iC == 3) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==114){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 111) and ($iC <= 112)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or (($iC >= 110) and ($iC <= 111)))? 1 : 0;
        }
        elsif($iR==111){
            return (($iC == 0) or (($iC >= 2) and ($iC <= 5)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==116)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==113) or ($iR==115)){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==58) or ($iR==86)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 112) or ($iC == 114) or ($iC == 116))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==57) or ($iR==59) or ($iR==85) or ($iR==87)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==56) or ($iR==60) or ($iR==84) or ($iR==88)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 27) {
        if($iR==116){
            return (($iC == 0) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)))? 1 : 0;
        }
        elsif($iR==114){
            return (($iC == 1) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==118){
            return (($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64) or ($iC == 88) or ($iC == 90) or ($iC == 92))? 1 : 0;
        }
        elsif($iR==115){
            return (($iC == 0) or ($iC == 2) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 114))? 1 : 0;
        }
        elsif($iR==0){
            return ((($iC >= 115) and ($iC <= 116)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92) or (($iC >= 114) and ($iC <= 115)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 115))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)) or (($iC >= 114) and ($iC <= 115)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==120)){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)))? 1 : 0;
        }
        elsif(($iR==34) or ($iR==62) or ($iR==90)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64) or ($iC == 88) or ($iC == 90) or ($iC == 92) or ($iC == 116) or ($iC == 118) or ($iC == 120))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==117) or ($iR==119)){
            return (($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92))? 1 : 0;
        }
        elsif(($iR==33) or ($iR==35) or ($iR==61) or ($iR==63) or ($iR==89) or ($iR==91)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92) or ($iC == 116) or ($iC == 120))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==36) or ($iR==60) or ($iR==64) or ($iR==88) or ($iR==92)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)) or (($iC >= 116) and ($iC <= 120)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 28) {
        if($iR==122){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 72) or ($iC == 74) or ($iC == 76) or ($iC == 96) or ($iC == 98) or ($iC == 100))? 1 : 0;
        }
        elsif($iR==120){
            return ((($iC >= 3) and ($iC <= 4)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)) or (($iC >= 96) and ($iC <= 100)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76) or ($iC == 96) or ($iC == 100) or (($iC >= 118) and ($iC <= 119)))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 119) and ($iC <= 120)))? 1 : 0;
        }
        elsif($iR==118){
            return (($iC == 1) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 118) and ($iC <= 119)))? 1 : 0;
        }
        elsif($iR==119){
            return ((($iC >= 0) and ($iC <= 1)) or ($iC == 3) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)) or (($iC >= 96) and ($iC <= 100)) or ($iC == 120))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 119))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==124)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)) or (($iC >= 96) and ($iC <= 100)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==121) or ($iR==123)){
            return (($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76) or ($iC == 96) or ($iC == 100))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==50) or ($iR==74) or ($iR==98)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 72) or ($iC == 74) or ($iC == 76) or ($iC == 96) or ($iC == 98) or ($iC == 100) or ($iC == 120) or ($iC == 122) or ($iC == 124))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==48) or ($iR==52) or ($iR==72) or ($iR==76) or ($iR==96) or ($iR==100)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 72) and ($iC <= 76)) or (($iC >= 96) and ($iC <= 100)) or (($iC >= 120) and ($iC <= 124)))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==49) or ($iR==51) or ($iR==73) or ($iR==75) or ($iR==97) or ($iR==99)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 48) or ($iC == 52) or ($iC == 72) or ($iC == 76) or ($iC == 96) or ($iC == 100) or ($iC == 120) or ($iC == 124))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 29) {
        if($iR==123){
            return ((($iC >= 0) and ($iC <= 1)) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==122){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 3) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)) or ($iC == 122) or ($iC == 124))? 1 : 0;
        }
        elsif($iR==126){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 100) or ($iC == 102) or ($iC == 104))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 122))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104) or (($iC >= 122) and ($iC <= 123)))? 1 : 0;
        }
        elsif($iR==124){
            return ((($iC >= 0) and ($iC <= 2)) or ($iC == 4) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 124))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==128)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==1)){
            return ((($iC >= 122) and ($iC <= 124)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==125) or ($iR==127)){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==54) or ($iR==78) or ($iR==102)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 100) or ($iC == 102) or ($iC == 104) or ($iC == 124) or ($iC == 126) or ($iC == 128))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==53) or ($iR==55) or ($iR==77) or ($iR==79) or ($iR==101) or ($iR==103)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104) or ($iC == 124) or ($iC == 128))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==52) or ($iR==56) or ($iR==76) or ($iR==80) or ($iR==100) or ($iR==104)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 124) and ($iC <= 128)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 30) {
        if($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 50) and ($iC <= 54)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 102) and ($iC <= 106)) or (($iC >= 127) and ($iC <= 128)))? 1 : 0;
        }
        elsif($iR==128){
            return ((($iC >= 0) and ($iC <= 4)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 50) and ($iC <= 54)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 102) and ($iC <= 106)))? 1 : 0;
        }
        elsif($iR==127){
            return (($iC == 1) or (($iC >= 3) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 50) or ($iC == 54) or ($iC == 76) or ($iC == 80) or ($iC == 102) or ($iC == 106) or (($iC >= 126) and ($iC <= 127)))? 1 : 0;
        }
        elsif($iR==130){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 50) or ($iC == 52) or ($iC == 54) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 102) or ($iC == 104) or ($iC == 106))? 1 : 0;
        }
        elsif($iR==126){
            return (($iC == 0) or ($iC == 2) or ($iC == 5))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==132)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 50) and ($iC <= 54)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 102) and ($iC <= 106)))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==2)){
            return (($iC == 126) or ($iC == 128))? 1 : 0;
        }
        elsif(($iR==1) or ($iR==3)){
            return ((($iC >= 127) and ($iC <= 128)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==129) or ($iR==131)){
            return (($iC == 24) or ($iC == 28) or ($iC == 50) or ($iC == 54) or ($iC == 76) or ($iC == 80) or ($iC == 102) or ($iC == 106))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==52) or ($iR==78) or ($iR==104)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 50) or ($iC == 52) or ($iC == 54) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 102) or ($iC == 104) or ($iC == 106) or ($iC == 128) or ($iC == 130) or ($iC == 132))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==51) or ($iR==53) or ($iR==77) or ($iR==79) or ($iR==103) or ($iR==105)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 50) or ($iC == 54) or ($iC == 76) or ($iC == 80) or ($iC == 102) or ($iC == 106) or ($iC == 128) or ($iC == 132))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==50) or ($iR==54) or ($iR==76) or ($iR==80) or ($iR==102) or ($iR==106)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 50) and ($iC <= 54)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 102) and ($iC <= 106)) or (($iC >= 128) and ($iC <= 132)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 31) {
        if($iR==131){
            return (($iC == 1) or (($iC >= 4) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==134){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 54) or ($iC == 56) or ($iC == 58) or ($iC == 80) or ($iC == 82) or ($iC == 84) or ($iC == 106) or ($iC == 108) or ($iC == 110))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 54) or ($iC == 58) or ($iC == 80) or ($iC == 84) or ($iC == 106) or ($iC == 110) or (($iC >= 130) and ($iC <= 131)))? 1 : 0;
        }
        elsif($iR==130){
            return ((($iC >= 2) and ($iC <= 5)))? 1 : 0;
        }
        elsif($iR==132){
            return (($iC == 4) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 106) and ($iC <= 110)))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 106) and ($iC <= 110)) or (($iC >= 130) and ($iC <= 132)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 131))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==136)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 106) and ($iC <= 110)))? 1 : 0;
        }
        elsif(($iR==2) or ($iR==3)){
            return (($iC == 130))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==133) or ($iR==135)){
            return (($iC == 28) or ($iC == 32) or ($iC == 54) or ($iC == 58) or ($iC == 80) or ($iC == 84) or ($iC == 106) or ($iC == 110))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==56) or ($iR==82) or ($iR==108)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 54) or ($iC == 56) or ($iC == 58) or ($iC == 80) or ($iC == 82) or ($iC == 84) or ($iC == 106) or ($iC == 108) or ($iC == 110) or ($iC == 132) or ($iC == 134) or ($iC == 136))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==55) or ($iR==57) or ($iR==81) or ($iR==83) or ($iR==107) or ($iR==109)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 54) or ($iC == 58) or ($iC == 80) or ($iC == 84) or ($iC == 106) or ($iC == 110) or ($iC == 132) or ($iC == 136))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==54) or ($iR==58) or ($iR==80) or ($iR==84) or ($iR==106) or ($iR==110)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 54) and ($iC <= 58)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 106) and ($iC <= 110)) or (($iC >= 132) and ($iC <= 136)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 32) {
        if($iR==134){
            return (($iC == 0) or ($iC == 2))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 32) or ($iC == 36) or ($iC == 58) or ($iC == 62) or ($iC == 84) or ($iC == 88) or ($iC == 110) or ($iC == 114) or ($iC == 136))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 134) or ($iC == 136))? 1 : 0;
        }
        elsif($iR==138){
            return (($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 58) or ($iC == 60) or ($iC == 62) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 110) or ($iC == 112) or ($iC == 114))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 134) and ($iC <= 136)))? 1 : 0;
        }
        elsif($iR==135){
            return ((($iC >= 1) and ($iC <= 2)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 135))? 1 : 0;
        }
        elsif($iR==136){
            return (($iC == 0) or (($iC >= 2) and ($iC <= 3)) or ($iC == 5) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 58) and ($iC <= 62)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 110) and ($iC <= 114)))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 136))? 1 : 0;
        }
        elsif(($iR==4) or ($iR==8) or ($iR==140)){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 58) and ($iC <= 62)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 110) and ($iC <= 114)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==137) or ($iR==139)){
            return (($iC == 32) or ($iC == 36) or ($iC == 58) or ($iC == 62) or ($iC == 84) or ($iC == 88) or ($iC == 110) or ($iC == 114))? 1 : 0;
        }
        elsif(($iR==34) or ($iR==60) or ($iR==86) or ($iR==112)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 58) or ($iC == 60) or ($iC == 62) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 110) or ($iC == 112) or ($iC == 114) or ($iC == 136) or ($iC == 138) or ($iC == 140))? 1 : 0;
        }
        elsif(($iR==33) or ($iR==35) or ($iR==59) or ($iR==61) or ($iR==85) or ($iR==87) or ($iR==111) or ($iR==113)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 36) or ($iC == 58) or ($iC == 62) or ($iC == 84) or ($iC == 88) or ($iC == 110) or ($iC == 114) or ($iC == 136) or ($iC == 140))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==36) or ($iR==58) or ($iR==62) or ($iR==84) or ($iR==88) or ($iR==110) or ($iR==114)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 58) and ($iC <= 62)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 110) and ($iC <= 114)) or (($iC >= 136) and ($iC <= 140)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 33) {
        if($iR==142){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 112) or ($iC == 114) or ($iC == 116))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)) or ($iC == 138))? 1 : 0;
        }
        elsif($iR==138){
            return ((($iC >= 2) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==140){
            return (($iC == 1) or ($iC == 5) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)))? 1 : 0;
        }
        elsif($iR==139){
            return ((($iC >= 1) and ($iC <= 3)))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 139) and ($iC <= 140)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116) or ($iC == 140))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==144)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)))? 1 : 0;
        }
        elsif(($iR==2) or ($iR==3)){
            return ((($iC >= 138) and ($iC <= 139)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==141) or ($iR==143)){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==58) or ($iR==86) or ($iR==114)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 112) or ($iC == 114) or ($iC == 116) or ($iC == 140) or ($iC == 142) or ($iC == 144))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==56) or ($iR==60) or ($iR==84) or ($iR==88) or ($iR==112) or ($iR==116)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)) or (($iC >= 140) and ($iC <= 144)))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==57) or ($iR==59) or ($iR==85) or ($iR==87) or ($iR==113) or ($iR==115)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116) or ($iC == 140) or ($iC == 144))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 34) {
        if($iR==4){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)) or (($iC >= 116) and ($iC <= 120)) or ($iC == 143))? 1 : 0;
        }
        elsif($iR==142){
            return (($iC == 1))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92) or ($iC == 116) or ($iC == 120) or ($iC == 144))? 1 : 0;
        }
        elsif($iR==146){
            return (($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64) or ($iC == 88) or ($iC == 90) or ($iC == 92) or ($iC == 116) or ($iC == 118) or ($iC == 120))? 1 : 0;
        }
        elsif($iR==144){
            return (($iC == 1) or ($iC == 3) or ($iC == 5) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)) or (($iC >= 116) and ($iC <= 120)))? 1 : 0;
        }
        elsif($iR==143){
            return ((($iC >= 0) and ($iC <= 2)) or ($iC == 4))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 144))? 1 : 0;
        }
        elsif($iR==1){
            return ((($iC >= 142) and ($iC <= 144)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==148)){
            return ((($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)) or (($iC >= 116) and ($iC <= 120)))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==2)){
            return (($iC == 143))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==145) or ($iR==147)){
            return (($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92) or ($iC == 116) or ($iC == 120))? 1 : 0;
        }
        elsif(($iR==34) or ($iR==62) or ($iR==90) or ($iR==118)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 34) or ($iC == 36) or ($iC == 60) or ($iC == 62) or ($iC == 64) or ($iC == 88) or ($iC == 90) or ($iC == 92) or ($iC == 116) or ($iC == 118) or ($iC == 120) or ($iC == 144) or ($iC == 146) or ($iC == 148))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==36) or ($iR==60) or ($iR==64) or ($iR==88) or ($iR==92) or ($iR==116) or ($iR==120)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 32) and ($iC <= 36)) or (($iC >= 60) and ($iC <= 64)) or (($iC >= 88) and ($iC <= 92)) or (($iC >= 116) and ($iC <= 120)) or (($iC >= 144) and ($iC <= 148)))? 1 : 0;
        }
        elsif(($iR==33) or ($iR==35) or ($iR==61) or ($iR==63) or ($iR==89) or ($iR==91) or ($iR==117) or ($iR==119)){
            return (($iC == 4) or ($iC == 8) or ($iC == 32) or ($iC == 36) or ($iC == 60) or ($iC == 64) or ($iC == 88) or ($iC == 92) or ($iC == 116) or ($iC == 120) or ($iC == 144) or ($iC == 148))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 35) {
        if($iR==146){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 3) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104) or ($iC == 124) or ($iC == 128) or ($iC == 148))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 124) and ($iC <= 128)) or (($iC >= 146) and ($iC <= 147)))? 1 : 0;
        }
        elsif($iR==148){
            return (($iC == 0) or ($iC == 2) or ($iC == 5) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 124) and ($iC <= 128)))? 1 : 0;
        }
        elsif($iR==2){
            return ((($iC >= 147) and ($iC <= 148)))? 1 : 0;
        }
        elsif($iR==0){
            return ((($iC >= 146) and ($iC <= 148)))? 1 : 0;
        }
        elsif($iR==147){
            return ((($iC >= 0) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==150){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 100) or ($iC == 102) or ($iC == 104) or ($iC == 124) or ($iC == 126) or ($iC == 128))? 1 : 0;
        }
        elsif(($iR==1) or ($iR==3)){
            return ((($iC >= 146) and ($iC <= 147)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==152)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 124) and ($iC <= 128)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==149) or ($iR==151)){
            return (($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104) or ($iC == 124) or ($iC == 128))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==54) or ($iR==78) or ($iR==102) or ($iR==126)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 76) or ($iC == 78) or ($iC == 80) or ($iC == 100) or ($iC == 102) or ($iC == 104) or ($iC == 124) or ($iC == 126) or ($iC == 128) or ($iC == 148) or ($iC == 150) or ($iC == 152))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==53) or ($iR==55) or ($iR==77) or ($iR==79) or ($iR==101) or ($iR==103) or ($iR==125) or ($iR==127)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 52) or ($iC == 56) or ($iC == 76) or ($iC == 80) or ($iC == 100) or ($iC == 104) or ($iC == 124) or ($iC == 128) or ($iC == 148) or ($iC == 152))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==52) or ($iR==56) or ($iR==76) or ($iR==80) or ($iR==100) or ($iR==104) or ($iR==124) or ($iR==128)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 76) and ($iC <= 80)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 124) and ($iC <= 128)) or (($iC >= 148) and ($iC <= 152)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 36) {
        if($iR==5){
            return (($iC == 22) or ($iC == 26) or ($iC == 48) or ($iC == 52) or ($iC == 74) or ($iC == 78) or ($iC == 100) or ($iC == 104) or ($iC == 126) or ($iC == 130) or ($iC == 152))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 22) and ($iC <= 26)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 74) and ($iC <= 78)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 126) and ($iC <= 130)) or ($iC == 152))? 1 : 0;
        }
        elsif($iR==154){
            return (($iC == 22) or ($iC == 24) or ($iC == 26) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 74) or ($iC == 76) or ($iC == 78) or ($iC == 100) or ($iC == 102) or ($iC == 104) or ($iC == 126) or ($iC == 128) or ($iC == 130))? 1 : 0;
        }
        elsif($iR==150){
            return ((($iC >= 0) and ($iC <= 1)) or ($iC == 3))? 1 : 0;
        }
        elsif($iR==0){
            return ((($iC >= 150) and ($iC <= 151)))? 1 : 0;
        }
        elsif($iR==151){
            return (($iC == 0))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 150))? 1 : 0;
        }
        elsif($iR==152){
            return ((($iC >= 2) and ($iC <= 5)) or (($iC >= 22) and ($iC <= 26)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 74) and ($iC <= 78)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 126) and ($iC <= 130)))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 150) or ($iC == 152))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 152))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==156)){
            return ((($iC >= 22) and ($iC <= 26)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 74) and ($iC <= 78)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 126) and ($iC <= 130)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==153) or ($iR==155)){
            return (($iC == 22) or ($iC == 26) or ($iC == 48) or ($iC == 52) or ($iC == 74) or ($iC == 78) or ($iC == 100) or ($iC == 104) or ($iC == 126) or ($iC == 130))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==50) or ($iR==76) or ($iR==102) or ($iR==128)){
            return (($iC == 4) or ($iC == 8) or ($iC == 22) or ($iC == 24) or ($iC == 26) or ($iC == 48) or ($iC == 50) or ($iC == 52) or ($iC == 74) or ($iC == 76) or ($iC == 78) or ($iC == 100) or ($iC == 102) or ($iC == 104) or ($iC == 126) or ($iC == 128) or ($iC == 130) or ($iC == 152) or ($iC == 154) or ($iC == 156))? 1 : 0;
        }
        elsif(($iR==22) or ($iR==26) or ($iR==48) or ($iR==52) or ($iR==74) or ($iR==78) or ($iR==100) or ($iR==104) or ($iR==126) or ($iR==130)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 22) and ($iC <= 26)) or (($iC >= 48) and ($iC <= 52)) or (($iC >= 74) and ($iC <= 78)) or (($iC >= 100) and ($iC <= 104)) or (($iC >= 126) and ($iC <= 130)) or (($iC >= 152) and ($iC <= 156)))? 1 : 0;
        }
        elsif(($iR==23) or ($iR==25) or ($iR==49) or ($iR==51) or ($iR==75) or ($iR==77) or ($iR==101) or ($iR==103) or ($iR==127) or ($iR==129)){
            return (($iC == 4) or ($iC == 8) or ($iC == 22) or ($iC == 26) or ($iC == 48) or ($iC == 52) or ($iC == 74) or ($iC == 78) or ($iC == 100) or ($iC == 104) or ($iC == 126) or ($iC == 130) or ($iC == 152) or ($iC == 156))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 37) {
        if($iR==0){
            return ((($iC >= 155) and ($iC <= 156)))? 1 : 0;
        }
        elsif($iR==1){
            return (($iC == 154) or ($iC == 156))? 1 : 0;
        }
        elsif($iR==155){
            return (($iC == 0) or ($iC == 3))? 1 : 0;
        }
        elsif($iR==158){
            return (($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 78) or ($iC == 80) or ($iC == 82) or ($iC == 104) or ($iC == 106) or ($iC == 108) or ($iC == 130) or ($iC == 132) or ($iC == 134))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 155))? 1 : 0;
        }
        elsif($iR==154){
            return (($iC == 1) or ($iC == 4))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)) or (($iC >= 104) and ($iC <= 108)) or (($iC >= 130) and ($iC <= 134)) or ($iC == 154) or ($iC == 156))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 26) or ($iC == 30) or ($iC == 52) or ($iC == 56) or ($iC == 78) or ($iC == 82) or ($iC == 104) or ($iC == 108) or ($iC == 130) or ($iC == 134) or ($iC == 156))? 1 : 0;
        }
        elsif($iR==156){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 4) and ($iC <= 5)) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)) or (($iC >= 104) and ($iC <= 108)) or (($iC >= 130) and ($iC <= 134)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==160)){
            return ((($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)) or (($iC >= 104) and ($iC <= 108)) or (($iC >= 130) and ($iC <= 134)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==157) or ($iR==159)){
            return (($iC == 26) or ($iC == 30) or ($iC == 52) or ($iC == 56) or ($iC == 78) or ($iC == 82) or ($iC == 104) or ($iC == 108) or ($iC == 130) or ($iC == 134))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==54) or ($iR==80) or ($iR==106) or ($iR==132)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 28) or ($iC == 30) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 78) or ($iC == 80) or ($iC == 82) or ($iC == 104) or ($iC == 106) or ($iC == 108) or ($iC == 130) or ($iC == 132) or ($iC == 134) or ($iC == 156) or ($iC == 158) or ($iC == 160))? 1 : 0;
        }
        elsif(($iR==27) or ($iR==29) or ($iR==53) or ($iR==55) or ($iR==79) or ($iR==81) or ($iR==105) or ($iR==107) or ($iR==131) or ($iR==133)){
            return (($iC == 4) or ($iC == 8) or ($iC == 26) or ($iC == 30) or ($iC == 52) or ($iC == 56) or ($iC == 78) or ($iC == 82) or ($iC == 104) or ($iC == 108) or ($iC == 130) or ($iC == 134) or ($iC == 156) or ($iC == 160))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==30) or ($iR==52) or ($iR==56) or ($iR==78) or ($iR==82) or ($iR==104) or ($iR==108) or ($iR==130) or ($iR==134)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 26) and ($iC <= 30)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 78) and ($iC <= 82)) or (($iC >= 104) and ($iC <= 108)) or (($iC >= 130) and ($iC <= 134)) or (($iC >= 156) and ($iC <= 160)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 38) {
        if($iR==3){
            return (($iC == 158) or ($iC == 160))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 134) and ($iC <= 138)) or (($iC >= 159) and ($iC <= 160)))? 1 : 0;
        }
        elsif($iR==160){
            return ((($iC >= 0) and ($iC <= 1)) or (($iC >= 3) and ($iC <= 5)) or (($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 134) and ($iC <= 138)))? 1 : 0;
        }
        elsif($iR==159){
            return (($iC == 4))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60) or ($iC == 82) or ($iC == 86) or ($iC == 108) or ($iC == 112) or ($iC == 134) or ($iC == 138) or ($iC == 160))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 158))? 1 : 0;
        }
        elsif($iR==162){
            return (($iC == 30) or ($iC == 32) or ($iC == 34) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 82) or ($iC == 84) or ($iC == 86) or ($iC == 108) or ($iC == 110) or ($iC == 112) or ($iC == 134) or ($iC == 136) or ($iC == 138))? 1 : 0;
        }
        elsif($iR==158){
            return ((($iC >= 2) and ($iC <= 3)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==164)){
            return ((($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 134) and ($iC <= 138)))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==1)){
            return (($iC == 160))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==161) or ($iR==163)){
            return (($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60) or ($iC == 82) or ($iC == 86) or ($iC == 108) or ($iC == 112) or ($iC == 134) or ($iC == 138))? 1 : 0;
        }
        elsif(($iR==32) or ($iR==58) or ($iR==84) or ($iR==110) or ($iR==136)){
            return (($iC == 4) or ($iC == 8) or ($iC == 30) or ($iC == 32) or ($iC == 34) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 82) or ($iC == 84) or ($iC == 86) or ($iC == 108) or ($iC == 110) or ($iC == 112) or ($iC == 134) or ($iC == 136) or ($iC == 138) or ($iC == 160) or ($iC == 162) or ($iC == 164))? 1 : 0;
        }
        elsif(($iR==31) or ($iR==33) or ($iR==57) or ($iR==59) or ($iR==83) or ($iR==85) or ($iR==109) or ($iR==111) or ($iR==135) or ($iR==137)){
            return (($iC == 4) or ($iC == 8) or ($iC == 30) or ($iC == 34) or ($iC == 56) or ($iC == 60) or ($iC == 82) or ($iC == 86) or ($iC == 108) or ($iC == 112) or ($iC == 134) or ($iC == 138) or ($iC == 160) or ($iC == 164))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==34) or ($iR==56) or ($iR==60) or ($iR==82) or ($iR==86) or ($iR==108) or ($iR==112) or ($iR==134) or ($iR==138)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 30) and ($iC <= 34)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 82) and ($iC <= 86)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 134) and ($iC <= 138)) or (($iC >= 160) and ($iC <= 164)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 39) {
        if($iR==162){
            return (($iC == 0) or ($iC == 2) or ($iC == 4))? 1 : 0;
        }
        elsif($iR==0){
            return (($iC == 162))? 1 : 0;
        }
        elsif($iR==163){
            return ((($iC >= 3) and ($iC <= 4)))? 1 : 0;
        }
        elsif($iR==3){
            return (($iC == 163))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 24) or ($iC == 28) or ($iC == 52) or ($iC == 56) or ($iC == 80) or ($iC == 84) or ($iC == 108) or ($iC == 112) or ($iC == 136) or ($iC == 140) or ($iC == 164))? 1 : 0;
        }
        elsif($iR==164){
            return (($iC == 2) or (($iC >= 4) and ($iC <= 5)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 136) and ($iC <= 140)))? 1 : 0;
        }
        elsif($iR==2){
            return (($iC == 162) or ($iC == 164))? 1 : 0;
        }
        elsif($iR==166){
            return (($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 80) or ($iC == 82) or ($iC == 84) or ($iC == 108) or ($iC == 110) or ($iC == 112) or ($iC == 136) or ($iC == 138) or ($iC == 140))? 1 : 0;
        }
        elsif($iR==4){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 136) and ($iC <= 140)) or (($iC >= 162) and ($iC <= 164)))? 1 : 0;
        }
        elsif(($iR==8) or ($iR==168)){
            return ((($iC >= 24) and ($iC <= 28)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 136) and ($iC <= 140)))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==165) or ($iR==167)){
            return (($iC == 24) or ($iC == 28) or ($iC == 52) or ($iC == 56) or ($iC == 80) or ($iC == 84) or ($iC == 108) or ($iC == 112) or ($iC == 136) or ($iC == 140))? 1 : 0;
        }
        elsif(($iR==26) or ($iR==54) or ($iR==82) or ($iR==110) or ($iR==138)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 26) or ($iC == 28) or ($iC == 52) or ($iC == 54) or ($iC == 56) or ($iC == 80) or ($iC == 82) or ($iC == 84) or ($iC == 108) or ($iC == 110) or ($iC == 112) or ($iC == 136) or ($iC == 138) or ($iC == 140) or ($iC == 164) or ($iC == 166) or ($iC == 168))? 1 : 0;
        }
        elsif(($iR==25) or ($iR==27) or ($iR==53) or ($iR==55) or ($iR==81) or ($iR==83) or ($iR==109) or ($iR==111) or ($iR==137) or ($iR==139)){
            return (($iC == 4) or ($iC == 8) or ($iC == 24) or ($iC == 28) or ($iC == 52) or ($iC == 56) or ($iC == 80) or ($iC == 84) or ($iC == 108) or ($iC == 112) or ($iC == 136) or ($iC == 140) or ($iC == 164) or ($iC == 168))? 1 : 0;
        }
        elsif(($iR==24) or ($iR==28) or ($iR==52) or ($iR==56) or ($iR==80) or ($iR==84) or ($iR==108) or ($iR==112) or ($iR==136) or ($iR==140)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 24) and ($iC <= 28)) or (($iC >= 52) and ($iC <= 56)) or (($iC >= 80) and ($iC <= 84)) or (($iC >= 108) and ($iC <= 112)) or (($iC >= 136) and ($iC <= 140)) or (($iC >= 164) and ($iC <= 168)))? 1 : 0;
        }
        return 0;
    }
    elsif($iV == 40) {
        if($iR==1){
            return (($iC == 166) or ($iC == 168))? 1 : 0;
        }
        elsif($iR==5){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116) or ($iC == 140) or ($iC == 144) or ($iC == 166) or ($iC == 168))? 1 : 0;
        }
        elsif($iR==3){
            return ((($iC >= 167) and ($iC <= 168)))? 1 : 0;
        }
        elsif($iR==168){
            return (($iC == 1) or ($iC == 3) or ($iC == 5) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)) or (($iC >= 140) and ($iC <= 144)))? 1 : 0;
        }
        elsif($iR==167){
            return (($iC == 3))? 1 : 0;
        }
        elsif($iR==166){
            return ((($iC >= 0) and ($iC <= 2)) or ($iC == 5))? 1 : 0;
        }
        elsif($iR==170){
            return (($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 112) or ($iC == 114) or ($iC == 116) or ($iC == 140) or ($iC == 142) or ($iC == 144))? 1 : 0;
        }
        elsif(($iR==0) or ($iR==2)){
            return (($iC == 166))? 1 : 0;
        }
        elsif(($iR==7) or ($iR==169) or ($iR==171)){
            return (($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116) or ($iC == 140) or ($iC == 144))? 1 : 0;
        }
        elsif(($iR==4) or ($iR==8) or ($iR==172)){
            return ((($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)) or (($iC >= 140) and ($iC <= 144)))? 1 : 0;
        }
        elsif(($iR==30) or ($iR==58) or ($iR==86) or ($iR==114) or ($iR==142)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 30) or ($iC == 32) or ($iC == 56) or ($iC == 58) or ($iC == 60) or ($iC == 84) or ($iC == 86) or ($iC == 88) or ($iC == 112) or ($iC == 114) or ($iC == 116) or ($iC == 140) or ($iC == 142) or ($iC == 144) or ($iC == 168) or ($iC == 170) or ($iC == 172))? 1 : 0;
        }
        elsif(($iR==28) or ($iR==32) or ($iR==56) or ($iR==60) or ($iR==84) or ($iR==88) or ($iR==112) or ($iR==116) or ($iR==140) or ($iR==144)){
            return ((($iC >= 4) and ($iC <= 5)) or (($iC >= 7) and ($iC <= 8)) or (($iC >= 28) and ($iC <= 32)) or (($iC >= 56) and ($iC <= 60)) or (($iC >= 84) and ($iC <= 88)) or (($iC >= 112) and ($iC <= 116)) or (($iC >= 140) and ($iC <= 144)) or (($iC >= 168) and ($iC <= 172)))? 1 : 0;
        }
        elsif(($iR==29) or ($iR==31) or ($iR==57) or ($iR==59) or ($iR==85) or ($iR==87) or ($iR==113) or ($iR==115) or ($iR==141) or ($iR==143)){
            return (($iC == 4) or ($iC == 8) or ($iC == 28) or ($iC == 32) or ($iC == 56) or ($iC == 60) or ($iC == 84) or ($iC == 88) or ($iC == 112) or ($iC == 116) or ($iC == 140) or ($iC == 144) or ($iC == 168) or ($iC == 172))? 1 : 0;
        }
        return 0;
    }
}
1;
__END__

=head1 NAME

GD::Barcode::QRcode - Create QRcode barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::QRcode;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::QRcode->new('1234567')->plot->png;

I<with UnitSize, ECC settings>

  my $oGdBar = GD::Barcode::QRcode->new('123456789', 
                            { Ecc => 'L', Version=>2, ModuleSize => 2}
                        );


=head1 DESCRIPTION

GD::Barcode::QRcode is a subclass of GD::Barcode and allows you to
create QRcode barcode image with GD.
This module based on "QRcode image CGI version 0.50 (C)2000-2002,Y.Swetake".

=head2 new

I<$oGdBar> = GD::Barcode::QRcode->new(I<$sTxt>, 
                    { Ecc => I<Ecc Mode>,
                      Version => I<Version>,
                      ModuleSize => I<Size of 1 modlue>,
                    });

Constructor. Creates a GD::Barcode::QRcode object for I<$sTxt>.

Parameters:

=over 4

=item Ecc

Ecc mode. Select 'M', 'L', 'H' or 'Q' (Default = 'M').

=item Version

Version ie. size of barcode image (Default = auto select).

=item ModuleSize

Size of modules(barcode unit)  (Default = 1).

=back

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::QRcode->new('1234567');
  my $oGD = $oGdB->plot();
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1' and '0'. 
'1' means black, '0' means white.

 ex.
  my $oGdB = GD::Barcode::QRcode->new('1234567');
  my $sPtn = $oGdB->barcode();

=head2 $errStr

$GD::Barcode::QRcode::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 AUTHOR

Kawai Takanori GCD00051@nifty.ne.jp

=head1 COPYRIGHT

The GD::Barocde::QRcode module is Copyright (c) 2003 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut
