use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Table::Item;

my ($i, $i2, $i3);
my $r;

my @tests = (
  sub {
    $i = Games::Sudoku::Component::Table::Item->new(
      row => 5,
      col => 4,
      allowed => [1,2,3,4],
    );
    ok(ref $i eq 'Games::Sudoku::Component::Table::Item');
  },
  sub {
    ok($i->row == 5);
  },
  sub {
    ok($i->col == 4);
  },
  sub {
    ok(scalar $i->allowed == 4);
  },
  sub {
    ok(!$i->value);
  },
  sub {
    $r = $i->random_value;
    ok($r > 0 and $r < 5);
  },
  sub {
    ok($i->value == $r);
  },
  sub {
    ok(scalar $i->allowed == 3);
  },
  sub {
    my $found = grep { $_ == $r } $i->allowed;
    ok(!$found);
  },
  sub {
    ok($i->as_string);
  },

);

eval "use Test::Exception";
unless ($@) {
  push @tests, (
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Item->new;
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Item->new(
            col => 5,
            allowed => [1,2,3,4]
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Item->new(
            row => 5,
            allowed => [1,2,3,4]
          );
        }
      );
    },
    sub {
      dies_ok(
        sub {
          my $err = Games::Sudoku::Component::Table::Item->new(
            row => 5,
            col => 4,
          );
        }
      );
    },

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
