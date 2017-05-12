# IUP::Matrix + MASK example

use strict;
use warnings;

use IUP ':all';

my $mat = IUP::Matrix->new( NUMLIN=>3, NUMCOL=>3 );
$mat->MatCell(1, 1, "Only numbers");

for my $i (1..3) {
  for my $j (1..3) {
    $mat->SetAttributeId2("MASK", $i, $j, '/d+'); # xxxTODO does not work well - ASK    
  }
}

my $dg = IUP::Dialog->new( child=>$mat, TITLE=>"IUP::Matrix + MASK Example" );

$dg->Show();

IUP->MainLoop;
