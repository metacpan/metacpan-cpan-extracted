# IUP::Sbox example

use strict;
use warnings;

use IUP ':all';

my $bt = IUP::Button->new( TITLE=>"Button", EXPAND=>"YES");

my $bx = IUP::Sbox->new( child=>$bt, DIRECTION=>"SOUTH", COLOR=>"0 255 0" );

my $ml = IUP::Text->new( MULTILINE=>"YES", EXPAND=>"YES", VISIBLELINES=>5 );

my $vb = IUP::Vbox->new( child=>[$bx, $ml] );

my $lb = IUP::Label->new( TITLE=>"Label", EXPAND=>"VERTICAL" );

my $dg = IUP::Dialog->new( child=>IUP::Hbox->new( child=>[$vb, $lb] ), 
                           TITLE=>"IUP::Sbox Example", 
                           MARGIN=>"10x10", 
                           GAP=>10 );
$dg->Show();

IUP->MainLoop();

