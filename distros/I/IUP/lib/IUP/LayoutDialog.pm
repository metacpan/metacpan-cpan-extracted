package IUP::LayoutDialog;
use strict;
use warnings;
use base 'IUP::Internal::Element';

use IUP::Internal::LibraryIup;
use Scalar::Util 'blessed';
use Carp;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  if (defined $firstonly) {
    return IUP::Internal::LibraryIup::_IupLayoutDialog($firstonly->ihandle) if blessed($firstonly) && $firstonly->can('ihandle');
  }
  elsif (defined $args->{dialog}) {
    my $d = delete $args->{dialog};
    return IUP::Internal::LibraryIup::_IupLayoutDialog($d->ihandle) if blessed($d) && $d->can('ihandle');    
  }
  carp "[warning] IUP::LayoutDialog->new() parameter mismatch";
  return undef;
}

1;
