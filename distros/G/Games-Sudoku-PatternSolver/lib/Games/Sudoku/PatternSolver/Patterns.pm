package Games::Sudoku::PatternSolver::Patterns;

use strict;
use warnings;

require 5.10.0;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( init_patterns init_fields build_groups print_grid_from_vector get_intersections field_coordinates );
our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

use Bit::Vector;
use Time::HiRes;

my $VERBOSE = 0;

my $file_name = 'patterns_9x9.bin';

#####################################

my (%pos_to_offset, %offset_to_pos);

{
  my (%pattern_vectors_by_field, @all_patterns);

  sub init_patterns {
    # load from file or ask whether to create the patterns file

    return (\%pattern_vectors_by_field, \@all_patterns) if %pattern_vectors_by_field;

    my $module_path = __FILE__;
    $module_path =~ s|[^/]*$||;

    my $existing_file;
    if (-f './' . $file_name) {
      $existing_file = './' . $file_name;

    } elsif (-f $module_path . $file_name) {
      $existing_file = $module_path . $file_name;
    }

    if ($existing_file) {
      $file_name = $existing_file;

    } else {
      print "No pattern file '$file_name' exists in '$module_path' or in the current directory.\n";

      if (-w $module_path) {
        $file_name = $module_path . 'symbol_patterns.bin';

      } else {
        my $elevated = ($^O =~ /Win/i ? 'administrator' : 'sudo');
        
        print "Pls. consider to exit now and restart the program as $elevated, to have the file created in '$module_path' once and for all.\n";
        print "Or proceed to have it created in the current directory.\n";
        $file_name = './' . 'symbol_patterns.bin';
      }

      print "\nCreating the patterns should take < 1 minute and takes 0.5MB space.\nProceed? [Yn]:";
      my $answer = <STDIN>;
      exit 0 unless $answer =~ /Y/;

      my $t1 = Time::HiRes::time();
      my $fields = init_fields();

      # prevent an annoying and false OOM message, happening on windows when Ctrl-C is signalled while executing a nested loop
      my $old_handler = $SIG{'INT'};
      $SIG{'INT'} = sub {
        print "Exit on user request.\n";
        CORE::exit(0);
      };

      open my $Pattern_Handle, '>', $file_name or die $!;
      binmode $Pattern_Handle;

      my $written_count = 0;
      create_patterns($Pattern_Handle, 0, 0, Bit::Vector->new(81), Bit::Vector->new(81), \$written_count, $fields);
      close $Pattern_Handle;

      $SIG{'INT'} = $old_handler;
      printf("Creating and storing %d patterns took %.2f secs.\n", $written_count, Time::HiRes::time() - $t1);
    }

    my $file_size = -s $file_name;
    unless ($file_size and ! ($file_size % 46656)) {
      die "$file_name seems corrupted.";
    }

    my $bytes_per_pattern = $file_size / 46656;

    open my $Bin_File, '<', $file_name or die "Could not open the patterns binary at '$file_name':\n" . $!;
    binmode $Bin_File;
    my $load_count = 0;
    my $buffer = '';
    my $bytes  = 0;

    while ($bytes = sysread $Bin_File, $buffer, $bytes_per_pattern) {
      $bytes == $bytes_per_pattern or die "Unexpected number of $bytes bytes read (expected $bytes_per_pattern) after $load_count Patterns loaded.\n";
      my $vector = Bit::Vector->new(81);
      $vector->Block_Store($buffer);

      my @fields = $vector->Index_List_Read();
      foreach my $field_index (@fields) {
        push @{$pattern_vectors_by_field{$field_index}}, $vector;
      }
      push @all_patterns, $vector;
      $load_count++;
    }
    close $Bin_File;

    unless ($load_count == 46656) {
      die "Expected to load 46656 pattern vectors from '$file_name' (got $load_count instead).\n";
    }

    print("$load_count patterns loaded from $file_name\n") if $VERBOSE;

    return (\%pattern_vectors_by_field, \@all_patterns)
  }
}

