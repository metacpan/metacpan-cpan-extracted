##########################################################################
package Games::PangZero::PowerWire;
##########################################################################

@ISA = qw(Games::PangZero::Harpoon);
use strict;
use warnings;

sub Create {
  return PowerWire->new(@_);
}

sub new {
  my $class = shift;
  my $self  = Harpoon->new(@_);
  %{$self}  = ( %{$self},
    'topdelay' => 200,
  );
  bless $self, $class;
}

sub Advance {
  my $self = shift;

  if ($self->{y} > 0) {
    return $self->SUPER::Advance();
  }
  $self->{y} = 0;
  --$self->{topdelay};
  if ($self->{topdelay} <= 0) {
    $self->Delete();
  }
}

sub GetAnimPhase {
  my $self = shift;

  if ($self->{y} <= 0) {
    return 0;
  }
  return $self->SUPER::GetAnimPhase();
}

1;
