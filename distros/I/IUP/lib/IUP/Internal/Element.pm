package IUP::Internal::Element;

use strict;
use warnings;

use IUP::Internal::LibraryIup;
use IUP::Internal::Callback;
use IUP::Constants qw(IUP_CURRENT);
use Carp;
use Scalar::Util qw(blessed looks_like_number);

sub import {
  my $p = shift;
  #warn "### IUP::Internal::Element->import($p) called";

  # callback accessors
  if (my $c = IUP::Internal::Callback::_get_cb_eval_code($p)) {
    eval($c);
    die "###ERROR### import failed(cb) '$p': " . $@ if $@;
  }
}

sub AUTOLOAD {
  my ($name) = our $AUTOLOAD =~ /::(\w+)$/;
  die "FATAL: unknown method '$name'" unless $name =~ /^[A-Z0-9_]+$/;
  my $method = sub {
        return $_[0]->GetAttribute($name) if scalar(@_) == 1;
        return $_[0]->SetAttribute($name, $_[1]) if scalar(@_) > 1;
  };
  no strict 'refs';
  *{$AUTOLOAD} = $method;
  goto &$method;
}

sub BEGIN {
  #warn "***DEBUG*** IUP::Internal::Element::BEGIN() started\n";
  IUP::Internal::LibraryIup::_IupControlsOpen();
}

# constructor
sub new {
  my $class = shift;
  my $argc = scalar @_;
  my %args = ();
  my $firstonly;

  my $self = { class => $class };
  bless($self, $class);

  if ($argc == 1) {
    $firstonly = shift;
  }
  elsif ($argc > 1 && $argc % 2 == 0) {
    %args = @_;
  }
  elsif ($argc > 0) {
    carp "Warning: $class->new() odd number of arguments ($argc), ignoring all parameters";
  }

  $self->ihandle($self->_create_element(\%args, $firstonly));
  unless ($self->ihandle) {
    carp "Error: $class->new() failed";
    return;
  }

  if (!$self->HasValidClassName) {
    my $c = $self->GetClassName || '';
    carp "Warning: $class->new() classname mismatch '$class' vs. '$c'";
  }

  my @cb;
  my @at;
  while (@_) { # keep original order
    my $k = shift;
    my $v = shift;
    next unless defined $k;
    next unless exists $args{$k}; #some values may be deleted during _create_element()
    if ($self->IsValidCallbackName($k)) {
      push(@cb, $k, $v);
    }
    elsif ($k eq 'name') {
      $self->SetName($v);
    }
    elsif ($k eq uc($k)) {
      push(@at, $k, $v);  # assuming an attribute
    }
    else {
      carp "Warning: $class->new() ignoring unknown parameter '$k'";
    }
  }
  $self->SetCallback(@cb) if scalar(@cb);
  $self->SetAttribute(@at) if scalar(@at);
  return $self;
}

# constructor
sub new_no_ihandle {
  my $class = shift;
  my $self = { class => $class };
  bless($self, $class);
  return $self;
}

# constructor
sub new_from_ihandle {
  my ($class, $ih) = @_;
  my $self = { class => $class };
  bless($self, $class);
  $self->ihandle($ih);
  if (!$self->HasValidClassName) {
    my $c = $_[0]->GetClassName || '';
    carp "Warning: $class->new_from_ihandle() classname mismatch '$class' vs. '$c'";
  }
  return $self;
}

# accessor
sub ihandle {
  if ($_[1]) {
    IUP::Internal::LibraryIup::_register_ih($_[1], $_[0]);
    return $_[0]->{'!int!ihandle'} = $_[1]
  }
  else {
    return $_[0]->{'!int!ihandle'};
  }
}

sub GetName {
  #char* IupGetName(Ihandle* ih); [in C]
  #iup.GetName(ih: ihandle) -> (name: string) [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGetName($self->ihandle);
}

