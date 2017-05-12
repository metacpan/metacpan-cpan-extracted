package IUP::GL::SubCanvas;
use strict;
use warnings;
use base 'IUP::GL';
use IUP::Internal::LibraryIup;

sub _create_element {
  return IUP::Internal::LibraryIup::_IupGLSubCanvas;
}

1;
