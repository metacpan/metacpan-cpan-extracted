package IUP::Matrix;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupMatrix(undef);
  return $ih;
}

sub MatCell {
  my ($self, $lin, $col, $val) = @_;
  if (scalar(@_)>3) {
    return IUP::Internal::LibraryIup::_IupStoreAttributeId2($self->ihandle, "", $lin, $col, $val);
  }
  else {
    return IUP::Internal::LibraryIup::_IupGetAttributeId2($self->ihandle, "", $lin, $col);
  }
}

sub MatAttribute {
  my ($self, $attr, $lin, $col, $val) = @_;
  if (scalar(@_)>4) {
    return IUP::Internal::LibraryIup::_IupStoreAttributeId2($self->ihandle, $attr, $lin, $col, $val);
  }
  else {
    return IUP::Internal::LibraryIup::_IupGetAttributeId2($self->ihandle, $attr, $lin, $col);
  }
}

1;
