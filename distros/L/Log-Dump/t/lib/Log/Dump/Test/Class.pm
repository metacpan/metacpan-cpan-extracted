package Log::Dump::Test::Class;

use strict;
use warnings;
use Log::Dump;

sub new { bless {}, shift }

sub debug {
  my $self = shift;

  $self->log( debug => 'debug' );
}

1;
