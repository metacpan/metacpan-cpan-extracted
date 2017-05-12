package IUP::Link;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  return IUP::Internal::LibraryIup::_IupLink(delete $args->{URL}, delete $args->{TITLE});
}

1;
