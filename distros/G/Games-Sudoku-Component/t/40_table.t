use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Table;

my ($t, $t2, $t3);
my @tests;

# These tests will be always executed.

@tests = (

  sub {
    $t = Games::Sudoku::Component::Table->new;
    ok(ref $t eq 'Games::Sudoku::Component::Table');
  },
  sub {
    ok($t->size == 9);
  },
  sub {
    ok(scalar $t->cells == 81);
  },
  sub {
    ok($t->block_width == 3);
  },
  sub {
    ok($t->block_height == 3);
  },

  sub {
    $t2 = Games::Sudoku::Component::Table->new(
      size => 16,
    );
    ok(ref $t2 eq 'Games::Sudoku::Component::Table');
  },
  sub {
    ok($t2->size == 16);
  },
  sub {
    ok(scalar $t2->cells == 16*16);
  },
  sub {
    ok($t2->block_width == 4);
  },
  sub {
    ok($t2->block_height == 4);
  },

  sub {
    $t3 = Games::Sudoku::Component::Table->new(
      block_width  => 3,
      block_height => 2,
    );
    ok(ref $t3 eq 'Games::Sudoku::Component::Table');
  },
  sub {
    ok($t3->size == 6);
  },
  sub {
    ok(scalar $t3->cells == 36);
  },
  sub {
    ok($t3->block_width == 3);
  },
  sub {
    ok($t3->block_height == 2);
  },

  # Check initial status
  sub {
    ok(scalar $t->cell(5,5)->allowed == 9);
  },

  sub {
    ok($t->cell(5,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(2));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(3));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(4));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(5));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(6));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(7));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(8));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(9));
  },

  # Set value to deny one
  sub {
    $t->cell(5,5)->value(1);
    ok($t->cell(5,5)->value == 1);
  },

  sub {
    my @allowed = $t->cell(5,5)->allowed;
    ok(scalar @allowed == 0);
  },

  sub {
    ok(!$t->cell(5,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(2));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(3));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(4));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(5));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(6));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(7));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(8));
  },
  sub {
    ok(!$t->cell(5,5)->is_allowed(9));
  },

  # Check row
  sub {
    ok(!$t->cell(1,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(2,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(3,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(4,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(6,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(7,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(8,5)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(9,5)->is_allowed(1));
  },

  # Check col
  sub {
    ok(!$t->cell(5,1)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,2)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,3)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,4)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,6)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,7)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,8)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(5,9)->is_allowed(1));
  },

  # Check block
  sub {
    ok(!$t->cell(4,4)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(4,6)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(6,4)->is_allowed(1));
  },
  sub {
    ok(!$t->cell(6,6)->is_allowed(1));
  },

  # Clear value to allow one
  sub {
    $t->cell(5,5)->value(0);
    ok($t->cell(5,5)->value == 0);
  },

  sub {
    my @allowed = $t->cell(5,5)->allowed;
    ok(scalar @allowed == 9);
  },

  sub {
    ok($t->cell(5,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(2));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(3));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(4));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(5));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(6));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(7));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(8));
  },
  sub {
    ok($t->cell(5,5)->is_allowed(9));
  },

  # Check row
  sub {
    ok($t->cell(1,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(2,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(3,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(4,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(6,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(7,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(8,5)->is_allowed(1));
  },
  sub {
    ok($t->cell(9,5)->is_allowed(1));
  },

  # Check col
  sub {
    ok($t->cell(5,1)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,2)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,3)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,4)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,6)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,7)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,8)->is_allowed(1));
  },
  sub {
    ok($t->cell(5,9)->is_allowed(1));
  },

  # Check block
  sub {
    ok($t->cell(4,4)->is_allowed(1));
  },
  sub {
    ok($t->cell(4,6)->is_allowed(1));
  },
  sub {
    ok($t->cell(6,4)->is_allowed(1));
  },
  sub {
    ok($t->cell(6,6)->is_allowed(1));
  },

  # Set value again
  sub {
    $t->cell(5,5)->value(1);
    ok($t->cell(5,5)->value == 1);
  },
  # Set forbidden value; new value is set temporarily
  sub {
    $t->cell(5,4)->value(1);
    ok($t->cell(5,4)->value == 1);
  },
  sub {
    ok($t->cell(5,4)->realvalue == 0);
  },
  sub {
    ok($t->cell(5,4)->tmpvalue == 1);
  },
  # Clear value
  sub {
    $t->cell(5,5)->value(0);
    ok($t->cell(5,5)->value == 0);
  },
  # new value is still temporary one
  sub {
    ok($t->cell(5,4)->value == 1);
  },
  sub {
    ok($t->cell(5,4)->realvalue == 0);
  },
  sub {
    ok($t->cell(5,4)->tmpvalue == 1);
  },
  # After check_tmpvalue, new value becomes real one
  sub {
    $t->check_tmpvalue;
    ok($t->cell(5,4)->value == 1);
  },
  sub {
    ok($t->cell(5,4)->realvalue == 1);
  },
  sub {
    ok($t->cell(5,4)->tmpvalue == 0);
  },

  # Set forbidden value again; new value is set temporarily
  sub {
    $t->cell(5,5)->value(1);
    ok($t->cell(5,5)->value == 1);
  },
  sub {
    ok($t->cell(5,5)->realvalue == 0);
  },
  sub {
    ok($t->cell(5,5)->tmpvalue == 1);
  },
  # Set another value
  sub {
    $t->cell(5,4)->value(3);
    ok($t->cell(5,4)->value == 3);
  },
  # new value is still temporary one
  sub {
    ok($t->cell(5,5)->value == 1);
  },
  sub {
    ok($t->cell(5,5)->realvalue == 0);
  },
  sub {
    ok($t->cell(5,5)->tmpvalue == 1);
  },
  # After check_tmpvalue, new value becomes real one
  sub {
    $t->check_tmpvalue;
    ok($t->cell(5,5)->value == 1);
  },
  sub {
    ok($t->cell(5,5)->realvalue == 1);
  },
  sub {
    ok($t->cell(5,5)->tmpvalue == 0);
  },

  # Of course this table is not finished
  sub {
    $t->clear;
    ok(!$t->is_finished);
  },
  sub {
    ok($t->find_next);
  },
  sub {
    ok(scalar $t->find_all == 81);
  },
  sub {
    ok($t->as_string);
  },
  sub {
    ok($t->as_HTML);
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
          my $err = Games::Sudoku::Component::Table->new(
            size => 10,
          );
        }
      );
    },


    # Block setting should need both width and height
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table->new(
            block_width => 3,
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table->new(
            block_height => 3,
          );
        }
      );
    },

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
