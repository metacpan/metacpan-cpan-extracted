##########################################################################
package Games::PangZero::SlowEffect;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);
use strict;
use warnings;

sub new {
  my ($class) = @_;
  my $self    = Games::PangZero::GameObject->new();
  %{$self}    = ( %{$self},
    'timeout' => 1500, # Lasts for 15s
  );
  # TODO Play a sound here
  bless $self, $class;
  return $self;
}

sub RemoveSlowEffects {
  @Games::PangZero::GameObjects = grep { ref $_ ne 'Games::PangZero::SlowEffect' } @Games::PangZero::GameObjects;
}

sub Advance {
  my ($self) = @_;
  my ($timeout, $slowratio);
  
  $timeout = --$self->{timeout};
  if ( $timeout == 256 ) {
    # TODO Play a sound here
  }
  if ( $timeout > 256 ) {
    $Games::PangZero::GameSpeed = 0.2;
  } elsif ( $timeout > 0 ) {
    $Games::PangZero::Game->SetGameSpeed();
    $slowratio           = int(256 - $timeout) / 256;
    $Games::PangZero::GameSpeed = $Games::PangZero::GameSpeed * $slowratio + 0.2 * (1.0 - $slowratio);
  } else {
    $Games::PangZero::Game->SetGameSpeed();
    $self->Delete();
    return;
  }
}

sub Draw {
}

sub Clear {
}

1;
