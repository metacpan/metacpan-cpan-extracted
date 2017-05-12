# IUP::GridBox example

use strict;
use warnings;

use IUP ':all';

my $gbox = IUP::GridBox->new(SIZECOL=>2, SIZELIN=>3, NUMDIV=>3, ALIGNMENTLIN=>"ACENTER", MARGIN=>"10x10", GAPLIN=>5, GAPCOL=>5, child=>[
      #line 0 (header)
      IUP::Label->new(),
      IUP::Label->new(TITLE=>"col1", FONTSTYLE=>"Bold"),
      IUP::Label->new(TITLE=>"col2", FONTSTYLE=>"Bold"),
      #line 1
      IUP::Label->new(TITLE=>"lin1", FONTSTYLE=>"Bold"),
      IUP::Label->new(TITLE=>"lbl", XSIZE=>"50x12"),
      IUP::Button->new(TITLE=>"but", XSIZE=>50),
      #line 2
      IUP::Label->new(TITLE=>"lin2", FONTSTYLE=>"Bold"),
      IUP::Label->new(TITLE=>"label", XSIZE=>"x12"),
      IUP::Button->new(TITLE=>"button", XEXPAND=>"Horizontal"),
      #line 3
      IUP::Label->new(TITLE=>"lin3", FONTSTYLE=>"Bold"),
      IUP::Label->new(TITLE=>"label large", XSIZE=>"x12"),
      IUP::Button->new(TITLE=>"button large"),
]);

my $fr1 = IUP::Frame->new(child=>$gbox, MARGIN=>"0x0");

# Shows dialog in the center of the screen
my $dlg  = IUP::Dialog->new( child=>IUP::Hbox->new(child=>$fr1), TITLE=>"IUP::GridBox Example", MARGIN=>"10x10" );
$dlg->ShowXY (IUP_CENTER, IUP_CENTER);
IUP->MainLoop;