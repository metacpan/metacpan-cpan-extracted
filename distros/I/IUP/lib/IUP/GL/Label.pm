package IUP::GL::Label;
use strict;
use warnings;
use base 'IUP::GL';
use IUP::Internal::LibraryIup;

sub _create_element {
  my ($self, $args) = @_;
  return IUP::Internal::LibraryIup::_IupGLLabel(delete $args->{TITLE});
}

1;
