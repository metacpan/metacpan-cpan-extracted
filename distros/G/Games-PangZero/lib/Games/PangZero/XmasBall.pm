##########################################################################
package Games::PangZero::XmasBall;
##########################################################################

@ISA = qw(Games::PangZero::Ball);
use strict;
use warnings;

sub SpawnChildren {
  return ();
}

sub Pop {
  my $self          = shift;
  $self->SUPER::Pop(@_);
  my $bonusdrop     = BonusDrop->new($self);
  my @collectedSubs = ( \&OnCollectedLife, \&OnCollectedScore, \&OnCollectedScore, \&OnCollectedInvulnerability, \&OnCollectedInvulnerability );
  if ($Games::PangZero::Game->Rand(2 * scalar @collectedSubs) < scalar @collectedSubs) {
    $bonusdrop->{desc} = { 'srcRect' => SDL::Rect->new(0, 0, 32, 32), };
    $bonusdrop->SetOnCollectedSub( $collectedSubs[int $Games::PangZero::Game->Rand(scalar @collectedSubs)] );
  }
  push @Games::PangZero::GameObjects, $bonusdrop;
}

sub GiveMagic {
}
sub GiveBonus {
}

sub OnCollectedLife {
  my ($bonus, $guy) = @_;
  $guy->{player}->{lives}++;
  Games::PangZero::PlaySound('bonuslife');
}

sub OnCollectedScore {
  my ($bonus, $guy) = @_;
  $guy->GiveScore(50000);
  Games::PangZero::PlaySound('score');
}

sub OnCollectedInvulnerability {
  my ($bonus, $guy)  = @_;
  $guy->{invincible} = 500;
}

1;
