use strict;
use GD qw(:DEFAULT :cmp);
my $oOld = GD::Image->newFromPng('reschk.png');
my $oNew = GD::Image->newFromPng('qrc4.png');
printf "CMP              :%8b\n", $oOld->compare($oNew), "\n";
printf "GD_CMP_IMAGE     :%8b\n", GD_CMP_IMAGE;
printf "GD_CMP_NUM_COLORS:%8b\n", GD_CMP_NUM_COLORS;
printf "GD_CMP_COLOR     :%8b\n", GD_CMP_COLOR     ;
printf "GD_CMP_SIZE_X    :%8b\n", GD_CMP_SIZE_X    ;
printf "GD_CMP_SIZE_Y    :%8b\n", GD_CMP_SIZE_Y    ;
printf "GD_CMP_TRANSPAREN:%8b\n", GD_CMP_TRANSPARENT;
printf "GD_CMP_BACKGROUND:%8b\n", GD_CMP_BACKGROUND;
printf "GD_CMP_INTERLACE :%8b\n", GD_CMP_INTERLACE;
my($iOldX, $iOldY) = $oOld->getBounds();
my($iNewX, $iNewY) = $oNew->getBounds();
for(my $i=0;$i<$iOldX; ++$i) {
    for(my $j=0;$j<$iOldY; ++$j) {
        my $iOIdx = $oOld->getPixel($i, $j);
        my $sOS = join(',', $oOld->rgb($iOIdx));
        my $iNIdx = $oNew->getPixel($i, $j);
        my $sNS = join(',', $oNew->rgb($iNIdx));
        print "($i, $j) => $sNS , $sOS\n" if($sOS ne $sNS);
    }
}
__END__
print $oOld->compare($oNew);
my $cB = $oOld->colorAllocate(10,10,255);
$oOld->setPixel(0, 0, $cB);
print $oNew->compare($oOld);

