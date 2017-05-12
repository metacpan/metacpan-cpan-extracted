# IUP::Matrix example

use strict;
use warnings;

use IUP ':all';

my $mat = IUP::Matrix->new( NUMCOL=>5, NUMCOL_VISIBLE=>2, NUMLIN=>3, NUMLIN_VISIBLE=>3, WIDTHDEF=>60, RESIZEMATRIX=>"YES" );

$mat->MatCell(0,0,"Inflation");
$mat->MatCell(1,0,"Medicine");
$mat->MatCell(2,0,"Food");
$mat->MatCell(3,0,"Energy");
$mat->MatCell(0,1,"January 2000");
$mat->MatCell(1,1,"5.6");
$mat->MatCell(2,1,"2.2");
$mat->MatCell(3,1,"7.2");
$mat->MatCell(0,2,"February 2000");
$mat->MatCell(1,2,"4.6");
$mat->MatCell(2,2,"1.3");
$mat->MatCell(3,2,"1.4");

$mat->MatAttribute("BGCOLOR", 2, 2, "200 0 0");

my $dlg = IUP::Dialog->new( TITLE=>'IUP::Matrix Example', child=>IUP::Vbox->new( child=>$mat, MARGIN=>"10x10") );
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