# a recursive function that creates all possible distribution patterns and writes them to a binary file
sub create_patterns {
  my ($file_hdl, $start_index, $positioned_count, $positioned_vector, $coverage_vector, $written_count, $fields) = @_;

  # once we end up with an empty first row, we're finished
  return 0 if ($positioned_count == 0 && $start_index > 8);

  # the return value signals to the former/upper call whether proceeding with the recursion or to return
  my $return_value = 1;
  # find the next unobstructed cell, starting with the given index
  for (my $current_index = $start_index; $current_index <= 80; $current_index++) {
    next if $coverage_vector->bit_test($current_index);

    # a free cell was found - put it on the grid
    $positioned_vector->Bit_On($current_index);
    $positioned_count++;

    if ($positioned_count == 9) {
      # with 9 occupied cells the pattern is complete
      save_pattern($file_hdl, $positioned_vector);
      $$written_count++;
      if ($VERBOSE && ! ($$written_count % 1000)) {
        print $$written_count, ": ";
        print_grid_from_vector($positioned_vector);
      }

    } else {
      my $combined_vector = Bit::Vector->new(81);
      $combined_vector->Or($coverage_vector, $fields->[$current_index]{covers});

      $return_value = create_patterns($file_hdl, $current_index+1, $positioned_count, $positioned_vector, $combined_vector, $written_count, $fields)
        or last;
    }

    $positioned_vector->Bit_Off($current_index);
    $positioned_count--;
  }

  return $return_value
}

sub print_grid_from_vector {
  my ($vector) = shift;
  my ($symbol) = shift() // 'X';

  my $bits = $vector->to_Bin();
  $bits =~ s/0/ /g;
  $bits =~ s/1/$symbol/g;
  my @bits = reverse split //, $bits;

  print "\n-----------------\n";
  while (my @row = splice @bits, 0, 9) {
    print "@row\n";
  }
  print "-----------------\n";
}

sub save_pattern {
  my ($Out_File, $vector) = @_;

  # default string length for 81 bits is 12 bytes on Windows (3 words), 16 bytes on linux (2 words)
  # we unify by cutting to the minimum
  my $buffer = substr($vector->Block_Read(), 0, 11);
  my $written = syswrite($Out_File, $buffer);
  unless ($written == 11) {
    die "Unexpected number of $written bytes written (expected 11)\n";
  }
}

sub init_fields {
  # return arrayref with 81 field hashes, field->{covers} has Bit::Vector with constraint coverage field indexes set (row, column and block in one)

  my $offset = 0;

  unless (%pos_to_offset) {
	  foreach my $row ('A' .. 'I') {
	    foreach my $column ('1' .. '9') {
	      $pos_to_offset{$row . $column} = $offset++;
	    }
	  }
	  %offset_to_pos = reverse %pos_to_offset;
  }

  my %block_ranges = (
    A => ['A' .. 'C'],
    B => ['A' .. 'C'],
    C => ['A' .. 'C'],
    D => ['D' .. 'F'],
    E => ['D' .. 'F'],
    F => ['D' .. 'F'],
    G => ['G' .. 'I'],
    H => ['G' .. 'I'],
    I => ['G' .. 'I'],
    1 => ['1' .. '3'],
    2 => ['1' .. '3'],
    3 => ['1' .. '3'],
    4 => ['4' .. '6'],
    5 => ['4' .. '6'],
    6 => ['4' .. '6'],
    7 => ['7' .. '9'],
    8 => ['7' .. '9'],
    9 => ['7' .. '9'],
  );

  my @fields = ();
  $offset = 0;
  foreach my $row ('A' .. 'I') {
    foreach my $column ('1' .. '9') {
      push @fields, new_sudo_field($row, $column, \%pos_to_offset, \%block_ranges);
      $offset++;
    }
  }

  return \@fields
}

sub field_coordinates {
	return $offset_to_pos{$_[0]}
}

