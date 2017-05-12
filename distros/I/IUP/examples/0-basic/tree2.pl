# IUP::Tree example (figures) - using attribute only interface
#
# Creates a tree with some branches and leaves.
# Two callbacks are registered: one deletes marked nodes when the Del key
# is pressed, and the other, called when the right mouse button is pressed,
# opens a menu with options.

use strict;
use warnings;

use IUP ':all';

my $tree = IUP::Tree->new( );

$tree->RIGHTCLICK_CB( sub { print STDERR "RIGHTCLICK_CB\n" } );

$tree->RENAME_CB( sub { print STDERR "RENAME_CB\n" } );

$tree->MULTISELECTION_CB( sub { 
  my ($self, $ids, $n) = @_;
  print STDERR "MULTISELECTION_CB ids.count=",join('-',@$ids)," n=$n\n" 
} );

$tree->NODEREMOVED_CB( sub { 
  my ($self, $data) = @_;
  print STDERR "NODEREMOVED_CB data.ref=",ref($data)," data.x=",$data->{x},"\n" 
} );

$tree->K_ANY( sub {
  my ($self, $c) = @_;
  $tree->SetAttribute("DELNODE", "MARKED") if ( $c == K_DEL );
} );

my $userdata = [
  { x => "test0" },
  { x => "test1" },
  { x => "test2" },
  { x => "test3" },
  { x => "test4" },
  { x => "test5" },
  { x => "test6" },
  { x => "test7" },
  { x => "test8" },
  { x => "test9" },
  { x => "test10" },
  { x => "test11" },
];

sub init_tree_nodes {
  $tree->SetAttribute( "TITLE0", "Figures" ); 
  $tree->SetAttribute( "ADDBRANCH0", "3D" );
  $tree->SetAttribute( "ADDBRANCH0", "2D" );
  $tree->SetAttribute( "ADDBRANCH1", "parallelogram" );
  $tree->SetAttribute( "ADDLEAF2", "diamond" );
  $tree->SetAttribute( "ADDLEAF2", "square" );
  $tree->SetAttribute( "ADDBRANCH1", "triangle" );
  $tree->SetAttribute( "ADDLEAF2", "scalenus" );
  $tree->SetAttribute( "ADDLEAF2", "isoceles" );
  $tree->SetAttribute( "ADDLEAF2", "equilateral" );
  $tree->SetAttribute( "ADDLEAF2", "other" );
  $tree->SetAttribute( "VALUE", "6" ); #xxxCHECKLATER why is this line so crutial?
  $tree->TreeSetUserId($_, $userdata->[$_]) for (0..11);
}

my $dlg = IUP::Dialog->new( child=>$tree, TITLE=>"IUP::Tree Demo", SIZE=>"QUARTERxTHIRD" );
$tree->SetAttribute( MARKMODE=>"MULTIPLE", ADDEXPANDED=>"NO", SHOWRENAME=>"YES" );
$dlg->ShowXY(IUP_CENTER,IUP_CENTER);

#NOTE: all tree->SetAttribute(...) has to go after dialog->Show() or after dialog->Map()
init_tree_nodes();

IUP->MainLoop;
