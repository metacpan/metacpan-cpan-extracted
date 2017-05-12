use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Controller::Status;

my ($s, $s2);

my @tests = (
  sub {
    $s = Games::Sudoku::Component::Controller::Status->new;
    ok(ref $s eq 'Games::Sudoku::Component::Controller::Status');
  },

  # Initial status
  sub {
    ok($s->is_null);
  },
  sub {
    ok(!$s->is_ok);
  },
  sub {
    ok(!$s->is_rewind);
  },
  sub {
    ok(!$s->is_solved);
  },
  sub {
    ok(!$s->is_giveup);
  },
  sub {
    ok(!$s->is_changed);
  },
  sub {
    ok(!$s->is_finished);
  },

  # Turn to ok
  sub {
    $s->turn_to_ok;
    ok(!$s->is_null);
  },
  sub {
    ok($s->is_ok);
  },
  sub {
    ok(!$s->is_rewind);
  },
  sub {
    ok(!$s->is_solved);
  },
  sub {
    ok(!$s->is_giveup);
  },
  sub {
    ok($s->is_changed);
  },
  sub {
    ok(!$s->is_finished);
  },

  # Turn to rewind
  sub {
    $s->turn_to_rewind;
    ok(!$s->is_null);
  },
  sub {
    ok(!$s->is_ok);
  },
  sub {
    ok($s->is_rewind);
  },
  sub {
    ok(!$s->is_solved);
  },
  sub {
    ok(!$s->is_giveup);
  },
  sub {
    ok($s->is_changed);
  },
  sub {
    ok(!$s->is_finished);
  },

  # Turn to solved
  sub {
    $s->turn_to_solved;
    ok(!$s->is_null);
  },
  sub {
    ok(!$s->is_ok);
  },
  sub {
    ok(!$s->is_rewind);
  },
  sub {
    ok($s->is_solved);
  },
  sub {
    ok(!$s->is_giveup);
  },
  sub {
    ok($s->is_changed);
  },
  sub {
    ok($s->is_finished);
  },

  # Turn to giveup
  sub {
    $s->turn_to_giveup;
    ok(!$s->is_null);
  },
  sub {
    ok(!$s->is_ok);
  },
  sub {
    ok(!$s->is_rewind);
  },
  sub {
    ok(!$s->is_solved);
  },
  sub {
    ok($s->is_giveup);
  },
  sub {
    ok($s->is_changed);
  },
  sub {
    ok($s->is_finished);
  },

  # Second is_changed check should fail
  sub {
    ok(!$s->is_changed);
  },

  # Clear
  sub {
    $s->clear;
    ok($s->is_null);
  },
  sub {
    ok(!$s->is_ok);
  },
  sub {
    ok(!$s->is_rewind);
  },
  sub {
    ok(!$s->is_solved);
  },
  sub {
    ok(!$s->is_giveup);
  },
  sub {
    ok(!$s->is_changed);
  },
  sub {
    ok(!$s->is_finished);
  },

  # Check rewind
  sub {
    ok($s->can_rewind); # 1
  },
  sub {
    ok($s->can_rewind); # 2
  },
  sub {
    ok($s->can_rewind); # 3
  },
  sub {
    ok($s->can_rewind); # 4
  },
  sub {
    ok($s->can_rewind); # 5
  },
  sub {
    ok($s->can_rewind); # 6
  },
  sub {
    ok($s->can_rewind); # 7
  },
  sub {
    ok($s->can_rewind); # 8
  },
  sub {
    ok($s->can_rewind); # 9
  },
  sub {
    ok(!$s->can_rewind); # 10
  },

  # Check retry
  sub {
    ok($s->can_retry); # 1
  },
  sub {
    ok($s->can_retry); # 2
  },
  sub {
    ok($s->can_retry); # 3
  },
  sub {
    ok(!$s->can_retry); # 4
  },

  sub {
    $s2 = Games::Sudoku::Component::Controller::Status->new(
      rewind_max => 3,
      retry_max  => 1,
    );
    ok(ref $s2 eq 'Games::Sudoku::Component::Controller::Status');
  },

  # Check rewind
  sub {
    ok($s2->can_rewind); # 1
  },
  sub {
    ok($s2->can_rewind); # 2
  },
  sub {
    ok($s2->can_rewind); # 3
  },
  sub {
    ok(!$s2->can_rewind); # 4
  },

  # Check retry
  sub {
    ok($s2->can_retry); # 1
  },
  sub {
    ok(!$s2->can_retry); # 2
  },
);

eval "use Test::Exception";
unless ($@) {
  push @tests, (

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
