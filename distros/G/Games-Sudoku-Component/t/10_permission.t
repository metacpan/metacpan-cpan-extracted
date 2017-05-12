use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Table::Permission;

my ($p, $p2, $p3);
my $flag = 2 ** (8 - 1) + 2 ** (5 - 1);

# These tests will be always executed.

my @tests = (

  # Check the objects and their size.
  sub {
    $p = Games::Sudoku::Component::Table::Permission->new;
    ok(ref $p eq 'Games::Sudoku::Component::Table::Permission');
  },
  sub {
    ok($p->size == 9);
  },
  sub {
    ok($p->block_width == 3);
  },
  sub {
    ok($p->block_height == 3);
  },

  sub {
    $p2 = Games::Sudoku::Component::Table::Permission->new(
      size => 16,
    );
    ok(ref $p2 eq 'Games::Sudoku::Component::Table::Permission');
  },
  sub {
    ok($p2->size == 16);
  },
  sub {
    ok($p2->block_width == 4);
  },
  sub {
    ok($p2->block_height == 4);
  },

  sub {
    $p3 = Games::Sudoku::Component::Table::Permission->new(
      block_width  => 3,
      block_height => 2,
    );
    ok(ref $p3 eq 'Games::Sudoku::Component::Table::Permission');
  },
  sub {
    ok($p3->size == 6);
  },
  sub {
    ok($p3->block_width == 3);
  },
  sub {
    ok($p3->block_height == 2);
  },

  # Check initial status
  sub {
    my @allowed = $p->allowed(5,5);
    ok(scalar @allowed == 9);
  },

  # Deny one
  sub {
    $p->deny(5,5,1);
    ok(scalar $p->allowed(5,5) == 8);
  },

  # Deny again
  sub {
    $p->deny(5,5,1);
    ok(scalar $p->allowed(5,5) == 8);
  },

  sub {
    ok(!$p->is_allowed(5,5,1));
  },

  # Check row
  sub {
    ok(!$p->is_allowed(1,5,1));
  },
  sub {
    ok(!$p->is_allowed(2,5,1));
  },
  sub {
    ok(!$p->is_allowed(3,5,1));
  },
  sub {
    ok(!$p->is_allowed(4,5,1));
  },
  sub {
    ok(!$p->is_allowed(6,5,1));
  },
  sub {
    ok(!$p->is_allowed(7,5,1));
  },
  sub {
    ok(!$p->is_allowed(8,5,1));
  },
  sub {
    ok(!$p->is_allowed(9,5,1));
  },

  # Check col
  sub {
    ok(!$p->is_allowed(5,1,1));
  },
  sub {
    ok(!$p->is_allowed(5,2,1));
  },
  sub {
    ok(!$p->is_allowed(5,3,1));
  },
  sub {
    ok(!$p->is_allowed(5,4,1));
  },
  sub {
    ok(!$p->is_allowed(5,6,1));
  },
  sub {
    ok(!$p->is_allowed(5,7,1));
  },
  sub {
    ok(!$p->is_allowed(5,8,1));
  },
  sub {
    ok(!$p->is_allowed(5,9,1));
  },

  # Check block
  sub {
    ok(!$p->is_allowed(4,4,1));
  },
  sub {
    ok(!$p->is_allowed(4,6,1));
  },
  sub {
    ok(!$p->is_allowed(6,4,1));
  },
  sub {
    ok(!$p->is_allowed(6,6,1));
  },

  # Allow one
  sub {
    $p->allow(5,5,1);
    ok(scalar $p->allowed(5,5) == 9);
  },

  # Allow again
  sub {
    $p->allow(5,5,1);
    ok(scalar $p->allowed(5,5) == 9);
  },

  sub {
    ok($p->is_allowed(5,5,1));
  },

  # Check row
  sub {
    ok($p->is_allowed(1,5,1));
  },
  sub {
    ok($p->is_allowed(2,5,1));
  },
  sub {
    ok($p->is_allowed(3,5,1));
  },
  sub {
    ok($p->is_allowed(4,5,1));
  },
  sub {
    ok($p->is_allowed(6,5,1));
  },
  sub {
    ok($p->is_allowed(7,5,1));
  },
  sub {
    ok($p->is_allowed(8,5,1));
  },
  sub {
    ok($p->is_allowed(9,5,1));
  },

  # Check col
  sub {
    ok($p->is_allowed(5,1,1));
  },
  sub {
    ok($p->is_allowed(5,2,1));
  },
  sub {
    ok($p->is_allowed(5,3,1));
  },
  sub {
    ok($p->is_allowed(5,4,1));
  },
  sub {
    ok($p->is_allowed(5,6,1));
  },
  sub {
    ok($p->is_allowed(5,7,1));
  },
  sub {
    ok($p->is_allowed(5,8,1));
  },
  sub {
    ok($p->is_allowed(5,9,1));
  },

  # Check block
  sub {
    ok($p->is_allowed(4,4,1));
  },
  sub {
    ok($p->is_allowed(4,6,1));
  },
  sub {
    ok($p->is_allowed(6,4,1));
  },
  sub {
    ok($p->is_allowed(6,6,1));
  },

  # Check clear
  sub {
    $p->deny(5,5,1);
    $p->clear;
    ok($p->is_allowed(5,5,1));
  },
);

# We have some exception tests.

eval "use Test::Exception";
unless ($@) {
  push @tests, (

    # Size should be square
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Permission->new(
            size => 10,
          );
        }
      );
    },

    # Block setting should need both width and height
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Permission->new(
            block_width => 3,
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Permission->new(
            block_height => 3,
          );
        }
      );
    },

    # Should specify cell (row/col)
    sub {
      dies_ok(
        sub {
          my @array = $p->allowed;
        }
      );
    },

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
