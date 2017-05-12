##########################################################################
package Games::PangZero::HalfCutter;
##########################################################################

@ISA = qw(Games::PangZero::Harpoon);
use strict;
use warnings;

sub Create {
  return Games::PangZero::HalfCutter->new(@_);
}

sub new {
  my $class = shift;
  my $self                 = Games::PangZero::Harpoon->new(@_);
  $self->{popEffect}       = 'HalfCutter';
  $self->{originalSurface} = $self->{surface};
  bless $self, $class;
}

sub Advance {
  my $self = shift;

  $self->{surface} = (($Games::PangZero::Game->{anim} % 15) < 3) ? $Games::PangZero::WhiteHarpoonSurface : $self->{originalSurface};
  $self->SUPER::Advance();
}

1;
