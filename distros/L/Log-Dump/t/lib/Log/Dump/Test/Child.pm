package Log::Dump::Test::Child;

use strict;
use warnings;
use base qw( Log::Dump::Test::Class );

sub child {
  my $self = shift;

  $self->log( child => 'child' );
}

1;