{
  # used in logic mode only
  my @groups;

  # returns an array of 27 arrays, each with the 9 indexes for any region (row, column or box)
  sub build_groups {
    use integer;

    return \@groups if @groups;

    foreach my $i (0..80) {
      my $ri = ($i / 9);
      push @{$groups[$ri]}, $i;
      my $ci = $i % 9 + 9;
      push @{$groups[$ci]}, $i;
      my $bi = 3 * ($i / 27) + ($i % 9 / 3) + 18;
      push @{$groups[$bi]}, $i;
    }

    return \@groups
  }

  my @intersections;

  # returns an array of 54 arrays, each with 3 defining vectors of size 81: 
  # [ 
  #   [intersection of a box with a row or column], 
  #   [excluded subset of same box], 
  #   [excluded subset of the row or column]
  # ]
  sub get_intersections {
    use integer;

    return \@intersections if @intersections;

    @groups or build_groups();

    foreach my $i (0..8) {
      # 1 box
      my $box_vector = Bit::Vector->new(81);
      $box_vector->Index_List_Store(@{$groups[$i + 18]});
      # 3 intersecting rows
      my $row_index = ($i / 3) * 3;
      my @rows = @groups[$row_index, $row_index + 1, $row_index + 2];
      # 3 intersecting columns
      my $column_index = ($i * 3 % 9) + 9;
      my @columns = @groups[$column_index, $column_index + 1, $column_index + 2];

      foreach my $line (@rows, @columns) {
        my $line_vector = Bit::Vector->new(81);
        $line_vector->Index_List_Store(@$line);

        my $intersection_vector = Bit::Vector->new(81);
        $intersection_vector->Intersection($box_vector, $line_vector);
        my $negation_vector_1 = Bit::Vector->new(81);
        $negation_vector_1->Difference($box_vector, $intersection_vector);
        my $negation_vector_2 = Bit::Vector->new(81);
        $negation_vector_2->Difference($line_vector, $intersection_vector);
        
        push @intersections, [$intersection_vector, $negation_vector_1, $negation_vector_2];
      }
    }

    return \@intersections
  }
}

#####################################################

sub new_sudo_field {
  my ($row, $col, $position_to_offset, $block_ranges) = @_;

  return {
    offset => $position_to_offset->{$row . $col},
    covers => _get_covered_cells_vector($row, $col, $position_to_offset, $block_ranges),
    candidates => {},
    value => undef,
  }
}

sub _get_covered_cells_vector {
  my ($row, $col, $position_to_offset, $block_ranges) = @_;

  my %conflicts = ();
  foreach my $ri ('A' .. 'I') {
    $conflicts{$ri . $col} = $position_to_offset->{$ri . $col};
  }
  foreach my $ci ('1' .. '9') {
    $conflicts{$row . $ci} = $position_to_offset->{$row . $ci};
  }
  foreach my $ri (@{$block_ranges->{$row}}) {
    foreach my $ci (@{$block_ranges->{$col}}) {
      $conflicts{$ri . $ci} = $position_to_offset->{$ri . $ci};
    }
  }

  my $covered_fields_vector = Bit::Vector->new(81);
  $covered_fields_vector->Index_List_Store(sort {$a <=> $b} values %conflicts);

  return $covered_fields_vector
}

1

__END__

=head1 NAME
 
Games::Sudoku::PatternSolver::Patterns - for internal use in L<Games::Sudoku::PatternSolver> only
 
=head1 DESCRIPTION
 
This sub module encompasses procedures that require a certain knowledge of the specific grid size and layout (currently only the standard 9x9).

The solve method does not know of the grid. For its backtracking algorithm it doesn't apply constraint rules to any individual field, 
but only uses bit vectors of length 81 and tries to combine them in order to arrive at a solution.

This sub module L<Games::Sudoku::PatternSolver::Patterns>

* reads the 46656 different patterns from a binary file, converts them into L<Bit::Vector> objects, which it returns in 2 different data structures: 
As an array, as well as a hash which holds them ordered in sets by a common field they share.
(If the binary file is missing, it will offer to create it from scratch; this lasts around 1 minute.)

* provides an array with 81 hashes representing the fields, initialized with some properties that help to maintain status (value, candidate lists, area covered, ...)

* provides the field indices in sets of groups (rows, columns and boxes). 
These are needed by the cheat mode, essentially in methods hidden_singles() and naked_singles(), which have to know which fields they must apply the rules to.
 
=head1 SEE ALSO
 
L<https://www.sudokuwiki.org/Pattern_Overlay>, L<https://sites.math.washington.edu/~morrow/mcm/team2280.pdf>
 
=head1 AUTHOR
 
Steffen Heinrich
 
=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
