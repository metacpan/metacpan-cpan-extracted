# IUP::Expander example

use strict;
use warnings;

use IUP ':all';

my $bt1  = IUP::Button->new(TITLE=>"Button ONE");
my $bt2  = IUP::Button->new(TITLE=>"Button TWO");
my $exp  = IUP::Expander->new(child=>$bt1, TITLE=>"IupExpander Title");
my $vbox = IUP::Vbox->new(child=>[$exp, $bt2], MARGIN=>"10x10", GAP=>"10");

# Shows dialog in the center of the screen
my $dlg  = IUP::Dialog->new( child=>$vbox, TITLE=>"IUP::Expander Example", SIZE=>"250x" );
$dlg->ShowXY (IUP_CENTER, IUP_CENTER);
IUP->MainLoop;