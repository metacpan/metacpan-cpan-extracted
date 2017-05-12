package IUP::GL::Expander;
use strict;
use warnings;
use base 'IUP::GL';
use IUP::Internal::LibraryIup;

sub _create_element {
  return shift->_proc_child_param(\&IUP::Internal::LibraryIup::_IupGLExpander, @_);
}

1;
