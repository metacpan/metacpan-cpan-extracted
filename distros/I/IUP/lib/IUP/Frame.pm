package IUP::Frame;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub _create_element {
  return shift->_proc_child_param_single(\&IUP::Internal::LibraryIup::_IupFrame, @_);
}

1;
