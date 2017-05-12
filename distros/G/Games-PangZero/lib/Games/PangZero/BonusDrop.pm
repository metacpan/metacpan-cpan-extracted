package Games::PangZero::BonusDrop;

@ISA = qw(Games::PangZero::GameObject);
use strict;
use warnings;

use vars qw(@BonusDesc);

@BonusDesc = (
  { 'weaponClass' => 'MachineGun', 'bonusDelay' => 1500, 'srcRect' => SDL::Rect->new( 0, 64, 32, 32), },
  { 'weaponClass' => 'HalfCutter', 'bonusDelay' => 1000, 'srcRect' => SDL::Rect->new(32, 64, 32, 32), },
  { 'weaponClass' => 'PowerWire',  'bonusDelay' => 3000, 'srcRect' => SDL::Rect->new(32, 96, 32, 32), },
  { 'onCollectedSub' => \&OnCollectedSlowEffect,         'srcRect' => SDL::Rect->new(32,  0, 32, 32), },
);


sub new {
  my ($class, $ball) = @_;
  my ($self);

  $self    = Games::PangZero::GameObject->new();

  %{$self} = ( %{$self},
    'x' => $ball->{x} + ($ball->{w} - 32) / 2,
    'y' => $ball->{y} + ($ball->{h} - 32) / 2,
    'w' => 32,
    'h' => 32,
    'speedY' => -3,
    'speedX' => 0,
    'bottomDelay' => 500,
    'desc' => $BonusDesc[int $Games::PangZero::Game->Rand(scalar @BonusDesc)],
  );
  bless $self, $class;
}

sub Advance {
  my $self = shift;

  if ($self->{y} >= $Games::PangZero::ScreenHeight - $self->{h}) {
    $self->{y} = $Games::PangZero::ScreenHeight - $self->{h};
    if (--$self->{bottomDelay} < 0) {
      $self->Delete();
    }
  } else {
    $self->{speedY} += 0.1;
    $self->{y} += $self->{speedY};
  }

  $self->CheckCollisions() if $self->{speedY} >= 0;
}

sub CheckCollisions {
  my $self = shift;
  my ($guy, @guysTouched);

  foreach $guy (@Games::PangZero::GameObjects) {
    next unless ref($guy) eq 'Games::PangZero::Guy';
    next unless $self->Collisions($guy);
    push @guysTouched, ($guy);
  }
  return unless @guysTouched;
  $self->Collected($guysTouched[$Games::PangZero::Game->Rand( scalar @guysTouched )]);
}

sub SetOnCollectedSub {
  my ($self, $onCollectedSub) = @_;
  $self->{onCollectedSub} = $onCollectedSub;
}

sub Collected {
  my ($self, $guy) = @_;
  
  if ($self->{onCollectedSub}) {
    $self->{onCollectedSub}->($self, $guy);
  } elsif ($self->{desc}->{onCollectedSub}) {
    $self->{desc}->{onCollectedSub}->($self, $guy);
  } else {
    $guy->{weapon} = $self->{desc}->{weaponClass};
    $guy->{bonusDelay} = $self->{desc}->{bonusDelay} * $Games::PangZero::WeaponDuration->{durationmultiplier};
  }
  $self->Delete();
}

sub Draw {
  my $self = shift;

  return if $self->{bottomDelay} < 100 and (($Games::PangZero::Game->{anim} / 4) % 2 < 1);
  $self->TransferRect();
  SDL::Video::blit_surface($Games::PangZero::BonusSurface, $self->{desc}->{srcRect}, $Games::PangZero::App, $self->{rect});
}

sub OnCollectedSlowEffect {
  my ($self, $guy) = @_;
  
  Games::PangZero::SlowEffect::RemoveSlowEffects();
  push @Games::PangZero::GameObjects, Games::PangZero::SlowEffect->new();
}

1;
