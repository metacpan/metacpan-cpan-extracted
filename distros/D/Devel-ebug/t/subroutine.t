#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 9;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

# Let's step through the program, and check that we get the
# correct subroutine for each line

foreach (1..9) {
  my $line = $ebug->line;
  my $sub  = $ebug->subroutine;

  my $want_sub = 'main';
  # sub add { ... } is lines 11 to 15
  if ($line > 11 && $line < 15) {
    $want_sub = 'main::add';
  }

  is($sub, $want_sub);
  $ebug->step;
}

