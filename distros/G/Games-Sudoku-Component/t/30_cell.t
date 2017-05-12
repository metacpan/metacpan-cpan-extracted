use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Table::Cell;
use Games::Sudoku::Component::Table::Permission;

my ($c, $c2, $c3);

my $perm = Games::Sudoku::Component::Table::Permission->new;

# These tests will be always executed.

my @tests = (

  # Check the objects and their size.
  sub {
    $c = Games::Sudoku::Component::Table::Cell->new(
      row  => 1,
      col  => 1,
      perm => $perm,
    );
    ok(ref $c eq 'Games::Sudoku::Component::Table::Cell');
  },
  sub {
    ok($c->size == 9);
  },
  sub {
    ok($c->block_width == 3);
  },
  sub {
    ok($c->block_height == 3);
  },
  sub {
    ok($c->row == 1);
  },
  sub {
    ok($c->col == 1);
  },
  sub {
    ok($c->realvalue == 0);
  },
  sub {
    ok($c->tmpvalue == 0);
  },
  sub {
    ok($c->value == 0);
  },

  sub {
    $c2 = Games::Sudoku::Component::Table::Cell->new(
      row  => 16,
      col  => 16,
      size => 16,
      perm => $perm,
    );
    ok(ref $c2 eq 'Games::Sudoku::Component::Table::Cell');
  },
  sub {
    ok($c2->size == 16);
  },
  sub {
    ok($c2->block_width == 4);
  },
  sub {
    ok($c2->block_height == 4);
  },
  sub {
    ok($c2->row == 16);
  },
  sub {
    ok($c2->col == 16);
  },
  sub {
    ok($c2->realvalue == 0);
  },
  sub {
    ok($c2->tmpvalue == 0);
  },
  sub {
    ok($c2->value == 0);
  },

  sub {
    $c3 = Games::Sudoku::Component::Table::Cell->new(
      row          => 4,
      col          => 4,
      block_width  => 3,
      block_height => 2,
      perm         => $perm,
    );
    ok(ref $c3 eq 'Games::Sudoku::Component::Table::Cell');
  },
  sub {
    ok($c3->size == 6);
  },
  sub {
    ok($c3->block_width == 3);
  },
  sub {
    ok($c3->block_height == 2);
  },
  sub {
    ok($c3->row == 4);
  },
  sub {
    ok($c3->col == 4);
  },
  sub {
    ok($c3->realvalue == 0);
  },
  sub {
    ok($c3->tmpvalue == 0);
  },
  sub {
    ok($c3->value == 0);
  },

  # Check initial status
  sub {
    ok(scalar $c->allowed == 9);
  },

  sub {
    ok($c->is_allowed(1));
  },
  sub {
    ok($c->is_allowed(2));
  },
  sub {
    ok($c->is_allowed(3));
  },
  sub {
    ok($c->is_allowed(4));
  },
  sub {
    ok($c->is_allowed(5));
  },
  sub {
    ok($c->is_allowed(6));
  },
  sub {
    ok($c->is_allowed(7));
  },
  sub {
    ok($c->is_allowed(8));
  },
  sub {
    ok($c->is_allowed(9));
  },

  # Set value
  sub {
    $c->value(1);
    ok($c->value == 1);
  },
  sub {
    ok($c->realvalue == 1);
  },
  sub {
    ok($c->tmpvalue == 0);
  },
  sub {
    my @allowed = $c->allowed;
    ok(scalar @allowed == 0);
  },

  # Set another value.
  # Can override if there are no other restrictions
  sub {
    $c->value(2);
    ok($c->value == 2);
  },
  sub {
    ok($c->realvalue == 2);
  },
  sub {
    ok($c->tmpvalue == 0);
  },
  sub {
    my @allowed = $c->allowed;
    ok(scalar @allowed == 0);
  },

  # Set yet another value.
  # Cannot override if there are other restrictions
  sub {
    $c->_permissions->deny(1,2,1);
    ok(!$c->is_allowed(1));
  },
  sub {
    $c->value(1);
    ok($c->value == 1);
  },
  sub {
    ok($c->realvalue == 0);
  },
  sub {
    ok($c->tmpvalue == 1);
  },
  sub {
    my @allowed = $c->allowed;
    ok(scalar @allowed == 8);
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
          $c3 = Games::Sudoku::Component::Table::Cell->new(
            row  => 1,
            col  => 1,
            size => 10,
            perm => $perm,
          );
        }
      );
    },

    # Block setting should need both width and height
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row => 1,
            col => 1,
            block_width => 3,
            perm => $perm,
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row => 1,
            col => 1,
            block_height => 3,
            perm => $perm,
          );
        }
      );
    },

    # Row or Col should be between 1 and $size, inclusive.
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row  => 10,
            col  => 1,
            size => 9,
            perm => $perm,
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row  => 1,
            col  => 10,
            size => 9,
            perm => $perm,
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row  => 0,
            col  => 1,
            perm => $perm,
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row  => 1,
            col  => 0,
            perm => $perm,
          );
        }
      );
    },

    # Permission object is required
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Cell->new(
            row  => 1,
            col  => 1,
          );
        }
      );
    },

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
