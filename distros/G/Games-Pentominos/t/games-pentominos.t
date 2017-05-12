#!perl

use Test::More tests => 2;

BEGIN {
  use_ok( 'Games::Pentominos' );
}

diag( "Testing Games::Pentominos $Games::Pentominos::VERSION, Perl $], $^X" );

my $board = <<"";
.xxxxxx.
xxxxxxxx
xxxxxxxx
xxxxxxxx
xxxxxxxx
xxxxxxxx
xxxxxxxx
.xxxxxx.

my $solution;

my $callback = sub {
  my ($placed, $n_solutions, $t_solution, $t_tot) = @_;
  $solution = $placed;
  return 0; # stop searching
};


Games::Pentominos->solve($board, $callback);

like($solution, qr/\A\.\w{6}\./, "solution");
