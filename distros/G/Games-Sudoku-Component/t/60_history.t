use strict;
use warnings;
use Test::More;

use Games::Sudoku::Component::Controller::History;

my ($h, $h2);

my $str  = 'test1';
my $str2 = 'test2';
my @latest;

my @tests = (
  sub {
    $h = Games::Sudoku::Component::Controller::History->new;
    ok(ref $h eq 'Games::Sudoku::Component::Controller::History');
  },

  # Initial status
  sub {
    ok(scalar $h->latest == 0);
  },
  sub {
    ok($h->count == 0);
  },

  sub {
    ok($h->push($str));
  },
  sub {
    ok($h->count == 1);
  },
  sub {
    ok(scalar $h->latest == 1);
  },

  sub {
    ok($str eq $h->pop);
  },
  sub {
    ok($h->count == 0);
  },
  sub {
    ok(scalar $h->latest == 0);
  },

  sub {
    ok($h->push($str));
  },
  sub {
    ok($h->count == 1);
  },
  sub {
    ok(scalar $h->latest == 1);
  },

  sub {
    ok($h->clear);
  },
  sub {
    ok($h->count == 0);
  },
  sub {
    ok(scalar $h->latest == 0);
  },

  sub {
    $h->push($str);
    $h->push($str2);
    @latest = $h->latest;
    ok($latest[0] eq $str2);
  },

  sub {
    ok($latest[1] eq $str);
  },

  sub {
    @latest = $h->latest(1);
    ok(scalar @latest == 1);
  },
  sub {
    ok($latest[0] eq $str2);
  },

);

eval "use Test::Exception";
unless ($@) {
  push @tests, (

  );
}

plan tests => scalar @tests;

foreach my $test (@tests) { $test->(); }
