package Games::Sudoku::PatternSolver;

our $VERSION = '0.06';

require 5.10.0;

use Bit::Vector qw();
use Time::HiRes qw();

use Games::Sudoku::PatternSolver::Patterns qw( init_patterns );

use strict;
use warnings;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( solve print_solution print_grid $VERBOSE $MAX_SOLUTIONS $LOOSE_MODE $USE_LOGIC );
our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

our $VERBOSE       = 0; # Informative output about the algorithm at work
our $MAX_SOLUTIONS = 2; # If 0, will do an exhaustive search which may run into memory problems on invalid puzzles. (Time overhead isn't very much, usally.)
our $LOOSE_MODE    = 1; # Finds the unique solution even for any sudoku with < 8 different givens, using letters as dropin symbols.
our $USE_LOGIC     = 1; # Try to fill in more givens before starting with patterns? Only uses simple area constraints (naked / hidden singles).

####################################################################
our $exit_handler;

{
  my ($patterns_by_field, $all_patterns) = init_patterns();

  sub solve {
    my $str_puzzle = ((ref $_[0]) ? flatten_input(@_) : join('', @_))
      or die " - dunno how to handle that input ... :-(\n";

    length($str_puzzle) == 81 or die "Puzzle input must be 81 chars long.\n";
    $str_puzzle =~ s/[ 0]/./g; # dots, not zeros for free cells

    print_grid($str_puzzle) if $VERBOSE;

    my $start_time = Time::HiRes::time();

    my $puzzle = new_puzzle(
      startTime => $start_time,
      strPuzzle => $str_puzzle
    ) or return 0;

    if ($USE_LOGIC) {
      require Games::Sudoku::PatternSolver::CPLogic;
      Games::Sudoku::PatternSolver::CPLogic::apply_logic( $puzzle )
        or return 0;

      my $logic_endtime = Time::HiRes::time();
      my $logic_time = $logic_endtime - $start_time;

      if ($puzzle->{logicFilled}) {
        printf("Logic mode provided %d more clues after %0.6f secs:", $puzzle->{logicFilled}, $logic_time) if $VERBOSE;

        $str_puzzle = $puzzle->{strPuzzleAfterLogic};
        print_grid($str_puzzle) if $VERBOSE;
      }

      if ($puzzle->{logicSolved}) {
        print "Puzzle was solved by logic alone (no backtracking with patterns needed)!\n" if $VERBOSE;
        $puzzle->{seconds} = $logic_time;
        $puzzle->{endTime} = $logic_endtime;


        ### TODO: Logic will only ever find the 1st solution. How to ensure a valid puzzle?
        return $puzzle
      }
    }

    set_exit_handler($exit_handler);

    solve_puzzle($puzzle, $patterns_by_field, $all_patterns)
      or return 0;

    restore_exit_handler();

    $puzzle->{endTime} = Time::HiRes::time();
    $puzzle->{seconds} = $puzzle->{endTime} - $puzzle->{startTime};

    sweep($puzzle);

    return $puzzle
  }
}

####################################################################

sub flatten_input {
  my $input = $_[0];

  my $ref = ref($input) or return 0;

  if ($ref eq 'ARRAY') {
    if ($#$input == 80 && (defined $input->[0]) && (not ref($input->[0]))) {
      return join '', @$input;
    }

    if ($#$input == 8 && (defined $input->[0]) && (ref($input->[0]) eq 'ARRAY') && ($#$input->[0] == 8)) {
      # AoA 9x9
      return join( '', map {join( '', @$_)} @$input);
    }
  }

  return undef
}

