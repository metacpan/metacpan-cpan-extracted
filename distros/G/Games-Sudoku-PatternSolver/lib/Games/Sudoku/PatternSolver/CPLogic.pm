package Games::Sudoku::PatternSolver::CPLogic;

use strict;
use warnings;

require 5.06.0;

use Bit::Vector;
use Algorithm::Combinatorics qw(combinations);

# array with 81 hashes representing the fields; field->{covers} returns Bit::Vector with constraint coverage field indexes set (row, column and block in one)
my $Fields = Games::Sudoku::PatternSolver::Patterns::init_fields();
# an array of 27 arrays, holding the 9 indexes sharing any row, column or box 
my $Groups = Games::Sudoku::PatternSolver::Patterns::build_groups();
my $Group_Vectors = [map {my $v = Bit::Vector->new(81); $v->Index_List_Store(@$_); $v} @$Groups];

# an array of 54 (9x6) arrays with 3 Bit::Vector(s) each: [intersection of box with row or column], [remainder of box], [remainder of row or column] 
my $Intersections = Games::Sudoku::PatternSolver::Patterns::get_intersections();
# to be initialized with each symbol's candidates map as a Bit::Vector  

# ugly: a 2nd data structure with the candidates, that has to be created and maintained  
# only for use by advanced logic (locked_sets, locked_candidates)
my %Candidate_Vectors = ();
my $steps_taken;
my $RECORD_STEPS = 0;

sub apply_logic {
  my ($puzzle) = @_;

  my $puzzle_string = $puzzle->{strPuzzle};
  $puzzle_string =~ s/[^1-9]/0/g;
  
  $_->{candidates} = {}, $_->{value} = undef for @$Fields; # clear Field objects

  my $index_arrays_by_symbol     = {}; # symbol -> array with all fields (offset) where the symbol is the given value
  my $coverage_vectors_by_symbol = {}; # do we really need this? currently only for populating and deleting the candidates

  my $missing_count = 81;
  my $field_index = -1;
  foreach my $symbol (split //, $puzzle_string) {
    $field_index++;
    $symbol =~ /[1-9]/ or next;
    $missing_count--;
    push @{$index_arrays_by_symbol->{$symbol}}, $field_index;
    $Fields->[$field_index]{value} = $symbol;
  }

  foreach my $symbol (keys %$index_arrays_by_symbol) {
    my $covers = Bit::Vector->new(81);
    $covers->Or($covers, $Fields->[$_]{covers}) for $puzzle->{symbolVectors}{$symbol}->Index_List_Read();
    $coverage_vectors_by_symbol->{$symbol} = $covers;
  }

  foreach my $symbol (1..9) {
    # rem: $coverage_vectors_by_symbol used only here and in put_value(), would be nice to drop
    my $area_vector = $coverage_vectors_by_symbol->{$symbol} ||= Bit::Vector->new(81);
    my $candidate_vector = Bit::Vector->new(81);

    foreach my $field (@$Fields) {
      next if $field->{value};
      unless ($area_vector->bit_test($field->{offset})) {
        $field->{candidates}{$symbol} = 1;
        $candidate_vector->Bit_On($field->{offset});
      }
    }
    $Candidate_Vectors{$symbol} = $candidate_vector;
  }

  my $filled_total = 0;
  my $dropped_total = 0;
  my $dropping_candidates_did_help = 0;
  $steps_taken = [];

  while ($missing_count) {
    my $last_filled = 0;

    $last_filled += hidden_singles($puzzle);
    $last_filled +=  naked_singles($puzzle);

    unless ($last_filled) {
      #### last; # skip further efforts to reduce the candidates (advanced methods)

      my $last_dropped = 0;

      $last_dropped += locked_sets($puzzle);
      $last_dropped += locked_candidates($puzzle);

      $last_dropped or last;

      $dropped_total += $last_dropped;

    } elsif ($dropped_total) {
      $dropping_candidates_did_help = 1;
    }

    $filled_total += $last_filled;
    $missing_count -= $last_filled;
  }

  my $puzzle_string_2;
  if ($filled_total) {
    $puzzle_string_2 = join '', map {$Fields->[$_]{value} || '.'} (0..80);

    # are 8 symbols completely filled in and 1 symbol entirely missing?
    if ($missing_count == 9 && $puzzle->{uniqueGivens} == 8) {
      for (1..9) {
        next if $puzzle_string_2 =~ /$_/;

        my $added = $puzzle_string_2 =~ s/\./$_/g;
        $filled_total  += $added;
        $missing_count -= $added;
        # did not yet find a sudoku where that happend
        warn "'$puzzle_string': Logic mode finished by adding '$_' as the last symbol.\n";

        last;
      }
    }

    $puzzle->{strPuzzleAfterLogic} = $puzzle_string_2;
  }

  $puzzle->{logicFilled} = $filled_total;
  $puzzle->{candidatesDropped} = $dropped_total;
  $puzzle->{candidateVectors} = \%Candidate_Vectors;
  $puzzle->{droppingCandidatesDidHelp} = $dropping_candidates_did_help;
  $puzzle->{logicSteps} = $steps_taken;

  if ($missing_count) {
    $puzzle->{logicSolved} = 0;

  } elsif ($filled_total) {

    $puzzle->{logicSolved} = 1;
    push @{$puzzle->{solutions}}, $puzzle_string_2;
    $puzzle->{solutionCount} = 1;

  } else {
    print "Puzzle was no puzzle!\n" if $Games::Sudoku::PatternSolver::VERBOSE;
  }

  return $puzzle
}

