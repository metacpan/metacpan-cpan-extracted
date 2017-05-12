# IUP::Sbox example

use strict;
use warnings;

use IUP ':all';

sub create_tree_nodes {
  my $t = shift;    
  $t->SetAttribute( NAME=>"Figures",
                    ADDBRANCH=>"3D",
                    ADDBRANCH=>"2D",
                    ADDLEAF1=>"trapeze",
                    ADDBRANCH1=>"parallelogram",
                    ADDLEAF2=>"diamond",
                    ADDLEAF2=>"square",
                    ADDBRANCH1=>"triangle",
                    ADDLEAF2=>"scalenus",
                    ADDLEAF2=>"isoceles",
                    ADDLEAF2=>"equilateral",
                    VALUE=>6,
                    ADDEXPANDED=>"NO" );
}

my $tree = IUP::Tree->new( SIZE=>"120x100", EXPAND=>"YES" );

my $sbox1 = IUP::Sbox->new( child=>$tree, DIRECTION=>"EAST" );

my $cv = IUP::Canvas->new( EXPAND=>"YES" );

my $ml = IUP::Text->new( MULTILINE=>"YES", EXPAND=>"YES" );

my $sbox2 = IUP::Sbox->new( child=>$ml, DIRECTION=>"WEST" );

my $box = IUP::Hbox->new( [$sbox1, $cv, $sbox2] );

my $lb = IUP::Label->new( TITLE=>"This is a label", EXPAND=>"NO" );

my $sbox3 = IUP::Sbox->new( child=>$lb, DIRECTION=>"NORTH" );

my $dg = IUP::Dialog->new( child=>IUP::Vbox->new([$box, $sbox3]), TITLE=>"IUP::Sbox Example" );

$dg->Show();
create_tree_nodes($tree);

IUP->MainLoop();
