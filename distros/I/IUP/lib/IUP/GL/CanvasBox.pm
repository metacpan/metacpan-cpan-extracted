package IUP::GL::CanvasBox;
use strict;
use warnings;
use base 'IUP::CanvasGL';
use IUP::GL;
use IUP::Internal::LibraryIup;

sub _create_element {
  return shift->_proc_child_param(\&IUP::Internal::LibraryIup::_IupGLCanvasBox, @_);
}

1;
