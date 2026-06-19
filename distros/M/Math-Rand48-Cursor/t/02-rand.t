use strict;
use warnings;
use Config;
use Test::More;
use Math::Rand48::Cursor;

plan skip_all => "rand() is not Perl_drand48 ($Config{randfunc})"
  unless $Config{randfunc} eq 'Perl_drand48';

srand(424242);
my $prev = rand;    # draw before the observed one
my $obs  = rand;    # the observed output
my $next = rand;    # draw after the observed one

my $predicted = Math::Rand48::Cursor->from_rand($obs)->forward->state;
my $actual    = Math::Rand48::Cursor->from_rand($next)->state;
is $predicted->bstr, $actual->bstr, 'forward predicts the next rand()';

my $recovered = Math::Rand48::Cursor->from_rand($obs)->backward->state;
is $recovered->bstr, Math::Rand48::Cursor->from_rand($prev)->state->bstr, 'backward recovers the previous rand()';

done_testing;
