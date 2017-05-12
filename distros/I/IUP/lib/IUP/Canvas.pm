package IUP::Canvas;
use strict;
use warnings;
use base qw(IUP::Internal::Element IUP::Internal::Canvas);
use IUP::Internal::LibraryIup;
use IUP::Constants;

sub _special_initial_map_cb {
  my $self = shift;
  if (defined $self && !$self->cnvhandle) {
    my $ch = IUP::Internal::Canvas::_cdCreateCanvas_CD_IUP($self->ihandle);  
    $self->cnvhandle($ch);
    $self->MAP_CB(undef); #deactivate callback    
  }
  return IUP_DEFAULT;
}

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupCanvas(undef);
  $self->ihandle($ih);
  my $f = \&_special_initial_map_cb;
  $self->MAP_CB($f);
  return $ih;
}

#Note: all canvas related methods are inherited from IUP::Internal::Canvas

#XXX-CHECKLATER hack to make the following modules apper in META.json provide=>...
package IUP::Canvas::Bitmap;
package IUP::Canvas::Palette;
package IUP::Canvas::Pattern;
package IUP::Canvas::Stipple;

1;
