use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Controller::Loader;

my (@c, @c2);
my @tests;

# These tests will be always executed.

@tests = (

  sub {
    @c = Games::Sudoku::Component::Controller::Loader->load(<<'_EOD_');
0 1 0
2 0 1
1 2 0
_EOD_

    ok(@c == 9);
  },
  sub {
    ok($c[0]->value == 0);
  },
  sub {
    ok($c[0]->row   == 1);
  },
  sub {
    ok($c[0]->col   == 1);
  },
  sub {
    ok($c[1]->value == 1);
  },
  sub {
    ok($c[1]->row   == 1);
  },
  sub {
    ok($c[1]->col   == 2);
  },
  sub {
    ok($c[2]->value == 0);
  },
  sub {
    ok($c[2]->row   == 1);
  },
  sub {
    ok($c[2]->col   == 3);
  },
  sub {
    ok($c[3]->value == 2);
  },
  sub {
    ok($c[3]->row   == 2);
  },
  sub {
    ok($c[3]->col   == 1);
  },
  sub {
    ok($c[4]->value == 0);
  },
  sub {
    ok($c[4]->row   == 2);
  },
  sub {
    ok($c[4]->col   == 2);
  },
  sub {
    ok($c[5]->value == 1);
  },
  sub {
    ok($c[5]->row   == 2);
  },
  sub {
    ok($c[5]->col   == 3);
  },
  sub {
    ok($c[6]->value == 1);
  },
  sub {
    ok($c[6]->row   == 3);
  },
  sub {
    ok($c[6]->col   == 1);
  },
  sub {
    ok($c[7]->value == 2);
  },
  sub {
    ok($c[7]->row   == 3);
  },
  sub {
    ok($c[7]->col   == 2);
  },
  sub {
    ok($c[8]->value == 0);
  },
  sub {
    ok($c[8]->row   == 3);
  },
  sub {
    ok($c[8]->col   == 3);
  },
);

# We have some exception tests.

eval "use Test::Exception";
unless ($@) {
  push @tests, (

  );
}

plan tests => scalar @tests;

foreach my $cest (@tests) { $cest->(); }
