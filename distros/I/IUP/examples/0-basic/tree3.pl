# IUP::Tree example (figures) - using attribute only interface

use strict;
use warnings;

use IUP ':all';

my $tree = IUP::Tree->new( ADDROOT=>'NO' );

$tree->RIGHTCLICK_CB( sub { print STDERR "RIGHTCLICK_CB\n" } );

$tree->RENAME_CB( sub { print STDERR "RENAME_CB\n" } );

$tree->K_ANY( sub {
  my ($self, $c) = @_;
  $tree->SetAttribute("DELNODE", "MARKED") if ( $c == K_DEL );
} );

sub init_tree_nodes {  
  #xxxCHECKLATER broken due to iup bug
  $tree->SetAttribute('ADDLEAF-1', 'item 3');
  $tree->SetAttribute('ADDLEAF-1', 'item 2');
  $tree->SetAttribute('ADDLEAF-1', 'item 1');
  $tree->SetAttribute('ADDLEAF-1', 'item 0');
  $tree->SetAttribute('ADDLEAF2', 'between 2-3');  
}

my $dlg = IUP::Dialog->new( child=>$tree, TITLE=>"IUP::Tree Demo", SIZE=>"QUARTERxTHIRD" );
$tree->SetAttribute( MARKMODE=>"MULTIPLE", ADDEXPANDED=>"NO", SHOWRENAME=>"YES" );
$dlg->ShowXY(IUP_CENTER,IUP_CENTER);

#NOTE: all tree->SetAttribute(...) has to go after dialog->Show() or after dialog->Map()
init_tree_nodes();

IUP->MainLoop;
