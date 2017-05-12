# IUP::Vbox example
#
# Creates a dialog with buttons placed one above the other, showing
# the organization possibilities of the elements inside a vbox.
# The ALIGNMENT attribute is explored in all its possibilities to obtain
# the effects. The attributes GAP, MARGIN and SIZE are also tested.

use strict;
use warnings;

use IUP ':all';

# Creates frame 1;
my $frm_1 = IUP::Frame->new( TITLE=>"ALIGNMENT=ALEFT, GAP=10", child=>
              IUP::Hbox->new( child=>[
                IUP::Fill->new(),
                IUP::Vbox->new( ALIGNMENT=>"ALEFT", GAP=>10, child=>[
                  IUP::Button->new(TITLE=>"1", SIZE=>"20x30", ACTION=>""),
                  IUP::Button->new(TITLE=>"2", SIZE=>"30x30", ACTION=>""),
                  IUP::Button->new(TITLE=>"3", SIZE=>"40x30", ACTION=>""),
                ] ),
                IUP::Fill->new(),
              ] )
            );

# Creates frame 2;
my $frm_2 = IUP::Frame->new( TITLE=>"ALIGNMENT=ACENTER", child=>
              IUP::Hbox->new( child=>[
                IUP::Fill->new(),
                IUP::Vbox->new( ALIGNMENT=>"ACENTER", child=>[
                  IUP::Button->new(TITLE=>"1", SIZE=>"20x30", ACTION=>""),
                  IUP::Button->new(TITLE=>"2", SIZE=>"30x30", ACTION=>""),
                  IUP::Button->new(TITLE=>"3", SIZE=>"40x30", ACTION=>""),
                ] ),
                IUP::Fill->new(),
              ] )
            );

# Creates frame 3;
my $frm_3 = IUP::Frame->new( TITLE=>"ALIGNMENT=ARIGHT", child=>
              IUP::Hbox->new( child=>[
                IUP::Fill->new(),
                IUP::Vbox->new( ALIGNMENT=>"ARIGHT", child=>[
                  IUP::Button->new(TITLE=>"1", SIZE=>"20x30", ACTION=>""),
                  IUP::Button->new(TITLE=>"2", SIZE=>"30x30", ACTION=>""),
                  IUP::Button->new(TITLE=>"3", SIZE=>"40x30", ACTION=>""),
                ] ),
                IUP::Fill->new(),
              ] )
            );

my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( child=>[$frm_1, $frm_2, $frm_3] ), TITLE=>"IUP::Vbox Example", SIZE=>"250x" );

# Shows dialog in the center of the screen
$dlg->ShowXY (IUP_CENTER, IUP_CENTER);

IUP->MainLoop;