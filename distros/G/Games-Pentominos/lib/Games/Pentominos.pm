#======================================================================
package Games::Pentominos; # see doc at end of file
#======================================================================
our $VERSION = "1.0";
use strict;
use warnings;
use Time::HiRes     qw/time/;
use List::MoreUtils qw/uniq/;

# work mostly with global vars because this is fastest than parameter-passing
our    # because accessed from eval
   $board;             # cells remaining to be filled 
my $placed;            # cells filled so far
my $print_solution;    # callback for printing a solution
my ($t_ini, $t_tot);   # times in milliseconds
my $n_solutions;       # how many solutions found
my %substitutions;     # a coderef for each pentomino/permutation

# description of the 12 pentominos. Each of them has a labelling letter,
# a number of permutations, and for each permutation a rectangle describing
# the pentomino shape. Occupied cells are shown with an 'x', untouched cells
# with a '.' (this character explicitly chosen so that in regexes it will
# match anything except a newline character).

my %pentominos = (
  F => [8, qw/.xx xx. x.. ..x .x. .x. .x. .x.
              xx. .xx xxx xxx xxx xxx xx. .xx
              .x. .x. .x. .x. x.. ..x .xx xx./],

  I => [2, qw/xxxxx x
              ..... x
              ..... x
              ..... x
              ..... x/],

  L => [4, qw/xxxx xxxx x. .x
              x... ...x x. .x
              .... .... x. .x
              .... .... xx xx/],

  P => [8, qw/xx xx xxx xxx x. .x xx. .xx
              xx xx xx. .xx xx xx xxx xxx
              x. .x ... ... xx xx ... .../],

  S => [8, qw/xx.. ..xx xxx. .xxx x. .x x. .x
              .xxx xxx. ..xx xx.. xx xx x. .x
              .... .... .... .... .x x. xx xx
              .... .... .... .... .x x. .x x./],

  T => [4, qw/xxx .x. x.. ..x
              .x. .x. xxx xxx
              .x. xxx x.. ..x/],

  U => [4, qw/xxx x.x xx xx
              x.x xxx x. .x
              ... ... xx xx/],

  V => [4, qw/xxx xxx x.. ..x
              x.. ..x x.. ..x
              x.. ..x xxx xxx/],

  W => [4, qw/xx. .xx x.. ..x
              .xx xx. xx. .xx
              ..x x.. .xx xx./],

  X => [1, qw/.x.
              xxx
              .x./],

  Y => [8, qw/.x x. .x x. xxxx xxxx ..x. .x..
              xx xx .x x. .x.. ..x. xxxx xxxx
              .x x. xx xx .... .... .... ....
              .x x. .x x. .... .... .... ..../],

  Z => [4, qw/xx. .xx x.. ..x
              .x. .x. xxx xxx
              .xx xx. ..x x../],
);