sub solve_puzzle {
  # apply backtracking
  my ($puzzle, $patterns_by_field, $all_patterns) = @_;

  my $symbol_vectors = $puzzle->{symbolVectors};
  my $symbol_counts  = $puzzle->{symbolCounts};

  #  so far, only symbols with at least 1 given appear here
  my @by_count = sort {(($symbol_counts->{$b} // 0) <=> ($symbol_counts->{$a} // 0)) || ($a cmp $b)} keys %$symbol_counts;

  my $no_clue_patterns;
  if ($USE_LOGIC) {
    foreach my $symbol (1 .. 9) {
      unless (exists $symbol_counts->{$symbol}) {
        # all clueless symbols share the same candidate positions
        my $no_clue_candidates = $puzzle->{candidateVectors}{$symbol};
        $no_clue_patterns = [map {$_->subset($no_clue_candidates) ? $_ : ()} @$all_patterns];
        last;
      }
    }
  }
  $no_clue_patterns ||= $all_patterns;

  if ($LOOSE_MODE && @by_count < 8) {
    # with less than 8 different givens, we have to stock up on distinguishing cell markers
    my @dropins = ('A' .. 'I');
    while (@by_count < 9) {
      my $dropin_symbol = shift @dropins;
      push @by_count, $dropin_symbol;
      $symbol_counts->{$dropin_symbol} = 0;
      $symbol_vectors->{$dropin_symbol} = Bit::Vector->new(81);
    }
  }
  $puzzle->{maxDepth} = $#by_count;

  my $test_vector = Bit::Vector->new(81);

  my %possible_solutions = ();
  my $invalid = 0;

  foreach my $symbol (@by_count) {
    my $symbol_vector = $symbol_vectors->{$symbol}
      or die "No vector for givens '$symbol'!\n";

    my $t2 = Time::HiRes::time();

    my $pre_filtered;

    if ($symbol_counts->{$symbol} == 9) {
      $pre_filtered = [$symbol_vector];

    } elsif ($symbol_counts->{$symbol} > 0) {
      # start with a reduced set of 5184 instead of 46656 possible distributions for this symbol
      my $any_given_field = $symbol_vector->Min();

      if ($USE_LOGIC) {
        # a chance to early prune patterns by subsetting them against their resp. candidate map
        my $allowed_positions = Bit::Vector->new(81);
        $allowed_positions->Or($symbol_vector, $puzzle->{candidateVectors}{$symbol});
        $pre_filtered = [map {$_->subset($allowed_positions) ? $_ : ()} @{$patterns_by_field->{$any_given_field}}];

      }	else {
        $pre_filtered = $patterns_by_field->{$any_given_field};
      }

    } else {
      # no givens -> a general prefilterung by shared candidates happened above
      $pre_filtered = $no_clue_patterns;
    }

    my @solutions = ();
    my $found = 0;
    my $omitted = 0;

    foreach my $pattern_vector (@$pre_filtered) {
      if ($symbol_vector->subset($pattern_vector)) {
        $found++;

        # early omittance of patterns wherever a non-conflicting pattern was not found for any of the former symbols
        my $outer = 1;
        foreach my $symbol_2 (keys %possible_solutions) {
          my $inner = 0;
          foreach my $pattern_vector_2 (@{$possible_solutions{$symbol_2}}) {
            $test_vector->And($pattern_vector, $pattern_vector_2);
            if ($test_vector->is_empty()) {
              # fits to at least one of that other symbol's pattern candidates
              # proceed to testing next symbol's candidates

              $inner = 1;
              last;
            }
          }

          unless($inner) {
            $outer = 0;
            last;
          }
        }

        if ($outer) {
          push @solutions, $pattern_vector;

        } else {
          $omitted++;
        }

      }
    }

    unless ($found - $omitted) {
      print "Givens '$symbol' have no pattern match, puzzle is invalid!\n";
      $invalid++;
    }

    $possible_solutions{$symbol} = \@solutions;
    printf(" Symbol '%s' (%d givens) %5d assigned -> %4d kept (%4d omitted) in %f secs\n", 
      $symbol, $symbol_counts->{$symbol}, $found, $found - $omitted, $omitted, Time::HiRes::time() - $t2) if $VERBOSE;
  }

  return 0 if $invalid;

  # in a 2nd step, further reduce the number of patterns
  print("Reverse elimination of pattern candidates:\n") if $VERBOSE;
  reverse_filter(\@by_count, \%possible_solutions, $symbol_counts);

  printf("Start backtracking for possible pattern combinations after %0.5f secs:\n", Time::HiRes::time() - $puzzle->{startTime}) if $VERBOSE;
  find_solutions(0, \@by_count, \%possible_solutions, Bit::Vector->new(81), {}, $puzzle);

  return 1
}

sub reverse_filter {
  # try to eliminate even more patterns by doing the fitting test in reverse order
  my ($by_count, $possible_solutions, $symbol_counts) = @_;

  my $test_vector = Bit::Vector->new(81);

  # starting out on patterns for the most abundant symbol, removing those who have no non-conflicting counterpart for any of the rarer symbols

  for (my $symbol_index_1 = 0; $symbol_index_1 < $#$by_count; $symbol_index_1++) {
    my $symbol_1    = $by_count->[$symbol_index_1];
    my $solutions_1 = $possible_solutions->{$symbol_1};
    my $found   = 0;
    my $omitted = 0;

    my $t2 = Time::HiRes::time();
    my @filtered_solutions = ();

    foreach my $pattern_vector_1 (@$solutions_1) {
      $found++;

      my $outer = 1;
      for (my $symbol_index_2 = $symbol_index_1 + 1; $symbol_index_2 <= $#$by_count; $symbol_index_2++) {
        my $symbol_2    = $by_count->[$symbol_index_2];
        my $solutions_2 = $possible_solutions->{$symbol_2};

        my $inner = 0;
        foreach my $pattern_vector_2 (@$solutions_2) {
          $test_vector->And($pattern_vector_1, $pattern_vector_2);
          if ($test_vector->is_empty()) {
            # fits to at least one of that 2nd symbol's pattern candidates
            # proceed to testing the outer symbol's next candidate
            $inner = 1;
            last;
          }
        }

        unless($inner) {
          $outer = 0;
          last;
        }
      }

      if ($outer) {
        push @filtered_solutions, $pattern_vector_1;

      } else {
        $omitted++;
      }
    }
    $possible_solutions->{$symbol_1} = \@filtered_solutions;
    printf(" Symbol '%s' (%d givens) %4d -> %4d were kept (%4d omitted) in %f secs\n", 
      $symbol_1, $symbol_counts->{$symbol_1}, $found, $found - $omitted, $omitted, Time::HiRes::time() - $t2) if $VERBOSE;
  }
}

# the essential recursive function of the solver
# the return value signals whether to abort (false) or proceed (true) with the backtracking
sub find_solutions {
  my ($depth, $symbols, $possibles, $coverage_vector, $current_pattern_vectors, $puzzle) = @_;

  $depth > $puzzle->{maxDepth}
    and die sprintf("FIX ME: depth=$depth (maxDepth = %d)\n", $puzzle->{maxDepth});

  my $symbol = $symbols->[$depth];

  my $test_vector = Bit::Vector->new(81);
  foreach my $pattern_vector (@{$possibles->{$symbol}}) {
    $test_vector->And($coverage_vector, $pattern_vector);

    if ($test_vector->is_empty()) {
      # no conflicts
      $current_pattern_vectors->{$symbol} = $pattern_vector;
      $coverage_vector->Or($coverage_vector, $pattern_vector);

      if ($depth == $puzzle->{maxDepth}) {
        # is it a proper new solution?
        # because patterns are tried in random order and one pattern can be tried for different symbols, repetitive solutions have to be avoided
        my $newSolutionKey = solution_is_new($puzzle, $current_pattern_vectors);
        if ($newSolutionKey) {
          my $solution_string = prepare_solution_string($symbols, $current_pattern_vectors);
          add_solution($puzzle, $newSolutionKey, $solution_string);
          print_solution($solution_string, $puzzle->{solutionCount}, $puzzle->{startTime}) if $VERBOSE;
          check_for_max_solutions($puzzle->{solutionCount}) or return 0;
        }

      } else {
        # descent, and bubble up a false return value
        find_solutions ($depth+1, $symbols, $possibles, $coverage_vector, $current_pattern_vectors, $puzzle)
          or return 0;
      }
      # remove this pattern and proceed on the same level
      delete $current_pattern_vectors->{$symbol};
      $coverage_vector->Xor($coverage_vector, $pattern_vector);
    }
  }

  return 1
}

sub prepare_solution_string {
  my ($symbols, $pattern_vectors) = @_;

  my @chars = ('0') x 81;

  for (my $symbol_index = 0; $symbol_index < 9; $symbol_index++) {
    my $symbol = $symbols->[$symbol_index] // last;
    my $symbol_vector = $pattern_vectors->{$symbol} or last;
    $chars[$_] = $symbol for $symbol_vector->Index_List_Read();
  }

  return join '', @chars
}

sub print_solution {
  my ($solution, $solution_nr, $startTime) = @_;
  
  printf("\nSolution #%d after %f secs:", $solution_nr, Time::HiRes::time() - $startTime) if $VERBOSE && $solution_nr && $startTime;

  $solution =~ s/[^1-9A-I]/ /g;
  print_grid($solution);
}

sub print_grid {
  my $grid_string = shift;
  my @symbols = split //, $grid_string;

  my $row_count = 0;
  print "\n-------------------------\n";
  while (my @row = splice @symbols, 0, 9) {
    while (my @triple = splice @row, 0, 3) {
      print "| @triple ";
    }
    print(++$row_count % 3 ? "|\n" : "|\n-------------------------\n");
  }
}

sub check_for_max_solutions {
  my $solution_count = shift;

  if ($MAX_SOLUTIONS) {
    if ($solution_count >= $MAX_SOLUTIONS) {
      print "\$MAX_SOLUTIONS=$MAX_SOLUTIONS are reached - exiting.\n" if $VERBOSE;
      return 0;
    }
  }

  return 1
}

{
  # prevent error messages in windows, if user break happens inside a nested call
  my $old_handler;

  sub set_exit_handler {
    my ($sub_to_execute) = @_;
    return if $Games::Sudoku::PatternSolver::exitHandler;
    $old_handler and return;

    $old_handler = $SIG{'INT'};
    $SIG{'INT'} = $Games::Sudoku::PatternSolver::exitHandler = sub {
      print "Exit on user request.\n";
      &$sub_to_execute if $sub_to_execute;
      CORE::exit(0);
    };
  }

  sub restore_exit_handler {
    if ($old_handler) {
      $SIG{'INT'} = $old_handler;
      $old_handler = undef;
    }
  }
}

###############################################################

sub new_puzzle {

  return _read_puzzle({
    startTime      => 0,
    strPuzzle      => undef,
    @_,

    endTime        => 0,
    seconds        => 0,

    # properties and state keeping
    maxDepth       => undef,
    symbolVectors  => undef,
    givensCount    => undef,
    uniqueGivens   => undef,
    countsByGivens => undef,  # at start, on puzzle init
    symbolCounts   => undef,  # a copy that reflects the current state

    # logic mode related, might get used for ratings
    logicFilled    => 0,
    candidatesDropped => 0,
    logicSteps     => [],
    logicSolved    => 0,

    # backtracking related
    rejectedCount  => 0,
    knownSolutions => {},

    solutions      => [],
    solutionCount  => 0,
  })
}

sub _read_puzzle {
  my ($puzzle) = @_;

  my $puzzle_string = $puzzle->{strPuzzle}
    or die "Named param 'strPuzzle' must be passed to new_puzzle()";

  my $givens = 0;
  my %counts = ();
  my %symbol_vectors = ();
  @symbol_vectors{1..9} = Bit::Vector->new(81, 9);

  my $field_offset = 0;
  foreach my $symbol (split //, $puzzle_string) {
    if ($symbol =~ /[1-9]/) {
      $givens++;
      $counts{$symbol}++;
      $symbol_vectors{$symbol}->Bit_On($field_offset);
    }
    $field_offset++;
  }

  $puzzle->{symbolVectors}  = \%symbol_vectors;
  $puzzle->{givensCount}    = $givens;
  $puzzle->{uniqueGivens}   = scalar keys %counts;
  $puzzle->{countsByGivens} = \%counts;
  $puzzle->{symbolCounts}   = {%counts};

  print("Puzzle has $puzzle->{uniqueGivens} different symbols.\n") if $VERBOSE;

  if ($puzzle->{uniqueGivens} < 5) {
    warn "Puzzle has $puzzle->{uniqueGivens} different symbols and cannot have a unique solution.\n";
    return 0;

  } elsif ($puzzle->{uniqueGivens} < 8 && ! $LOOSE_MODE) {
    warn "Puzzle has $puzzle->{uniqueGivens} different symbols and may be solved with \$LOOSE_MODE=1 only.\n";
    return 0;
  }

  if ($puzzle->{givensCount} < 17) {
    warn "Puzzle has $puzzle->{givensCount} givens while 17 is regarded as bare minimum for a unique solution.\n";
    return 0;
  }

  return $puzzle
}

sub sweep {
  my ($puzzle, $thorough) = @_;

  $thorough //= 1;

  if ($thorough) {
    delete $puzzle->{$_} for qw(
      maxDepth
      symbolVectors
      symbolCounts
      rejectedCount
      knownSolutions
    );

  } else {
    $puzzle->{knownSolutions} = {};
    $puzzle->{symbolVectors}  = undef;
  }

  return $puzzle
}

sub add_solution {
  my ($puzzle, $key, $solution) = @_;

  $puzzle->{knownSolutions}{$key} = undef;
  push @{$puzzle->{solutions}}, $solution;

  return $puzzle->{solutionCount}++
}

sub solution_is_new {
  my ($puzzle, $vectors) = @_;

  # the hash values are the current Bit::Vector objects, found to satisfy the puzzle
  # here we create a short, unique key with the addresses of these up to 9 vectors
  my $key = join '|', sort map {/0x(.+?)\)$/} values %$vectors;

  if (exists $puzzle->{knownSolutions}{$key}) {
    $puzzle->{rejectedCount}++;
    return undef;
  }

  return $key
}

1

