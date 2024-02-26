package Games::Sudoku::PatternSolver::Generator;

use strict;
use warnings;

require 5.10.0;

use Games::Sudoku::PatternSolver::Patterns qw( init_patterns );
use Games::Sudoku::PatternSolver qw( solve print_grid );

use Bit::Vector;
use List::Util qw( shuffle );
use Time::HiRes ();

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( get_sudoku_builder get_grid_builder print_grid );
our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

our $VERBOSE     = 0;
our $LOOSE_MODE  = 0; # whether to allow puzzles to have < 8 different givens (still with an unique solution)

###########################################################

{
  my $grid_builder;

  # the grid at start doesn't matter for quality of the individual puzzle generated, 
  # but all puzzles generated from a single static grid share the same solution
  sub get_sudoku_builder {
    my ($start_grid_string, $start_with, $shuffle_symbols) = @_;

    set_solver_config();

    if ($start_grid_string) {
      my $sudoku = solve($start_grid_string)
        or return 0;

      my $sc = $sudoku->{solutionCount};

      if ($sc != 1) {
          printf "No way to reduce: Start grid %s and is invalid!\n", ($sc > 1) ? 'already has more than one solutions' : 'has NO solution';
        return 0;
      }
    }

    my $check_reducibility = ($start_grid_string && $start_grid_string =~ /[^1-9]/) ? 1 : 0;

    $start_with //= 40;
    $shuffle_symbols //= 1;

    $grid_builder ||= get_grid_builder();
    my $next_grid_str = $start_grid_string || &$grid_builder($shuffle_symbols);

    return sub {
      # given a possible solution, reduce the given values in random order until a proper sudoku is found that cannot be further reduced
      # (searching for a rating > 0.65 may take a while)

      # my $old_handler = $SIG{INT};
      # local $SIG{INT} = set_exit_handler(sub {print "BOOO!\n", &$old_handler() if ref($old_handler);});
      #my $solve_tries = 0;

      while (1) {
        print ">>> '$next_grid_str'\n" if $VERBOSE;
        # the initially given grid may have been fleshed out already
        my $grid = [split //, $next_grid_str];
        my @start_positions = map { $grid->[$_] =~ /[1-9]/ ? $_ : () } (0..$#$grid);
        #@start_positions >= 17 or die "Trying to reduce ", scalar(@start_positions), " givens from '$next_grid_str' is pretty much senseless.\n";
        my $to_drop = @start_positions - $start_with;
        $to_drop = 0 if $to_drop < 0;

        my $fields_to_try = $check_reducibility ? [@start_positions] : [shuffle @start_positions];

        # to get going, start from a certain depth
        my $dropped_fields = [];
        ($to_drop && !$check_reducibility) and do {
          drop_values($grid, $to_drop, $fields_to_try, $dropped_fields)
            or die "Couldn't drop $to_drop givens from the grid (@$grid).\n"
        };

        my $to_be_reduced;
        my $solution_count = 0;

        while ($solution_count < 2) {
          unless (drop_values($grid, 1, $fields_to_try, $dropped_fields)) {
            # tried to drop any single field that was left so far (bar 17), all leading to > 1 solutions => not further reducible => start over
            if ($to_be_reduced) {
              $next_grid_str = $start_grid_string || &$grid_builder($shuffle_symbols);
              $check_reducibility = 0;

              # this returns always a multiple of 40 (40 - 320 .. ??) why ???
              #print $solve_tries, " tries to solve were needed.\n";

              return $to_be_reduced;

            } elsif ($check_reducibility && !$to_be_reduced) {
              print "$solution_count: Start grid is minimal (could not be reduced): '$next_grid_str'\n";
              return 0;
            }
            last;
          }

          my $sudoku = solve($grid)
            or last;
          #$solve_tries++;
          $solution_count = $sudoku->{solutionCount};
          print "sc=$solution_count\n" if $VERBOSE;

          if ($solution_count == 1) {
            if ((!$to_be_reduced) || ($to_be_reduced->{uniqueGivens} > $sudoku->{uniqueGivens}) || ($to_be_reduced->{givensCount} >= $sudoku->{givensCount})) {
              # most interesting (reduced) puzzle found in the given start grid so far, 
              # still a subject to possible minimization
              $to_be_reduced = $sudoku;
            }
            next;
          }

          unless ($solution_count == 2) {
            warn "The current grid seems unsolvable!\n"; # . Dumper($sudoku);
            return 0;
          }

          # return to the former state (solution count == 1)
          # and try to achieve further reduction by dropping another value instead
          reinsert_last_value($grid, $dropped_fields);
          $solution_count = 1;
        }

        if ($check_reducibility) {
          $check_reducibility = 0;
          print "Reducibility check finished.\n";
          return 0;
        }

        $next_grid_str = $start_grid_string || &$grid_builder($shuffle_symbols);
      }

      return 0
    };
  }
}

sub drop_values {
  my ($grid, $to_drop, $fields_to_try, $dropped) = @_;

  my $dropped_count = 0;
  while ( $dropped_count < $to_drop ) {
    my $field_index = shift @$fields_to_try
      // return $dropped_count;
    my $symbol = $grid->[$field_index];
    print "dropped $symbol from $field_index\n" if $VERBOSE;
    die "Unexpected symbol '$symbol' in position $field_index!" if (!$symbol || $symbol eq '.');
    $grid->[$field_index] = '.';
    push @$dropped, [$field_index, $symbol];
    $dropped_count++;
  }

  return $dropped_count;
}

sub reinsert_last_value {
  # only puts the value back into the grid, does not return the index into the queue of drop candidates
  my ($grid, $dropped) = @_;

  my ($field_index, $symbol) = @{pop @$dropped} or die "No more grid positions to restore!";
  $grid->[$field_index] = $symbol;
  print "restored $symbol at $field_index\n" if $VERBOSE;
}

sub set_solver_config {
  # fastest way to find out if a sudoku has 0, 1, or more solutions
  $Games::Sudoku::PatternSolver::VERBOSE = $VERBOSE;
  $Games::Sudoku::PatternSolver::MAX_SOLUTIONS = 2;
  $Games::Sudoku::PatternSolver::LOOSE_MODE = $LOOSE_MODE;
  $Games::Sudoku::PatternSolver::USE_LOGIC = 1;
}

###########################################################

{
  my $patterns_by_field;

  sub get_grid_builder {

    $patterns_by_field ||= (init_patterns())[0];

    shuffle_pattern_arrays($patterns_by_field);

    # creating 81 iterators; each one iterates over a circular list with 5184 vectors in random order, which all have the specified field bit in common
    my %pattern_iterators = ();
    foreach my $field_index (keys %$patterns_by_field) {
      my $list = $patterns_by_field->{$field_index};
      my $index = -1;
      $pattern_iterators{$field_index} = sub {
        $index++;
        $index = 0 if $index > $#$list;
        return $list->[ $index ];
      };
    }

    my $test_vector = Bit::Vector->new(81);

    return sub {
      my $shuffle_symbols = shift() || 0;

      local $SIG{'INT'} = set_exit_handler();

      while (1) {
        my @placed_vectors = ();
        my $coverage_vector = Bit::Vector->new(81);
        my $placed = 0;
    
        while ($placed < 9) {
          $test_vector->Not($coverage_vector);
          my $any_empty_field = $test_vector->Min();

          my $could_place = 0;
          for (my $i = 0; $i < 5184; $i++) {
            my $pattern_vector = $pattern_iterators{$any_empty_field}();
            $test_vector->And($coverage_vector, $pattern_vector);

            if ($test_vector->is_empty()) {
              $coverage_vector->Or($coverage_vector, $pattern_vector);
              push @placed_vectors, $pattern_vector;
              $placed++;
              $could_place = 1;
              last;
            }
          }
          $could_place or last;
        }

        ($placed == 9) and return join '', prepare_grid(\@placed_vectors, $shuffle_symbols);
      }
    };
  }

  sub prepare_grid {
    # an arrayref with 9 complementing bit vectors
    my ($pattern_stack, $do_shuffle) = @_;

    # having 1-9 assigned to the 1st row makes spotting eventual repetitions more easy
    my @symbols = $do_shuffle ? (shuffle 1..9) : 1..9;
    
    my @chars = ();
    foreach my $pattern_vector (@$pattern_stack) {
      my $symbol = shift @symbols;
      $chars[$_] = $symbol for $pattern_vector->Index_List_Read();
    }

    return @chars
  }

  sub shuffle_pattern_arrays {
    my ($HashOfArrays) = @_;

    my $t1 = Time::HiRes::time();
    foreach my $key (keys %$HashOfArrays) {
      @{$HashOfArrays->{$key}} = shuffle( @{$HashOfArrays->{$key}} );
    }
    printf("Shuffling patterns took %0.4f secs.\n", Time::HiRes::time() - $t1) if $VERBOSE;
  }
}

sub set_exit_handler {
  my ($sub_to_execute) = @_;

  return $Games::Sudoku::PatternSolver::exitHandler = sub {
    #print "Exit on user request.\n";
    &$sub_to_execute if $sub_to_execute;
    #Time::HiRes::sleep 0.2;
    #CORE::exit(0);
  };
}

1

__END__

=head1 NAME

Games::Sudoku::PatternSolver::Generator - produces 9x9 Sudoku solution grids and 9x9 Sudoku puzzles

=head1 DESCRIPTION

This sub module uses the L<Games::Sudoku::PatternSolver>'s POM ability (Pattern Overlay Method) to build solution grids 
and enables L<PatternSolver::CPLogic|Games::Sudoku::PatternSolver/"PatternSolver::CPLogic"> to provide some indication of rating with the generated puzzles.

You may supply a grid of your liking to begin with, but it really doesn't matter because it is the (always) 
random order in which cell values are tried to be removed that make the essential difference, not the grid at launching point.

All Sudoku that are returned from the iterator I<builder> are well-posed (have a unique solution) and reduced (removing any of the givens would lead to > 1 solution).

=head1 METHODS

=over 1

=item * get_sudoku_builder()

 $sudoku_builder = get_sudoku_builder( start_grid, start_with, shuffle_symbols );

All 3 parameters are optional:

=over 2

=item start_grid (default none)

A grid string (81 chars) to start from, typically a complete solution as produced by the L<grid_builder|get_grid_builder>.

If a start grid is passed, the iterator will never replace it with another one. 
It will just be used over and over again, values removed in another random sequence.
The generated puzzles in this case, despite being all different in nature, will all share the same solution.

If you pass a grid with any missing values (a puzzle) it will just be checked and reported if the puzzle could be reduced any further and still be well-formed.   

=item start_with (default 40)

Number of random values to drop from the grid before checking the number of solutions for uniqueness kicks in.
A smaller number could lead to more unnecessary solution checking up front.
Too big a number might start the checking too often on a grid already overly reduced, which has more than one solution and has thus to start over.

=item shuffle_symbols (default true)

If false (and no start_grid was given), all puzzle's solutions will have the first row '123456789'. 

=back

The return value $sudoku_builder is a subref which on every call will return a result hash from its last call to L<Patternsolver::solve()|Games::Sudoku::PatternSolver/"solve()">:

 while (my $puzzle = &$sudoku_builder()) { 
 		... inspect and either reject or do something with $puzzle
 		print $puzzle->{strPuzzle}; 
 }

=item * get_grid_builder()

 $grid_builder = get_grid_builder();
 $solution_string = &$grid_builder( E<lt>shuffle_symbolsE<gt> ); 

=back

The iterator returned from get_grid_builder() can produce fully filled sudoku grids at a fairly high rate. 
Like the solver, it also uses plain overlay of random patterns (POM) and no biased methods. (As the Latin Squares would.) 
The grids are spread absolutely randomly across the Sudoku space.

=head1 EXPORTS

The module optionally exports get_sudoku_builder(), get_grid_builder() and provides the import tag ':all'.

=head1 SCRIPTS

=head2 sudogen

After installation of Games::Sudoku::PatternSolver this command line script should be in your path.
Flexible output options are available. Invoke C<E<gt>sudogen -h> for details.

=head1 SEE ALSO

L<Games::Sudoku::Html> play entire lists of standard sudoku interactively in your browser 

L<Games::Sudoku::Pdf> create pdf files from sixteen variants of 9x9 sudoku

L<https://www.sudokuwiki.org/Pattern_Overlay>, L<https://sites.math.washington.edu/~morrow/mcm/team2280.pdf>

=head1 AUTHOR

Steffen Heinrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