sub hidden_singles {
  my ($puzzle) = @_;

  print "hidden_singles()\n" if $Games::Sudoku::PatternSolver::VERBOSE;

  my $symbol_counts = $puzzle->{symbolCounts};
  my $filled = 0;
  # moving symbols with most givens upfront probably wouldn't yield
  foreach my $symbol (1..9) {
    next if (exists($symbol_counts->{$symbol}) && ($symbol_counts->{$symbol} == 9));

    GROUP:
    foreach my $g (@$Groups) {
      my $only_position = undef;
      foreach my $field_index (@$g) {
        next unless exists $Fields->[$field_index]{candidates}{$symbol};
        next GROUP if defined $only_position;
        $only_position = $field_index;
      }
        
      if (defined $only_position) {
        put_value($only_position, $symbol, $puzzle);
        $filled++;
        push @$steps_taken, 'HS_V_' . $symbol . '_' . Games::Sudoku::PatternSolver::Patterns::field_coordinates($only_position)
          if $RECORD_STEPS;
      }
    }
  }
  
  return $filled;
}

sub naked_singles {
  my ($puzzle) = @_;

  print "naked_singles()\n" if $Games::Sudoku::PatternSolver::VERBOSE;

  my $filled = 0;
  foreach my $field (@$Fields) {
    $field->{value} and next;
    my @candidates = keys %{$field->{candidates}};
    if (@candidates == 1) {
      my $field_index = $field->{offset};
      my $symbol = shift @candidates;
      put_value($field_index, $symbol, $puzzle);
      $filled++;
      push @$steps_taken, 'NS_V_' . $symbol . '_' . Games::Sudoku::PatternSolver::Patterns::field_coordinates($field_index)
        if $RECORD_STEPS;
    }
  }
  
  return $filled;
}

# Because the naked and hidden sets of candidates occuring within a group always are mutually complementary 
# we have to implement search for only one of the two types.
# Going for the hidden pairs, triples and quads seems like it can be done more easily with our candidates and groups vectors. 
# example with a hidden quad set: 816573294392......4572.9..6941...5687854961236238...4.279.....1138....7.564....82
sub locked_sets {
  my ($puzzle) = @_;

  print "locked_sets()\n" if $Games::Sudoku::PatternSolver::VERBOSE;

  my $symbol_counts = $puzzle->{symbolCounts};
  my $dropped = 0;
  my $test_vector = Bit::Vector->new(81);

  for (my $group_index = 0; $group_index < 27; $group_index++) {
    my $group_array  = $Groups->[$group_index];
    my $group_vector = $Group_Vectors->[$group_index];

    my %candidate_counts  = ();
    my %candidate_vectors = ();
    foreach my $field_index (@$group_array) {
      $Fields->[$field_index]{value} and next;
      foreach my $candidate_symbol (keys %{$Fields->[$field_index]{candidates}}) {
        $candidate_counts{$candidate_symbol}++;
      }
    }

    # stay with candidates which occupy 2-4 cells in the group
    foreach my $candidate_symbol (keys %candidate_counts) {
      my $candidate_count = $candidate_counts{$candidate_symbol};
      if ($candidate_count > 4 || $candidate_count == 1) {
        delete $candidate_counts{$candidate_symbol};

      } else {
        my $candidate_in_group_vector = Bit::Vector->new(81);
        $candidate_in_group_vector->And($group_vector, $Candidate_Vectors{$candidate_symbol});
        $candidate_vectors{$candidate_symbol} = $candidate_in_group_vector;
      }
    }
    my @candidates_in_group = keys %candidate_counts;
    next if @candidates_in_group < 4;
    
    # iterate over all possible combinations of the 2-4 different candidates found above
    foreach my $k_size (4, 3, 2) {
      next if @candidates_in_group <= $k_size;
      my $combination_iterator = combinations(\@candidates_in_group, $k_size);
      while (my $candidates_combination = $combination_iterator->next) {
        $test_vector->Empty();
        foreach my $candidate (@$candidates_combination) {
          $test_vector->Or($test_vector, $candidate_vectors{$candidate});        
        }

        # do the k different candidates occupy exactly k cells?
        my @combined_fields = $test_vector->Index_List_Read();
        if (@combined_fields == $k_size) {
          print "group $group_index, hidden_set (@$candidates_combination) in cells: [@combined_fields]\n" if $Games::Sudoku::PatternSolver::VERBOSE;
          # got a hidden set
          # now we must look for any other candidates in the same cells, which we can eliminate
          my %hidden_candidates = ();
          @hidden_candidates{@$candidates_combination} = undef;

          foreach my $field_index (@combined_fields) {
            foreach my $candidate_symbol (keys %{$Fields->[$field_index]{candidates}}) {
              unless (exists $hidden_candidates{$candidate_symbol}) {
                drop_candidate($field_index, $candidate_symbol);
                $dropped++;
				        push @$steps_taken, 'LS_D_' . $candidate_symbol . '_' . Games::Sudoku::PatternSolver::Patterns::field_coordinates($field_index)
				          if $RECORD_STEPS;
              }
            }
          }
        }
      }  
    }
  }

  return $dropped;
}

