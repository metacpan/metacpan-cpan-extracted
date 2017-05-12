use Test::More qw[no_plan];
use strict;
$^W = 1;

use lib qw[lib ../lib];

BEGIN {
  use_ok 'Devel::Caller::Perl', qw[called_args];
}

my @orig_args = qw[Hello there little red riding hood];

sub test_cw {
  my @args = called_args;
  my $args = called_args;
  ok eq_array( \@orig_args, \@args ), 'list context correct';
  ok eq_array( \@orig_args, $args ),  'scalar context correct';
}

sub foo {
  test_cw();
}

foo @orig_args;
