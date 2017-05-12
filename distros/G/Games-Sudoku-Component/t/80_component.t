use strict;
use warnings;
use Test::More;

# If you want to see the outputs, set to 1.
my $Verbose = 0;

use Games::Sudoku::Component;

my ($c, $c2, $c3);
my @tests;

# These tests will be always executed.

@tests = (

  sub {
    $c = Games::Sudoku::Component->new;
    ok(ref $c eq 'Games::Sudoku::Component');
  },

  sub {
    $c2 = Games::Sudoku::Component->new(
      size => 16,
    );
    ok(ref $c2 eq 'Games::Sudoku::Component');
  },

  sub {
    $c3 = Games::Sudoku::Component->new(
      block_width  => 2,
      block_height => 3,
    );
    ok(ref $c3 eq 'Games::Sudoku::Component');
  },

  sub {
    diag "Tests hereafter may take minutes";
    $c->solve;
    if ($Verbose) {
      diag("\n(9x9)\n".$c->as_string);
    }
    ok(1);
  },

  sub {
    $c3->generate(blanks => 20);
    my $pzl = $c3->as_string;
    if ($Verbose) {
      diag("\n(6x6) create a new puzzle\n".$c3->as_string);
    }

    $c3->solve;
    if ($Verbose) {
      diag("\n(6x6) solved\n".$c3->as_string);
    }

    ok($c3->is_solved);
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
