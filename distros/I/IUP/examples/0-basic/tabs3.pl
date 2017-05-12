# IUP::Tabs example 

use strict;
use warnings;

use IUP ':all';

# Creates boxes;
my $vboxA = IUP::Vbox->new( child=>[
              IUP::Fill->new(),
              IUP::Label->new( TITLE=>"TABS AAA", EXPAND=>"HORIZONTAL" ),
              IUP::Button->new( TITLE=>"AAA")
            ], TABTITLE=>"AAAAAA" );
my $vboxB = IUP::Vbox->new( child=>[
              IUP::Label->new( TITLE=>"TABS BBB" ),
              IUP::Button->new( TITLE=>"BBB" )
            ], TABTITLE=>"BBBBBB" );

# Creates tabs;
my $tabs = IUP::Tabs->new( child=>[$vboxA, $vboxB] );

# Creates dialog;
my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( child=>$tabs ), MARGIN=>"10x10", TITLE=>"Test IUP::Tabs", SIZE=>"150x80");

# Shows dialog in the center of the screen;
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
