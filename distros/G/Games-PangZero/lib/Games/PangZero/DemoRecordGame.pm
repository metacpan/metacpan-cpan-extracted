##########################################################################
package Games::PangZero::DemoRecordGame;
##########################################################################

@ISA = qw(Games::PangZero::DemoGame Games::PangZero::RecordGame);
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self  = Games::PangZero::RecordGame->new(@_);
  bless $self, $class;
}

1;
