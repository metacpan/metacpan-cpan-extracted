#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Language::RAM;

plan tests => 3;

my $machine = {
  snaps => {
    0 => [(3)]
  },
  steps => 0,
  ip => 3
};

Language::RAM::add_snapshot($machine, 1, 2);
is($machine->{'snaps'}{0}[0], 3, 'add-snapshot-ip');
is($machine->{'snaps'}{0}[1], 1, 'add-snapshot-addr');
is($machine->{'snaps'}{0}[2], 2, 'add-snapshot-value');

done_testing(3);
