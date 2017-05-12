package IUP::MatrixList;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub _create_element {
  my ($self, $args) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupMatrixList();

  if (defined $ih) {
    $self->ihandle($ih);
    if (my $c = delete $args->{items}) {
      if (ref($c) eq 'ARRAY') {
        my $i = 1; #BEWARE: the first item is saved as attribute "1"	
        $self->SetAttribute($i++, $_) for (@$c);
      }
      else {
        carp "Warning: parameter 'items' has to be an ARRAY ref";
      }
    }
  }

  return $ih;
}

1;
