##########################################################################
package Games::PangZero::WaterBall;
##########################################################################

@ISA = qw( Games::PangZero::Ball );

sub Bounce {
  my $self = shift;
  if ($self->{desc}->{nextgen}) {
    $self->{bonus} = 0;
    $self->Pop(undef, '');
  }
}

1;
