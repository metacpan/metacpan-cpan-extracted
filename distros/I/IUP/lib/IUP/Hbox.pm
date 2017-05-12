package IUP::Hbox;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub _create_element {
  return shift->_proc_child_param(\&IUP::Internal::LibraryIup::_IupHbox, @_);
}

1;
