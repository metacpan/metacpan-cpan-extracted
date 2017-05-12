package IUP::Submenu;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my ($t, $m);
  if (defined $args) {

    $t = delete $args->{TITLE};

    if (defined $args->{child}) {
      $m = $args->{child}->ihandle;
      $self->_store_child_ref($args->{child}); #xxx(ANTI)DESTROY-MAGIC
      delete $args->{child};
    }

  }
  my $ih = IUP::Internal::LibraryIup::_IupSubmenu($t, $m);
  return $ih;
}

1;
