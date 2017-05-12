package IUP::Tree;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

use Scalar::Util 'refaddr'; # http://stackoverflow.com/questions/4064001/how-should-i-compare-perl-references
use Carp;

sub _create_element {
  #my ($self, $args, $firstonly) = @_;
  return IUP::Internal::LibraryIup::_IupTree();
}

sub TreeSetUserId {
  #int IupTreeSetUserId(Ihandle *ih, int id, void *userid); [in C]
  #iup.TreeSetUserId(ih: ihandle, id: number, userid: userdata/table) [in Lua]  
  my ($self, $id, $userdata) = @_;
  my $pointer = IUP::Internal::LibraryIup::_IupTreeGetUserId($self->ihandle, $id);
  if (!defined($userdata)) {
    delete $self->{'!int!treedata'}->{$pointer} if $pointer; #delete the old data
  }
  elsif (ref($userdata)) {
    delete $self->{'!int!treedata'}->{$pointer} if $pointer; #delete the old data
    $pointer = refaddr($userdata);
    $self->{'!int!treedata'}->{$pointer} = $userdata;
    IUP::Internal::LibraryIup::_IupTreeSetUserId($self->ihandle, $id, $pointer);
  }
  else {
    carp "[Warning] 'userdata' parameter must be a reference";
  }
}

sub TreeGetUserId {
  #int IupTreeGetId(Ihandle* ih, void *userid);
  #iup.TreeGetUserId(ih: ihandle, id: number) -> (ret: userdata/table) [in Lua]
  my ($self, $id) = @_;
  my $pointer = IUP::Internal::LibraryIup::_IupTreeGetUserId($self->ihandle, $id);  
  return undef unless defined $self->{'!int!treedata'};
  return $self->{'!int!treedata'}->{$pointer};
}

sub TreeGetId {
  #int IupTreeGetId(Ihandle *ih, void *userid); [in C] 
  #iup.TreeGetId(ih: ihandle, userid: userdata/table) -> (ret: number) [in Lua]
  my ($self, $userdata) = @_;
  my $pointer = refaddr($userdata);
  return IUP::Internal::LibraryIup::_IupTreeGetId($self->ihandle, $pointer);
}

sub TreeSetAncestorsAttributes {
  my ($self, $ini, $attrs) = @_;
  #iup.TreeSetAncestorsAttributes(ih: ihandle, id: number, attrs: table) [in Lua]
  $ini = $self->GetAttributeId("PARENT",$ini);
  my @stack = ();  
  while (defined $ini) {
    push @stack, $ini;
    $ini = $self->GetAttributeId("PARENT",$ini);
  }
  $self->TreeSetNodeAttributes($_, $attrs) for (@stack);
}

sub TreeSetDescentsAttributes {
  my ($self, $ini, $attrs) = @_;
  #iup.TreeSetDescentsAttributes(ih: ihandle, id: number, attrs: table) [in Lua] 
  my $id = $ini;
  my $count = $self->GetAttributeId("CHILDCOUNT",$ini);
  for(my $i=0; $i<$count; $i++) {
    $id++;
    $self->TreeSetNodeAttributes($id, $attrs);
    if ($self->GetAttributeId("KIND", $id) eq "BRANCH") {
      $id = $self->TreeSetDescentsAttributes($id, $attrs);
    }
  }
  return $id;
}

sub TreeSetNodeAttributes {  
  my ($self, $id, $attrhash) = @_;
  while (my ($attr, $val) = each %$attrhash) {
    next unless $attr =~ /^[A-Z_0-9]+$/;    
    next if $attr =~ /^(KIND|PARENT|DEPTH|CHILDCOUNT|TOTALCHILDCOUNT)$/; #skip read only attributes
    if ($attr eq 'USERDATA') {
      $self->TreeSetUserId($id, $val); #special handling of USERDATA
    }
    else {
      $self->SetAttributeId($attr, $id, $val);
    }
  }
}

sub TreeAddNodes {
  my ($self, $t, $id) = @_;  
  return unless defined $t;
  $id = -1 unless defined $id;
  $self->_delete_root_if_empty if ($id == -1);
  if (ref($t) eq 'ARRAY') {
    $self->_proc_node_definition($_, $id, 'add') for (reverse @$t);
  }
  else {
    $self->_proc_node_definition($t, $id, 'add');
  }
}

sub TreeInsertNodes {
  my ($self, $t, $id) = @_;  
  return unless defined $t;
  $id = -1 unless defined $id;
  $self->_delete_root_if_empty if ($id == -1); # xxxCHECKLATER not sure if it is a good idea
  if (ref($t) eq 'ARRAY') {
    $self->_proc_node_definition($_, $id, 'ins') for (reverse @$t);
  }
  else {
    $self->_proc_node_definition($t, $id, 'ins');
  }
}

sub _delete_root_if_empty {
  my $self = shift;
  my $tc = $self->GetAttribute("TOTALCHILDCOUNT0");
  my $ti = $self->GetAttribute("TITLE0");  
  #workaround for handling ADDROOT='YES' but empty TITLE
  if (defined $tc && $tc==0 && defined $ti && $ti eq '') {
    #the tree is empty, but was created with ADDROOT='YES' - therefore deleting node 0     
    $self->SetAttributeId('DELNODE', 0, 'SELECTED'); 
  }
}

sub _proc_node_definition { 
  my ($self, $h, $id, $ins_or_add) = @_;
  #NOTE: $h is expected to be a hashref or scalar value (not arrayref!)
  return unless defined $h;
  $h = { TITLE=>"$h", KIND=>'LEAF' } if ref($h) ne 'HASH'; #autoconvert any scalar value into leaf title
  if ( ($h->{KIND} && $h->{KIND} eq 'BRANCH') || $h->{child} ) {
    #add branch
    if (defined $ins_or_add && $ins_or_add eq 'ins') {
      $self->SetAttributeId("INSERTBRANCH", $id, $h->{TITLE});
    }
    else {
      $self->SetAttributeId("ADDBRANCH", $id, $h->{TITLE});        
    }    
    
    my $newid = $self->LASTADDNODE;
    $self->TreeSetNodeAttributes($newid, $h);
    
    my $ch = $h->{child};
    if (defined $ch) {      
      if (ref($ch) eq 'ARRAY') {
        $self->_proc_node_definition($_, $newid) for (reverse @$ch);
      }
      else {
        $self->_proc_node_definition($ch, $newid);
      }
    }
  }
  else {
    #add leaf
    if (defined $ins_or_add && $ins_or_add eq 'ins') {
      $self->SetAttributeId("INSERTLEAF", $id, $h->{TITLE});
    }
    else {
      $self->SetAttributeId("ADDLEAF", $id, $h->{TITLE});
    }    

    my $newid = $self->LASTADDNODE;
    $self->TreeSetNodeAttributes($newid, $h);
  }
}

1;
