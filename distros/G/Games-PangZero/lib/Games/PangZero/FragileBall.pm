##########################################################################
package Games::PangZero::FragileBall;
##########################################################################

@ISA = qw( Games::PangZero::Ball );
use strict;
use warnings;

sub Bounce {
  my $self = shift;
  if ($self->{desc}->{nextgen}) {
    $self->{bonus} = 0;
    $self->Pop(undef, '');
  }
  $self->{speedX} = ($self->{speedX} > 0) ? 1.3 : -1.3;
}

sub SpawnChildren {
  my $self = shift;
  my (@children, $child, $i);
  
  my $nextgen     = $self->{desc}->{nextgen};
  die caller unless $nextgen->{class};
  my $numchildren = 2;
  while ($nextgen->{nextgen}) {
    $nextgen      = $nextgen->{nextgen};
    $numchildren *= 2;
  }
  
  my $y = $self->{y} + ($self->{h} - $nextgen->{height}) / 2;
  for ($i = 0; $i < $numchildren; ++$i) {
    $child           = Games::PangZero::Ball::Create($nextgen, $self->{x}, $y, 0);
    $child->{speedX} = -1.5 + ($i / ($numchildren-1) * 3);
    $child->{x}      = $self->{x} + ($self->{w} - $child->{w}) * ($i / ($numchildren-1));
    push @children, $child;
  }
  
  return @children;
}

1;
