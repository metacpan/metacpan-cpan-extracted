package IUP::Text;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub _create_element {
  #my ($self, $args, $firstonly) = @_;
  return IUP::Internal::LibraryIup::_IupText(undef);
}

sub TextConvertLinColToPos {
  my ($self, $lin, $col) = @_;
  my $pos = IUP::Internal::LibraryIup::_IupTextConvertLinColToPos($self->ihandle, $lin, $col);
  return $pos;
}

sub TextConvertPosToLinCol {
  my ($self, $pos) = @_;
  my ($lin, $col) = IUP::Internal::LibraryIup::_IupTextConvertPosToLinCol($self->ihandle, $pos);
  return ($lin, $col);
}

1;