sub SetName {
  #Ihandle *IupSetHandle(const char *name, Ihandle *ih); [in C]
  #iup.SetHandle(name: string, ih: ihandle) -> old_ih: ihandle [in Lua]
  my ($self, $name) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupSetHandle($name, $self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub SetAttribute {
  #void IupSetAttribute(Ihandle *ih, const char *name, const char *value); [in C]
  #iup.SetAttribute(ih: iulua_tag, name: string, value: string) [in Lua]
  #void IupStoreAttribute(Ihandle *ih, const char *name, const char *value); [in C]
  #iup.StoreAttribute(ih: iulua_tag, name: string, value: string) [in Lua]
  my $self = shift;

  #BEWARE: we need to keep the order of attribute assignment - thus cannot use for (keys %args) {...}
  while(1) {
    my $k = shift;
    carp("Warning: invalid attribute name"), last unless defined $k;
    my $v = shift;
    if (!ref($v)) {
      IUP::Internal::LibraryIup::_IupStoreAttribute($self->ihandle, $k, $v);
    }
    elsif (blessed($v) && $v->can('ihandle')) {
      #carp "Debug: attribute '$k' is a refference '" . ref($v) . "'";
      IUP::Internal::LibraryIup::_IupSetAttributeHandle($self->ihandle, $k, $v->ihandle);
      #assuming any element ref stored into iup attribute to be a child
      unless($self->_get_child_ref($v)) {
        #XXX-FIXME - child element destruction: happens for: MENU, MDIMENU, IMAGE*, PARENTDIALOG (can cause memory leaks)
        #during Destroy() we might destroy elements shared by more dialogs
        #warn "***DEBUG*** Unexpected situation elem='".ref($self)."' attr='$k'";
        $self->_store_child_ref($v); #xxx(ANTI)DESTROY-MAGIC
      }
    }
    else {
      carp "[warning] cannot set attribute '$k' to '$v'";
    }
    last unless @_;
  }
  return $self;
}

sub SetAttributeId {
  #void IupSetAttributeId(Ihandle *ih, const char *name, int id, const char *value); [in C]
  #iup.SetAttributeId(ih: ihandle, name: string, id: number, value: string) [in Lua]
  #void IupStoreAttributeId(Ihandle *ih, const char *name, int id, const char *value); [in C]
  #iup.StoreAttributeId(ih: ihandle, name: string, id: number, value: string) [in Lua]
  my ($self, $name, $id, $v) = @_;
  IUP::Internal::LibraryIup::_IupStoreAttributeId($self->ihandle, $name, $id, $v);
  return $self;
}

sub SetAttributeId2 {
  #void  IupStoreAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);
  my ($self, $name, $lin, $col, $v) = @_;
  IUP::Internal::LibraryIup::_IupStoreAttributeId2($self->ihandle, $name, $lin, $col, $v);
  return $self;
}

sub GetAttribute {
  #Ihandle* IupGetAttributeHandle(Ihandle *ih, const char *name); [in C]
  #char *IupGetAttribute(Ihandle *ih, const char *name); [in C]
  #iup.GetAttribute(ih: ihandle, name: string) -> value: string [in Lua]
  my ($self, @names) = @_;
  my @rv = ();
  push(@rv, IUP::Internal::LibraryIup::_IupGetAttribute($self->ihandle, $_)) for (@names);
  return (scalar(@names) == 1) ? $rv[0] : @rv; #xxxCHECKLATER not sure if this is a good idea
}

sub GetAttributeAsElement {
  #special perl method
  #XXX-FIXME needs testin g
  my ($self, @names) = @_;
  my @rv = ();
  for (@names) {
    my $v = IUP::Internal::LibraryIup::_IupGetAttribute($self->ihandle, $_);
    push(@rv, defined $v ? IUP->GetByName($v) : undef);
  }
  return (scalar(@names) == 1) ? $rv[0] : @rv; #xxxCHECKLATER not sure if this is a good idea
}

sub GetAttributeId {
  #char *IupGetAttributeId(Ihandle *ih, const char *name, int id); [in C]
  #iup.GetAttributeId(ih: ihandle, name: string, id: number) -> value: string [in Lua]
  my ($self, $name, @ids) = @_;
  my @rv = ();
  push(@rv, IUP::Internal::LibraryIup::_IupGetAttributeId($self->ihandle, $name, $_)) for (@ids);
  return (scalar(@ids) == 1) ? $rv[0] : @rv; #xxxCHECKLATER not sure if this is a good idea
}

sub GetAttributeId2 {
  #char* IupGetAttributeId2(Ihandle* ih, const char* name, int lin, int col);
  my ($self, $name, $lin, $col) = @_;
  return IUP::Internal::LibraryIup::_IupGetAttributeId2($self->ihandle, $name, $lin, $col);
}

sub SetCallback {
  my ($self, %args) = @_;
  for (keys %args) {
    my ($action, $func) = ($_, $args{$_});
    my $cb_init_func = IUP::Internal::Callback::_get_cb_init_function(ref($self), $action);
    if (ref($cb_init_func) eq 'CODE') {
      if (defined $func) {
        #set callback
        $self->{"!int!cb!$action!func"} = $func;
        $self->{"!int!cb!$action!related"}->{$self->ihandle} = $self; #intentional circular dependency #xxx(ANTI)DESTROY-MAGIC
        &$cb_init_func($self->ihandle);
      }
      else {
        #clear (unset) callback
        #warn("***DEBUG*** gonna unset callback '$action'\n");
        IUP::Internal::Callback::_clear_cb($self->ihandle,$action);
        for (keys %$self) {
          #clear all related values
          delete $self->{$_} if (/^!int!cb!\Q$action\E!/);
        }
      }
    }
    else {
      carp "Warning: ignoring unknown callback '$action' (".ref($self).")";
    }
  }
  return $self;
}

sub IsValidCallbackName {
  return IUP::Internal::Callback::_is_cb_valid(ref($_[0]), $_[1]);
}

sub HasValidClassName {
  my $p = lc(ref($_[0]));            #perl class name
  my $c = $_[0]->GetClassName || ''; #iup internal class name
  # we are using IUP::Image for all - image, imagergb, imagergba
  $c = 'image' if $c eq 'imagergb';
  $c = 'image' if $c eq 'imagergba';
  $c = 'canvasgl' if $c eq 'glcanvas';
  $p = 'iup::dialog' if ($p eq 'iup::layoutdialog') && ($c eq 'dialog'); #xxxCHECKLATER seems like a bug
  $p =~ s/^iup::gl::/gl/;
  $p =~ s/^iup:://;
  return $p eq $c ? 1 : 0;
}

sub Append {
  #Ihandle* IupAppend(Ihandle* ih, Ihandle* new_child); [in C]
  #iup.Append(ih, new_child: ihandle) -> (parent: ihandle) [in Lua]
  my ($self, $new_child) = @_;
  return unless ref $new_child;
  my $ih = IUP::Internal::LibraryIup::_IupAppend($self->ihandle, $new_child->ihandle);
  return IUP->GetByIhandle($ih);
}

sub ConvertXYToPos {
  #int IupConvertXYToPos(Ihandle *ih, int x, int y); [in C]
  #iup.ConvertXYToPos(ih: ihandle, x, y: number) -> (ret: number) [in Lua]
  #It can be used for IupText (returns a position in the string), IupList (returns an item) or IupTree (returns a node identifier).
  my ($self, $x, $y) = @_;
  return IUP::Internal::LibraryIup::_IupConvertXYToPos($self->ihandle, $x, $y);
}

sub Destroy {
  #void IupDestroy(Ihandle *ih); [in C]
  #iup.Destroy(ih: ihandle) [in Lua]
  my $self = shift;
  my $ih = $self->ihandle;

  #destroy all perl related stuff on element + its children
  $self->_internal_destroy();
  #BEWARE: at this point $self->ihandle is undef

  IUP::Internal::LibraryIup::_unregister_ih($ih); #xxxCHECKLATER not necessary if weaken refs stored in global register
  IUP::Internal::LibraryIup::_IupDestroy($ih);
  return $self;
}

sub Detach {
  #void IupDetach(Ihandle *child); [in C]
  #iup.Detach(child: ihandle) or child:detach() [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupDetach($self->ihandle);
  return $self;
}

sub GetAllAttributes {
  #int IupGetAllAttributes(Ihandle* ih, char** names, int max_n); [in C]
  #iup.GetAllAttributes(ih: ihandle, max_n: number) -> (names: table, n: number) [in Lua]
  my ($self, $max_n) = @_;
  return IUP::Internal::LibraryIup::_IupGetAllAttributes($self->ihandle, $max_n);
}

sub GetAttributes {
  #char* IupGetAttributes (Ihandle *ih); [in C]
  #iup.GetAttributes(ih: iulua_tag) -> (ret: string) [in Lua]
  #NOT USING original C API - different approach
  my $self = shift;
  my $result = { };
  $result->{$_} = $self->GetAttribute($_) for ($self->GetAllAttributes);
  return $result;
}

sub GetBrother {
  #Ihandle* IupGetBrother(Ihandle* ih); [in C]
  #iup.GetBrother(ih: ihandle) -> brother: ihandle [in Lua]
  my $self = shift;
  my $ih = IUP::Internal::LibraryIup::_IupGetBrother($self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub GetClassName {
  #char* IupGetClassName(Ihandle* ih); [in C]
  #iup.GetClassName(ih: ihandle) -> (name: string) [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGetClassName($self->ihandle);
}

sub GetClassType {
  #char* IupGetClassType(Ihandle* ih); [in C]
  #iup.GetClassType(ih: ihandle) -> (name: string) [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGetClassType($self->ihandle);
}

sub GetChildCount {
  #int IupGetChildCount(Ihandle* ih); [in C]
  #iup.GetChildCount(ih: ihandle) ->  pos: number [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGetChildCount($self->ihandle);
}

sub Map {
  #int IupMap(Ihandle* ih); [in C]
  #iup.Map(ih: iuplua-tag) -> ret: number [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupMap($self->ihandle);
}

sub Redraw {
  #void IupRedraw(Ihandle* ih, int children); [in C]
  #iup.Redraw(ih: ihandle, children: boolen) [in Lua]
  my ($self, $children) = @_;
  IUP::Internal::LibraryIup::_IupRedraw($self->ihandle, $children);
  return $self;
}

sub Refresh {
  #void IupRefresh(Ihandle *ih); [in C]
  #iup.Refresh(ih: ihandle) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupRefresh($self->ihandle);
  return $self;
}

sub RefreshChildren {
  #void IupRefreshChildren(Ihandle *ih); [in C]
  #iup.RefreshChildren(ih: ihandle) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupRefreshChildren($self->ihandle);
  return $self;
}

sub Reparent {
  #int IupReparent(Ihandle* ih, Ihandle* new_parent, Ihandle* ref_child);
  #iup.Reparent(child, parent: ihandle) [in Lua]
  my ($self, $new_parent, $ref_child) = @_;
  return IUP::Internal::LibraryIup::_IupReparent($self->ihandle, $new_parent->ihandle, $ref_child->ihandle);
}

sub ResetAttribute {
  #void IupResetAttribute(Ihandle *ih, const char *name); [in C]
  #iup.ResetAttribute(ih: iulua_tag, name: string) [in Lua]
  my ($self, $name) = @_;
  IUP::Internal::LibraryIup::_IupResetAttribute($self->ihandle, $name);
  return $self;
}

sub SaveClassAttributes {
  #void IupSaveClassAttributes(Ihandle* ih); [in C]
  #iup.SaveClassAttributes(ih: ihandle) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupSaveClassAttributes($self->ihandle);
  return $self;
}

sub SetFocus {
  #Ihandle *IupSetFocus(Ihandle *ih); [in C]
  #iup.SetFocus(ih: ihandle) -> ih: ihandle [in Lua]
  my $self = shift;
  my $ih = IUP::Internal::LibraryIup::_IupSetFocus($self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub Unmap {
  #void IupUnmap(Ihandle* ih); [in C]
  #iup.Unmap(ih: iuplua-tag) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupUnmap($self->ihandle);
  return $self;
}

sub Update {
  #void IupUpdate(Ihandle* ih); [in C]
  #iup.Update(ih: ihandle) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupUpdate($self->ihandle);
  return $self;
}

sub UpdateChildren {
  #void IupUpdateChildren(Ihandle* ih); [in C]
  #iup.UpdateChildren(ih: ihandle) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupUpdateChildren($self->ihandle);
  return $self;
}

sub Hide {
  #int IupHide(Ihandle *ih); [in C]
  #iup.Hide(ih: ihandle) -> (ret: number) [in Lua]
  my $self = shift;
  IUP::Internal::LibraryIup::_IupHide($self->ihandle);
  return $self;
}

sub Popup {
  #int IupPopup(Ihandle *ih, int x, int y); [in C]
  #iup.Popup(ih: ihandle[, x, y: number]) -> (ret: number) [in Lua]
  #or ih:popup([x, y: number]) -> (ret: number) [in Lua]
  my ($self, $x, $y) = @_;
  $x = IUP_CURRENT unless defined $x;
  $y = IUP_CURRENT unless defined $y;
  return IUP::Internal::LibraryIup::_IupPopup($self->ihandle, $x, $y);
}

sub Show {
  #int IupShow(Ihandle *ih); [in C]
  #iup.Show(ih: ihandle) -> (ret: number) [in Lua]
  #or ih:show() -> (ret: number) [in IupLua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupShow($self->ihandle);
}

sub ShowXY {
  #int IupShowXY(Ihandle *ih, int x, int y); [in C]
  #iup.ShowXY(ih: ihandle[, x, y: number]) -> (ret: number) [in Lua]
  #or ih:showxy([x, y: number]) -> (ret: number) [in Lua]
  my ($self, $x, $y) = @_;
  $x = IUP_CURRENT unless defined $x;
  $y = IUP_CURRENT unless defined $y;
  return IUP::Internal::LibraryIup::_IupShowXY($self->ihandle, $x, $y);
}

sub GetNextChild {
  #Ihandle *IupGetNextChild(Ihandle* ih, Ihandle* child); [in C]
  #iup.GetNextChild(ih, child: ihandle) -> next_child: ihandle [in Lua]
  my ($self, $child) = @_;
  my $ih;
  #xxxCHECKLATER check this - kind of a hack (now more or less works)
  if (defined $child) {
    $ih = IUP::Internal::LibraryIup::_IupGetNextChild($self->ihandle, $child->ihandle);
  }
  else {
    $ih = IUP::Internal::LibraryIup::_IupGetNextChild($self->ihandle, undef);
  }
  return IUP->GetByIhandle($ih);
}

sub PreviousField {
  #Ihandle* IupPreviousField(Ihandle* ih); [in C]
  #iup.PreviousField(ih: ihandle) -> (previous: ihandle) [in Lua]
  my $self = shift;
  my $ih = IUP::Internal::LibraryIup::_IupPreviousField($self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub GetChildPos {
  #int IupGetChildPos(Ihandle* ih, Ihandle* child); [in C]
  #iup.GetChildPos(ih, child: ihandle) ->  pos: number [in Lua]
  my ($self, $child) = @_;
  return IUP::Internal::LibraryIup::_IupGetChildPos($self->ihandle, $child->ihandle);
}

sub GetDialog {
  #Ihandle* IupGetDialog(Ihandle *ih); [in C]
  #iup.GetDialog(ih: ihandle) -> (ih: ihandle) [in Lua]
  my $self = shift;
  my $ih = IUP::Internal::LibraryIup::_IupGetDialog($self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub GetDialogChild {
  #Ihandle* IupGetDialogChild(Ihandle *ih, const char* name); [in C]
  #iup.GetDialogChild(ih: ihandle, name: string) -> (ih: ihandle) [in Lua]
  my ($self, $name) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGetDialogChild($self->ihandle, $name);
  return IUP->GetByIhandle($ih);
}

sub GetParamParam {
  #iup.GetParamParam(dialog: ihandle, param_index: number)-> (param: ihandle) [in Lua]
  my ($self, $param_index) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGetAttributeIH($self->ihandle, "PARAM" . $param_index);
  return IUP->GetByIhandle($ih);
}

sub GetParamValue {
  # extra function - not in standard iup C API
  #iup.GetParamParam(dialog: ihandle, param_index: number)-> (param: ihandle) [in Lua]
  my ($self, $param_index, $newval) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGetAttributeIH($self->ihandle, "PARAM" . $param_index);
  my $ct = IUP::Internal::LibraryIup::_IupGetAttributeIH($ih, "CONTROL");
  if (defined $newval) {
    #xxxWORKAROUND
    #when setting listindex values there is a mismatch 0-based vs 1-based indexes
    #setting VALUE to 1 selects the first item - there seems not to be an easy workaround
    my $t = IUP::Internal::LibraryIup::_IupGetAttribute($ih, "TYPE");
    $newval++ if ($t && $t eq 'LIST' && looks_like_number($newval) && $newval >=0);
    #xxxWORKAROUND-FINISHED
    IUP::Internal::LibraryIup::_IupStoreAttribute($ih, "VALUE", $newval);
    IUP::Internal::LibraryIup::_IupStoreAttribute($ct, "VALUE", $newval);
  }
  else {
    return IUP::Internal::LibraryIup::_IupGetAttribute($ih, "VALUE"); #usually the new value
    #XXX-beware it might be dufferent from:
    #return IUP::Internal::LibraryIup::_IupGetAttribute($ct, "VALUE"); #usually the old value
  }
}

sub GetChild {
  #Ihandle *IupGetChild(Ihandle* ih, int pos); [in C]
  #iup.GetChild(ih: ihandle, pos: number) -> child: ihandle [in Lua]
  my ($self, $pos) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGetChild($self->ihandle, $pos);
  return IUP->GetByIhandle($ih);
}

sub GetParent {
  #Ihandle* IupGetParent(Ihandle *ih); [in C]
  #iup.GetParent(ih: ihandle) -> parent: ihandle [in Lua]
  my $self = shift;
  my $ih = IUP::Internal::LibraryIup::_IupGetParent($self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub Insert {
  #Ihandle* IupInsert(Ihandle* ih, Ihandle* ref_child, Ihandle* new_child); [in C]
  #iup.Append(ih, ref_child, new_child: ihandle) -> (parent: ihandle) [in Lua]
  my ($self, $ref_child, $new_child) = @_;
  return unless ref $ref_child && ref $new_child;
  my $ih = IUP::Internal::LibraryIup::_IupInsert($self->ihandle, $ref_child->ihandle, $new_child->ihandle);
  return IUP->GetByIhandle($ih);
}

sub NextField {
  #Ihandle* IupNextField(Ihandle* ih); [in C]
  #iup.NextField(ih: ihandle) -> (next: ihandle) [in Lua]
  my $self = shift;
  my $ih = IUP::Internal::LibraryIup::_IupNextField($self->ihandle);
  return IUP->GetByIhandle($ih);
}

sub DESTROY {
  #IMPORTANT: do not automatically destroy iup elements
  #warn "XXX-DEBUG: IUP::Internal::Element::DESTROY(): " . ref($_[0]) . " [" . $_[0]->ihandle . "]\n";
}

###### INTERNAL HELPER FUNCTIONS

sub _create_element {
  my ($self, @args) = @_;
  die "Function _create_element() not implemented in IUP::Internal::Element";
}

sub _get_child_ref {
  #xxx(ANTI)DESTROY-MAGIC
  my ($self, $ih) = @_;
  return $self->{'!int!child'}->{$ih};
}

sub _store_child_ref {
  #xxx(ANTI)DESTROY-MAGIC
  my $self = shift;
  #warn("***DEBUG*** _store_child_ref started\n");
  for (@_) {
    next unless blessed($_);
    $self->{'!int!child'}->{$_->ihandle} = $_;
  }
}

sub _internal_destroy {
  my $self = shift;
  #unset all callbacks
  #warn("***DEBUG*** _internal_destroy ".$self->ihandle." started\n");
  for (keys %$self) {
    $self->SetCallback($1, undef) if (/^!int!cb!([^!]+)!func$/);
  }
  #go through all children #xxx(ANTI)DESTROY-MAGIC
  for (keys %{$self->{'!int!child'}}) {
    $self->{'!int!child'}->{$_}->_internal_destroy()
  }
  #in the last step destroy $self->ihandle
  #warn("***DEBUG*** _internal_destroy ".$self->ihandle." finished\n");
  $self->ihandle(undef);
}

sub _proc_child_param {
  #handling new(child=>$child) or new(child=>[...]) of new($child) or new([...])
  #warn "***DEBUG*** _proc_child_param started\n";
  my ($self, $func, $args, $firstonly) = @_;
  my @list;
  my @ihlist;

  if (defined $firstonly) {
    @list = (ref($firstonly) eq 'ARRAY') ? @$firstonly : ($firstonly);
  }
  elsif (defined $args && defined $args->{child}) {
    if (ref($args->{child}) eq 'ARRAY') {
      @list = @{$args->{child}};
    }
    elsif (blessed($args->{child}) && $args->{child}->can('ihandle')) {
      @list = ($args->{child});
    }
    else {
      carp "Warning: 'child' parameter has to be a reference to IUP element";
    }
    delete $args->{child};
  }

  for (@list) {
    if (blessed($_) && $_->can('ihandle')) {
      push @ihlist, $_->ihandle;
      $self->_store_child_ref($_); #xxx(ANTI)DESTROY-MAGIC
    }
    else {
      carp "warning: undefined item passed as 'child' parameter of ",ref($self),"->new()";
    }
  }
  return &$func(@ihlist);
}

#internal helper func
sub _proc_child_param_single {
  #handling new(child=>$child, ...) or new($child)
  #warn "***DEBUG*** _proc_child_param_single started\n";
  my ($self, $func, $args, $firstonly) = @_;
  my $ih;
  if (defined $firstonly) {
    if (blessed($firstonly) && $firstonly->can('ihandle')) {
      $ih = &$func($firstonly->ihandle); #call func
      $self->_store_child_ref($firstonly); #xxx(ANTI)DESTROY-MAGIC
    }
    else {
      carp "Warning: parameter 'child' has to be a reference to IUP element";
      $ih = &$func(undef); #call func
    }
  }
  elsif (defined $args && defined $args->{child}) {
    if (blessed($args->{child}) && $args->{child}->can('ihandle')) {
      $ih = &$func($args->{child}->ihandle); #call func
      $self->_store_child_ref($args->{child}); #xxx(ANTI)DESTROY-MAGIC
    }
    else {
      carp "Warning: 'child' parameter has to be a reference to IUP element";
      $ih = &$func(undef); #call func
    }
    delete $args->{child};
  }
  else {
    $ih = &$func(undef); #call func
  }
  return $ih;
}

1;

=pod

=head1 NAME

IUP::Internal::Element - [internal only] DO NOT USE this unless you know what could happen!

=cut
