# IUP::Tabs example 

use strict;
use warnings;

use IUP ':all';

# Creates boxes;
my $vboxA = IUP::Vbox->new( child=>[
              IUP::Label->new( TITLE=>"Inside Tab A" ),
              IUP::Button->new( TITLE=>"Button A" )
            ], TABTITLE=>"Tab A" );

my $vboxB = IUP::Vbox->new( child=>[
              IUP::Label->new( TITLE=>"Inside Tab B" ),
              IUP::Button->new( TITLE=>"Button B" )
            ], TABTITLE=>"Tab B" );

my $vboxC = IUP::Vbox->new( child=>[
              IUP::Label->new( TITLE=>"Inside Tab C" ),
              IUP::Button->new( TITLE=>"Button C" )
            ], TABTITLE=>"Tab C" );

my $vboxD = IUP::Vbox->new( child=>[
              IUP::Label->new( TITLE=>"Inside Tab D" ),
              IUP::Button->new( TITLE=>"Button D" )
            ], TABTITLE=>"Tab D" );

# Creates tabs;
my $tabs1 = IUP::Tabs->new( child=>[$vboxA, $vboxB] );
my $tabs2 = IUP::Tabs->new( child=>[$vboxC, $vboxD], TABTYPE=>"LEFT" );

# Creates dialog;
my $box = IUP::Hbox->new( child=>[$tabs1, $tabs2], MARGIN=>"10x10", GAP=>10);
my $dlg = IUP::Dialog->new( child=>$box, TITLE=>"Test IUP::Tabs", SIZE=>"200x80");

# Shows dialog in the center of the screen;
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
