package IUP::Scintilla;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub BEGIN {
  IUP::Internal::LibraryIup::_IupScintillaOpen();
}

sub _create_element {
  IUP::Internal::LibraryIup::_IupScintilla();
}

1;
