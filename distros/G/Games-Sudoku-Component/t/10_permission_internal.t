use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Table::Permission;

# Default 9x9 table
my $p = Games::Sudoku::Component::Table::Permission->new;

my $flag = 2 ** (8 - 1) + 2 ** (5 - 1);

# These tests will be always executed.

my @tests = (
  # Check current flag status
  sub {
    ok(!$p->_flag($flag, 1));
  },
  sub {
    ok(!$p->_flag($flag, 2));
  },
  sub {
    ok(!$p->_flag($flag, 3));
  },
  sub {
    ok(!$p->_flag($flag, 4));
  },
  sub {
    ok($p->_flag($flag, 5));
  },
  sub {
    ok(!$p->_flag($flag, 6));
  },
  sub {
    ok(!$p->_flag($flag, 7));
  },
  sub {
    ok($p->_flag($flag, 8));
  },
  sub {
    ok(!$p->_flag($flag, 9));
  },

  # Flag 1 on
  sub {
    $flag = $p->_on($flag, 1);
    ok($p->_flag($flag, 1));
  },
  sub {
    ok(!$p->_flag($flag, 2));
  },
  sub {
    ok(!$p->_flag($flag, 3));
  },
  sub {
    ok(!$p->_flag($flag, 4));
  },
  sub {
    ok($p->_flag($flag, 5));
  },
  sub {
    ok(!$p->_flag($flag, 6));
  },
  sub {
    ok(!$p->_flag($flag, 7));
  },
  sub {
    ok($p->_flag($flag, 8));
  },
  sub {
    ok(!$p->_flag($flag, 9));
  },

  # Flag 1 off
  sub {
    $flag = $p->_off($flag, 1);
    ok(!$p->_flag($flag, 1));
  },
  sub {
    ok(!$p->_flag($flag, 2));
  },
  sub {
    ok(!$p->_flag($flag, 3));
  },
  sub {
    ok(!$p->_flag($flag, 4));
  },
  sub {
    ok($p->_flag($flag, 5));
  },
  sub {
    ok(!$p->_flag($flag, 6));
  },
  sub {
    ok(!$p->_flag($flag, 7));
  },
  sub {
    ok($p->_flag($flag, 8));
  },
  sub {
    ok(!$p->_flag($flag, 9));
  },
);

# We have some exception tests.

eval "use Test::Exception";
unless ($@) {
  push @tests, (

    # Check boundaries
    sub {
      dies_ok(
        sub {
          $p->_flag($flag, -1);
        }
      );
    },

    sub {
      dies_ok(
        sub {
          $p->_flag($flag, 10);
        }
      );
    },

    sub {
      dies_ok(
        sub {
          $p->_on($flag, 10);
        }
      );
    },

    sub {
      dies_ok(
        sub {
          $p->_on($flag, -1);
        }
      );
    },

    sub {
      dies_ok(
        sub {
          $p->_off($flag, 10);
        }
      );
    },

    sub {
      dies_ok(
        sub {
          $p->_off($flag, -1);
        }
      );
    },

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
