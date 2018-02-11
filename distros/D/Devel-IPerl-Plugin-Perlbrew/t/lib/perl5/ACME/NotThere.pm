package ## no pause
  ACME::NotThere;
use strict;
use warnings;
use feature 'say';

sub heres_johnny {
  my $word = 'boo';
  say STDERR $word;
  return $word;
}

1;