sub locked_candidates {
  my ($puzzle) = @_;

  print "locked_candidates()\n" if $Games::Sudoku::PatternSolver::VERBOSE;

  my $symbol_counts = $puzzle->{symbolCounts};
  my $dropped = 0;
  my $in_box_vector = Bit::Vector->new(81);
  my $in_line_vector = Bit::Vector->new(81);

  foreach my $set (@$Intersections) {
    my ($intersection_vector, $boxremainder_vector, $lineremainder_vector) = @$set;

    my %candidates_in_intersection = ();
    foreach my $field_index ($intersection_vector->Index_List_Read()) {
      my $intersection_field = $Fields->[$field_index];
      $candidates_in_intersection{$_}++ for keys %{$intersection_field->{candidates}};
    }

    foreach my $symbol (keys %candidates_in_intersection) {
      my $candidate_vector = $Candidate_Vectors{$symbol};

      $in_box_vector->And($candidate_vector, $boxremainder_vector);
      my @further_box_matches = $in_box_vector->Index_List_Read();

      $in_line_vector->And($candidate_vector, $lineremainder_vector);
      my @further_line_matches = $in_line_vector->Index_List_Read();

      if (@further_box_matches && ! @further_line_matches) {
        # case of 'Claiming'
        foreach my $field_index (@further_box_matches) {
          drop_candidate($field_index, $symbol);
          $dropped++;
					push @$steps_taken, 'LC_D_' . $symbol . '_' . Games::Sudoku::PatternSolver::Patterns::field_coordinates($field_index)
					  if $RECORD_STEPS;
        }
      
      } elsif (@further_line_matches && ! @further_box_matches) {
        # case of 'Pointing' aka 'Box / Line reduction'
        foreach my $field_index (@further_line_matches) {
          drop_candidate($field_index, $symbol);
          $dropped++;
					push @$steps_taken, 'LC_D_' . $symbol . '_' . Games::Sudoku::PatternSolver::Patterns::field_coordinates($field_index)
					  if $RECORD_STEPS;
        }
      }
    }
  }
  
  return $dropped;
}

sub drop_candidate {
  my ($index, $value) = @_;

  print "Dropping candidate '$value' from $index\n" if $Games::Sudoku::PatternSolver::VERBOSE;

  my $field = $Fields->[$index];
  delete $field->{candidates}{$value};
  $Candidate_Vectors{$value}->Bit_Off($index);
}

sub put_value {
  my ($index, $value, $puzzle) = @_;

  print "Putting '$value' in $index\n" if $Games::Sudoku::PatternSolver::VERBOSE;

  my $field = $Fields->[$index];
  $field->{value}      = $value;
  $field->{candidates} = {};

  # drop candidates
  my $area_vector = $field->{covers};
  # same value candidates from covered fields 
  delete $Fields->[$_]{candidates}{$value} for $area_vector->Index_List_Read();
  # and also in the symbol's map of remaining candidates
  $Candidate_Vectors{$value}->Bit_Off($_) for $area_vector->Index_List_Read();
  # and in all candidate maps the one occupied place
  $_->Bit_Off($index) for values %Candidate_Vectors;

  $puzzle->{symbolVectors}{$value}->Bit_On($index);
  $puzzle->{symbolCounts}{$value}++;
}

1
