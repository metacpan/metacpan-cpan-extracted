package IUP::GL::Val;
use strict;
use warnings;
use base 'IUP::GL';
use IUP::Internal::LibraryIup;

sub _create_element {
  my ($self, $args) = @_;
  #return IUP::Internal::LibraryIup::_IupGLVal(delete $args->{ORIENTATION});
  return IUP::Internal::LibraryIup::_IupGLVal();
}

1;
