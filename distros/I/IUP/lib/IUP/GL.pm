package IUP::GL;
use strict;
use warnings;
use base 'IUP::Internal::Element';

sub BEGIN {
  IUP::Internal::LibraryIup::_IupGLControlsOpen();
}

1;
