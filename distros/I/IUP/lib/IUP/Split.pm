package IUP::Split;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my ($c1, $c2);
  if (defined $args) {
    $c1 = $args->{child1}->ihandle if defined $args->{child1};
    $c2 = $args->{child2}->ihandle if defined $args->{child2};
    $self->_store_child_ref($args->{child1}, $args->{child2}); #xxx(ANTI)DESTROY-MAGIC
    delete $args->{child1};
    delete $args->{child2};
  }
  my $ih = IUP::Internal::LibraryIup::_IupSplit($c1, $c2);
  return $ih;
}

1;
