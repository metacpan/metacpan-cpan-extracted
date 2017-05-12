# IUP::Tree example (animals) - using helper methods e.g. TreeAddNodes()
#
# Creates a tree with some branches and leaves. Uses a Lua Table to define the IUP::Tree structure.

use strict;
use warnings;

use IUP ':all';

my $t_singleroot = {
  TITLE=>"Animals", child=>[
    "0.Extra",
    { TITLE=>"1.Mammals",     child=>["Horse",  "Whale"] },
    "2.Extra",
    { TITLE=>"3.Crustaceans", child=>["Shrimp", "Lobster"] },
    "4.Extra",
  ],
};

my $t_rootless = [
    "0.Extra",
    { TITLE=>"1.Mammals",     child=>["Horse",  "Whale"] },
    { TITLE=>"2.Crustaceans", child=>["Shrimp", "Lobster"] },
    "3.Extra",
    "4.Extra",
    { TITLE=>"5.Extra", child=>["Dog", "Cat"] },
];

my $t_folders = [
  { TITLE=>"A", child=>["A1", "A2"] },
  { TITLE=>"B", child=>["B1", "B2"] },
];

my $tree_tleft = IUP::Tree->new();
my $tree_tright = IUP::Tree->new();
my $tree_bleft = IUP::Tree->new( ADDROOT=>'NO' );
my $tree_bright = IUP::Tree->new( ADDROOT=>'NO' );

my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new([
                              IUP::Hbox->new([$tree_tleft,$tree_tright]), 
                              IUP::Hbox->new([$tree_bleft,$tree_bright]), 
                            ]), TITLE=>"IUP::Tree Animals", SIZE=>"600x300" );

$dlg->ShowXY(IUP_CENTER,IUP_CENTER);

#NOTE: all tree->SetAttribute(...) has to go after dialog->Show() or after dialog->Map()

warn "Creating [top-left] rootless tree\n";
$tree_tleft->TreeAddNodes($t_rootless,-1);
$tree_tleft->TreeAddNodes({ TITLE=>"5.1.Extra", child=>["51"] },9);
warn "Creating [top-right] singleroot tree\n";
$tree_tright->TreeAddNodes($t_singleroot,-1);
warn "Creating [bottom-left] rootless tree\n";
$tree_bleft->TreeAddNodes($t_rootless,-1);
$tree_bleft->TreeInsertNodes({ TITLE=>"6.Extra", child=>["6"] },9);
warn "Creating [bottom-right] singleroot tree\n";
$tree_bright->TreeAddNodes($t_singleroot,-1);

IUP->MainLoop();
