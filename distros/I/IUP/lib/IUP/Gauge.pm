package IUP::Gauge;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub _create_element {
  #my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGauge();
}

1;
