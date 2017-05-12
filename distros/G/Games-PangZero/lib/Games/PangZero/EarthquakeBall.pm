##########################################################################
package Games::PangZero::EarthquakeBall;
##########################################################################

@ISA = qw(Games::PangZero::Ball);
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self  = Games::PangZero::Ball->new(@_);
  bless $self, $class;
}

sub CountEarthquakeBalls {
  my $count = 0;

  foreach my $ball (@Games::PangZero::GameObjects) {
    if (ref($ball) eq 'Games::PangZero::EarthquakeBall') { ++$count; }
  }
  return $count;
}

sub Bounce {
  my $self = shift;

  unless ($Games::PangZero::GameEvents{earthquake} and $Games::PangZero::GameEvents{earthquake} > $self->{desc}->{quake}) {
    $Games::PangZero::GameEvents{earthquake} = [$self->{desc}->{quake}, $self->{x}];
  }
}

1;
