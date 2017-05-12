# IUP::Image example
#
# Creates a button, a label, a toggle and a radio using an image.
# Uses an image for the cursor as well.

use strict;
use warnings;

use IUP ':all';

my $edit1 = IUP::Text->new( MULTILINE=>1, EXPAND=>"YES", VALUE=>"Number 1" );
my $edit2 = IUP::Text->new( MULTILINE=>1, EXPAND=>"YES", VALUE=>"Number 2" );

my $box = IUP::Hbox->new( child=>[
                            IUP::Frame->new( child=>$edit1, TITLE=>"First" ), 
                            IUP::Frame->new( child=>$edit2, TITLE=>"Second" )
                          ],
                          GAP=>5,
                          MARGIN=>"5x5" );

my $dlg = IUP::Dialog->new( child=>$box, TITLE=>"Frames!", SIZE=>"QUARTERxQUARTER" );

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
