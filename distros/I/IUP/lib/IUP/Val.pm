package IUP::Val;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih;
  if (defined $firstonly) {
    $ih = IUP::Internal::LibraryIup::_IupVal($firstonly);
  }
  elsif (defined $args->{type}) {
    $ih = IUP::Internal::LibraryIup::_IupVal(delete $args->{type});
  }
  else {
    $ih = IUP::Internal::LibraryIup::_IupVal(undef);
  }
  return $ih;
}

1;