#----------------------------------------------------------------------
sub solve {
#----------------------------------------------------------------------
  my ($self, $submitted_board, $submitted_callback) = @_;

  # initialize globals
  ($board, $placed) = ($submitted_board, "");
  $print_solution   = $submitted_callback;

  # check if $board meets requirements
  my $n_cells = ($board =~ tr/x//);
  my ($board_n_cols, @others) = uniq map length, ($board =~ m/.+/g);
  $n_cells == 60   or die "board does not have 60 empty cells noted as 'x'";
  not @others      or die "board has rows of different lengths";

  # check if callback is a coderef
  ref $print_solution eq 'CODE' or die "improper callback for solutions";

  # compile the substitution subroutines
  _compile_substitutions($board_n_cols);

  # anything up to first free cell goes to "placed"
  $board =~ s/^([^x]+)// and $placed .= $1;

  # start computing solutions
  $t_ini       = time;
  $t_tot       = 0;
  $n_solutions = 0;
  _place_pentomino(keys %pentominos);
}



#----------------------------------------------------------------------
sub _compile_substitutions {
#----------------------------------------------------------------------
  my ($board_n_cols) = @_; # how many columns in each row

  %substitutions = ();
  while (my ($letter, $array_ref) = each %pentominos) {

    my $n_permutations = $array_ref->[0]; # how many possible layouts 
    my $n_rows         = (@$array_ref-1) / $n_permutations;

    for my $perm_id (0 .. $n_permutations-1) {

      # gather data rows for that permutation
      my @rows      = map {$array_ref->[$_ * $n_permutations + $perm_id + 1]}
                          (0..$n_rows-1);
      my $n_cols    = length ($rows[0]);

      # construct regex to match that permutation
      # NOTE: \D below is just a convenience for char class [FILPSTUVWXYZx.\n]
      my $skip_to_next_row = sprintf "\\D{%d}", $board_n_cols + 1 - $n_cols;
      my $regex            = join $skip_to_next_row, @rows;

      # remove everything before or after the touched cells
      $regex =~ s/^[^x]+//;
      $regex =~ s/[^x]+$//;

      # add capture brackets in regex
      $regex =~ s/([^x]+)/($1)/g;

      # substitution string : replace 'x' by letter 
      #                       and brackets by captured groups
      (my $subst = $regex) =~ s/x/$letter/g;
      my $num_paren = 1;
      $subst =~ s/\(.*?\)/'$'.$num_paren++/eg; 

      # compile a sub performing the substitution 
      push @{$substitutions{$letter}}, 
        eval qq{sub {\$board =~ s/^$regex/$subst/}};
    }
  }
}


#----------------------------------------------------------------------
sub _place_pentomino { # the recursive algorithm
#----------------------------------------------------------------------
  # my @letters = @_; # commented out for speed (avoiding copy)

  my ($board_ini, $placed_ini) = ($board, $placed);

  foreach my $letter (@_) {
    foreach my $substitution (@{$substitutions{$letter}}) {
      if ($substitution->()) { # try to apply this pentomino to $board

        # anything up to next free cell goes to "placed"
        $board =~ s/^([^x]+)// and $placed .= $1;

        if (!$board) { # no more free cells, so this is a solution
          my $t_solution = time - $t_ini;
          $t_tot       += $t_solution;
          $n_solutions += 1;
          $print_solution->($placed, $n_solutions, $t_solution, $t_tot)
            or return; # stop searching if callback did not return true
          $t_ini = time;
        }
        else {
          _place_pentomino(grep {$_ ne $letter} @_)
            or return; 
        }

        # restore to previous state (remove pentomino from board)
        ($board, $placed) = ($board_ini, $placed_ini);
      }
    }
  }
  return 1; # continue searching
}


__END__

=head1 NAME

Games::Pentominos - solving the pentominos paving puzzle

=head1 SYNOPSIS

  use Games::Pentominos;

  my $board = "xxxxxxxxxx\n" x 6;
  my $solution_printer = sub {
   my ($placed, $n_solutions, $t_solution, $t_tot) = @_;
   printf "Solution %d\n%s\n", $n_solutions, $placed;
   return 1; # continue searching
  }

  Games::Pentominos->solve($board, $solution_printer);

=head1 DESCRIPTION

A pentomino is a surface formed from 5 adjacent squares; there are
exactly 12 such pieces, named by letters [FILPSTUVWXYZ] because their
shape is similar to those letters.  The puzzle is to fit them all in a
board of 60 cells; the most common board is a rectangle of 6x10 cells.

This module contains the solving algorithm, while the companion
program L<pentominos> contains the command-line interface
to launch the solver.


=head1 METHODS

=head2 solve

  Games::Pentominos->solve($board, $solution_callback);

The C<$board> argument should contain a string
representing the board on which to place pentominos. The string must
be a concatenation of rows of equal length, each with a final
C<"\n">. Empty cells are represented by an C<'x'>. Cells outside the
paving surface -- if any -- are represented by a dot. So for
exemple the U-shaped board is represented as :

  xxxx....xxxx
  xxxx....xxxx
  xxxx....xxxx
  xxxxxxxxxxxx
  xxxxxxxxxxxx
  xxxxxxxxxxxx

The C<$solution_callback> is called whenever a solution is found, as follows

  $should_continue = $callback->($placed, $n_solutions, $t_solution, $t_tot);

where 

=over

=item *

C<$placed> is a string representing the board, in which every cell 'x'
has been replaced by the letter name of the pentomino filling that cell.
As in the input board, cells outside the
paving surface -- if any -- are represented by a dot.

=item *

C<$n_solutions> is a counter of solutions

=item *

C<$t_solution> is a float containing the number of seconds and milliseconds
spent computing this solution

=item *

C<$t_tot> is the total time spent for all solutions so far.

=back

If the return value from the callback is true, then the computation 
continues to find a new solution; otherwise it stops.


=head1 ALGORITHM

For every possible permutation of each pentomino,
we compile a subroutine that just attempts to perform a regular
expression substitution on the board, replacing empty cells 
by the pentomino name.

At any point in time, the global variable C<$board> contains the
description of cells remaining to be filled, while C<$placed> contains
the description of cells already filled.  The algorithm starts at the
first character in C<$board> (the first empty cell), and iterates over
pentominos and permutations until finding a successful substitution
operation. It then removes all initial non-empty cells (storing them
in C<$placed>), and recurses to place the next pentomino. Recursion
stops when C<$board> is empty (this is a solution). 

=head1 AUTHOR

Laurent Dami, C<< <laurent.d...@justice.ge.ch> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Laurent Dami, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

