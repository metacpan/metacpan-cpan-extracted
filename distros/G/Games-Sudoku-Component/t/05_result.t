use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Result;

my ($r, $r2, $r3);

my @tests = (
  sub {
    $r = Games::Sudoku::Component::Result->new;
    ok(ref $r eq 'Games::Sudoku::Component::Result');
  },
  sub {
    ok($r->result == 0);
  },
  sub {
    ok(!$r);
  },
  sub {
    ok($r == 0);
  },
  sub {
    ok($r->reason eq '');
  },

  sub {
    $r2 = Games::Sudoku::Component::Result->new(1);
    ok(ref $r2 eq 'Games::Sudoku::Component::Result');
  },
  sub {
    ok($r2->result == 1);
  },
  sub {
    ok($r2);
  },
  sub {
    ok($r2 == 1);
  },
  sub {
    ok($r2 eq '1');
  },

  sub {
    $r3 = Games::Sudoku::Component::Result->new(
      result => 2,
      reason => 'test'
   );
    ok(ref $r3 eq 'Games::Sudoku::Component::Result');
  },
  sub {
    ok($r3->result == 2);
  },
  sub {
    ok($r3);
  },
  sub {
    ok($r3 == 2);
  },
  sub {
    ok($r3 eq '2');
  },
  sub {
    ok($r3->reason eq 'test');
  },
);

eval "use Test::Exception";
unless ($@) {
  push @tests, (

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
