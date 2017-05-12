#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 36;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->program("t/calc.pl");
$ebug->load;

# Let's step through the program, and check that we step through the
# lines in the right order

my @lines = (3, 4, 5, 12, 13, 14, 6, 7, 9);
foreach my $l (@lines) {
  is($ebug->line, $l);
  is($ebug->package, 'main');
  is($ebug->filename, 't/calc.pl');
  ok($ebug->codeline);
  $ebug->step;
}

