package IUP::Sbox;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub _create_element {
  return shift->_proc_child_param_single(\&IUP::Internal::LibraryIup::_IupSbox, @_);
}

1;
