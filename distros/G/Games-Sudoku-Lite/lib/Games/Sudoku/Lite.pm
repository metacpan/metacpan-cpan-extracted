# Games::Sudoku::Lite -- Fast and simple Sudoku puzzle solver
#
# Copyright (C) 2006  Bob O'Neill.
# All rights reserved.
#
# This code is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package Games::Sudoku::Lite;

use strict;
use warnings;

our $VERSION = '0.41';

my %Config = (
    width           => 9,
    height          => 9,
    square_height   => 3,
    square_width    => 3,
    possible_values => [1..9],
    DEBUG           => 0,
);
# If we need to brute force a solution, we'll set $Retrying to 1.
# Certain warnings about inconsistent puzzle states, sent through
# my_warn(), will be skipped.
my $Retrying = 0;

sub my_warn {
    warn @_ if not $Retrying;
}

sub new {
    my $class  = shift;
    my $board  = shift;
    my $config = shift;
    if (defined $config and ref $config eq 'HASH') {
       for (keys %$config) {
           $Config{$_} = $config->{$_};
       }
    }
    my $self = {};
    $self->{board} = _txt_to_array($board);

    return bless $self, $class;
}

sub solve {
    my $self = shift;

    my $success = $self->_algorithm();
    for (2..@{$Config{possible_values}})
    {
        last if $success;
        $success = $self->_retry($_);
    }

    return $success;
}

sub _algorithm {
    my $self = shift;

    # Accurate naming at the expense of brevity
    my $prev_possibilities = $Config{width} * $Config{height} * @{$Config{possible_values}};
    my $possibilities_left = $self->_possibilities_left();

    while ($possibilities_left and $possibilities_left < $prev_possibilities)
    {
        $self->_row_rule();
        $self->_column_rule();
        $self->_square_rule();

        $prev_possibilities = $possibilities_left;
        $possibilities_left = $self->_possibilities_left();
        warn "Possibilities Remaining: $possibilities_left\n" if $Config{DEBUG};
    }

    # Clarity at the expense of conciseness
    my $success = ($possibilities_left == 0);
    return $success;
}

sub _retry {
    my $self  = shift;
    my $limit = shift;
    $Retrying = 1;

    # Start guessing.
    my @coords;
    my $y = 0;
    # Make a list of all unknowns
    for my $row (@{$self->{board}})
    {
        my $x = 0;
        for my $cell (@$row)
        {
            push @coords, [$x, $y] if ref $cell;
            $x++;
        }
        $y++;
    }
    # For each undetermined point, make each possible guess and re-run
    # the algorithm.  This assumes that the puzzle is solvable with one
    # particular correct guess and doesn't attempt to make multiple
    # consecutive guesses.
    my $saved_board = _copy($self->{board});
    for my $point (@coords)
    {
        my ($x, $y) = @$point;

        my $point = $self->{board}[$y][$x];
        my @choices;
        if (ref $point eq 'ARRAY') {
            @choices = @{ $point };
        }
        else {
            @choices = $point;
        }
        # Only try the easiest guesses.
        next unless @choices == $limit;

        for my $choice (@choices) {
            # Make the guess.
            $self->{board}[$x][$y] = $choice;

            my $success = $self->_algorithm();

            if ($success) {
                my $errors = $self->validate();
                if ($errors) {
                    # we'll have to guess again...
                    $self->{board} = _copy($saved_board);
                }
                else {
                    # We guessed right.
                    return 1;
                }
            }
            else {
                # we'll have to guess again...
                $self->{board} = _copy($saved_board);
            }
        }
    }
    $self->{board} = _copy($saved_board);
    # No more guesses to make :(
    return 0;
}

sub solution {
    my $self = shift;
    my $x = _array_to_txt($self->{board});
    return $x;
}

sub _array_to_txt {
    my $array = shift || [];
    my $board = '';
    my $j = 0;
    for my $row (@$array)
    {
        $j++;
        if ($Config{DEBUG})
        {
            for my $r (@$row) {
               # Make a copy of $r so we don't change $self->{board}
               my $string = $r;
                  $string = join '', @$r if ref $r;
               # Print all remaining possible values for each column
               my $width  = @{$Config{possible_values}} + 1;
               $board .= sprintf "%${width}s", $string;
            }
            $board .= "\n";
        }
        else
        {
            my $i = 0;
            for my $r (@$row) {
                $i++;
                # Make a copy of $r so we don't change $self->{board}
                my $string = $r;
                   $string = '.' if ref $string;
                $board .= $string;
                # Experimenting with another output style.
                if ($Config{DEBUG}) {
                    $board .= '|' unless $i % $Config{square_width};
                }
            }
            $board .= "\n";
            # Experimenting with another output style.
            if ($Config{DEBUG})
            {
                $board .= ('-' x ($Config{width} + $Config{width}/$Config{square_width})). "\n" unless $j % $Config{square_height};
            }
        }
    }

    return $board;
}

sub _txt_to_array {
    my $board = shift;
    my @array;
    my $i = 0;
    for my $line (split /\n/, $board)
    {
        my @row = split //, $line, $Config{width};
        for my $i (0..@row-1)
        {
            my $cell = $row[$i];
            if ($cell eq '.')
            {
                $cell = [@{$Config{possible_values}}];
            }
            $row[$i] = $cell;
        }
        push @array, [@row];

        $i++;
        warn "ERROR: Too Many Rows in Board" if $i > $Config{height};
    }
    return \@array;
}

sub _possibilities_left {
    my $self = shift;
    my $possibilities_left = 0;
    for my $row (@{$self->{board}})
    {
        for my $cell (@$row)
        {
            $possibilities_left += @$cell if ref $cell;
        }
    }
    return $possibilities_left;
}

sub _row_rule {
    my $self = shift;

    for my $row_num (1..$Config{height})
    {
        my @row   = $self->_get_row($row_num);
        my %homes = _reduce_possibilities(\@row);
        $self->_set_row($row_num, @row);
        $self->_send_home(row_num => $row_num, homes => \%homes);
    }
    return;
}

sub _column_rule {
    my $self = shift;

    for my $column_num (1..$Config{width})
    {
        my @column = $self->_get_column($column_num);
        my %homes  = _reduce_possibilities(\@column);
        $self->_set_column($column_num, @column);
        $self->_send_home(column_num => $column_num, homes => \%homes);
    }
    return;
}

sub _square_rule {
    my $self = shift;

    my $h_squares     = $Config{width}  / $Config{square_width};
    my $v_squares     = $Config{height} / $Config{square_height};
    my $total_squares = $h_squares * $v_squares;

    for my $square_num (1..$total_squares)
    {
        my $square = $self->_get_square($square_num);
        my %homes  = _reduce_possibilities($square);
        $self->_set_square($square_num, $square);
        $self->_send_home(square_num => $square_num, homes => \%homes);
    }
    return;
}


#
# Inputs:  A row, column or square of cells
# Does:    Changes (in-place) the cells by removing from possibilities the
#          values that are already:
#             a) solved in this group of cells
#             b) determined to be elsewhere
# Returns: The number of homes available for each digit
# 
sub _reduce_possibilities {
    my $cells = shift;
    my @known_values = grep { not ref $_ } @$cells;

    # a)
    for my $cell (@$cells)
    {
        warn "blank cell?? '$cell'" if not defined $cell or $cell eq '';
        if (not ref $cell) {
            next;
        }

        $cell = [_take_out($cell, [@known_values])];
        my_warn "ERROR: No possibilities left for this cell" unless @$cell;
        $cell = $cell->[0] if @$cell == 1; # Cell is solved.
    }
    my %homes = _compute_homes($cells);
    # b)
    my %appears;
    for my $cell (@$cells)
    {
        # Skip solved cells.
        next if not ref $cell;

        # Map values (1..9) to cell contents
        if (ref $cell) {
            my $values = join '|', sort @$cell;
            for my $n (@$cell) {
                $appears{$n}{$values}++;
            }
        }
    }
    for my $n (keys %appears) {
        for my $values (keys %{$appears{$n}}) {

            my $appearances = $appears{$n}{$values};
            # Could be [3,8],[3,8] but no other occurrences of 3 or 8.
            next unless $appearances < $homes{$n};

            my @values = split /\|/, $values;
            # We don't have anything to do unless we see the same set
            # of values at least twice.
            next unless @values > 1;

            if ($appearances >= @values) {
                my_warn "Something's probably wrong ($appearances > ".@values.")"
                  if $appearances > @values;
                # For example, '3' appears in two cells of two members,
                # such as [3,8],[3,8].
                #
                # Therefore, we can remove '3' from the possibilities for
                # every other cell in this group.
                #
                # We'll remove it from every cell that doesn't match these
                # values.

                for my $cell (@$cells) {
                    next if not ref $cell; # skip solved cells

                    my $my_values = join '|', sort @$cell;
                    next if $my_values eq $values;    # skip [3,8]
                    my $saved = @$cell;
                    $cell = [_take_out($cell, [$n])]; # [2,3,7] -> [2,7]
                }
            }
        }
    }

    # Recompute and return.
    %homes = _compute_homes($cells);
    return %homes;
}

sub _compute_homes
{
    my $cells = shift;
    my %homes;
    for my $cell (@$cells)
    {
        if (not ref $cell) {
            $homes{$cell}++;
            next;
        }
        $homes{$_}++ for @$cell;
    }
    return %homes;
}

sub _take_out {
    my @old      = @{shift()};
    my @take_out = @{shift()};
    my @new;
    for my $o (@old) {
        push @new, $o unless grep /^$o$/, @take_out;
    }
    return @new;
}

sub _send_home {
    my $self       = shift;
    my %params     = @_;
    my %homes      = %{$params{homes}};
    my $row_num    = $params{row_num};
    my $column_num = $params{column_num};
    my $square_num = $params{square_num};

    if (not keys %homes == @{$Config{possible_values}})
    {
        my_warn "ERROR: missing value in ". join('|', keys %homes);
        my_warn $self->solution();
    }

    for my $n (keys %homes) {
        my_warn "ERROR: no home for $n"
            ." (row=$row_num; column=$column_num; square=$square_num)"
            unless $homes{$n};

        if ($homes{$n} == 1) {
            if ($row_num) {
                my @row = $self->_get_row($row_num);
                $self->_find_a_home($n, \@row);
                $self->_set_row($row_num, @row);
            }
            elsif ($column_num) {
                my @column = $self->_get_column($column_num);
                $self->_find_a_home($n, \@column);
                $self->_set_column($column_num, @column);
            }
            elsif ($square_num) {
                my $square = $self->_get_square($square_num);
                $self->_find_a_home($n, $square);
                $self->_set_square($square_num, $square);
            }
            else {
                my_warn "ERROR: missing row_num/column_num/square_num value";
            }
        }
    }
    return;
}

sub _find_a_home {
    my $self  = shift;
    my $n     = shift;
    my $cells = shift || [];

    for my $cell (@$cells)
    {
        next if not ref $cell;
        if (grep /^$n$/, @$cell)
        {
            # Cell is solved.
            $cell = $n;
            last;
        }
    }
    return;
}

sub _get_row {
    my $self    = shift;
    my $row_num = shift;

    return @{$self->{board}[$row_num-1]};
}

sub _set_row {
    my $self    = shift;
    my $row_num = shift;
    my @row     = @_;

    $self->{board}[$row_num-1] = \@row;
    return;
}

sub _get_column {
    my $self       = shift;
    my $column_num = shift;
    my @column;

    for my $row (@{$self->{board}}) {
        push @column, $row->[$column_num-1];
    }

    return @column;
}

sub _set_column {
    my $self       = shift;
    my $column_num = shift;
    my @column     = @_;

    my $i = 0;
    for my $row (@{$self->{board}}) {
        $row->[$column_num-1] = $column[$i++];
    }
    return;
}

sub _get_square {
    my $self = shift;
    return $self->_get_or_set_square(@_); # reduces duplication
}

sub _set_square {
    my $self = shift;
    $self->_get_or_set_square(@_); # ditto
    return;
}

sub _get_or_set_square {
    my $self       = shift;
    my $square_num = shift;
    my $set_square = shift; # Pass a square in to set, otherwise will get

    my $h_squares = $Config{width}  / $Config{square_width};
    my $v_squares = $Config{height} / $Config{square_height};

    my $column_num = ($square_num - 1) % $h_squares + 1; # 1, 2, 3
    my $row_num    = _round_up($square_num/$h_squares);  # 1, 2, 3

    my $x_min = ($column_num - 1) * $Config{square_width}; # 0..8
    my $x_max = $x_min + $Config{square_width} - 1;        # 0..8
    my $y_min = ($row_num - 1) * $Config{square_height};   # 0..8
    my $y_max = $y_min + $Config{square_height} - 1;       # 0..8

    my @square;
    for my $y ($y_min..$y_max)
    {
        for my $x ($x_min..$x_max)
        {
            if ($set_square)
            {
                my $next = shift @$set_square;
                $self->{board}[$y][$x] = $next;
            }
            push @square, $self->{board}[$y][$x];
        }
    }

    return \@square;
}

sub _round_up {
    my $float     = shift;
    my $int_float = int $float;
    if ($int_float == $float) {
        return $int_float;
    }
    else {
        return $int_float + 1;
    }
}

sub validate {
    my $self = shift;
    my $errors = '';
    # validate rows.
    for my $row_num (1..$Config{height})
    {
        my @row = $self->_get_row($row_num);
        $errors .= _validate(\@row, "row $row_num");
    }
    # validate columns.
    for my $column_num (1..$Config{width})
    {
        my @column = $self->_get_column($column_num);
        $errors .= _validate(\@column, "column $column_num");
    }
    # validate squares.
    my $h_squares     = $Config{width}  / $Config{square_width};
    my $v_squares     = $Config{height} / $Config{square_height};
    my $total_squares = $h_squares * $v_squares;
    for my $square_num (1..$total_squares)
    {
        my $square = $self->_get_square($square_num);
        $errors .= _validate($square, "square $square_num");
    }
    return $errors;
}

sub _validate {
    my @cells = @{shift()};
    my $where = shift;
    my $errors = '';
    my %seen;
    $seen{$_}++ for @cells;
    for (keys %seen)
    {
        $errors .= "$where: Seen $_ too many times ($seen{$_} times)\n" if $seen{$_} != 1;
    }
    for (@{$Config{possible_values}})
    {
        $errors .= "$where: Didn't see $_\n" if not $seen{$_};
    }
    return $errors;
}

sub _copy
{
    my $ref = shift;
    warn "This is for copying references" if not ref $ref;

    if (ref $ref eq 'ARRAY')
    {
        my @values = @$ref;
        my @new_array;
        for my $value (@values)
        {
            if (ref $value)
            {
                push @new_array, _copy($value);
            }
            else
            {
                push @new_array, $value;
            }
        }
        return \@new_array;
    }
}

1; # of rings to rule them all.

__END__

=head1 NAME

Games::Sudoku::Lite -- Fast and simple Sudoku puzzle solver

=head1 SYNOPSIS

 use Games::Sudoku::Lite;

 my $board = <<END;
 3....8.2.
 .....9...
 ..27.5...
 24.5..8..
 .85.74..6
 .3....94.
 1.4....72
 ..69...5.
 .7.612..9
 END

 my $puzzle = Games::Sudoku::Lite->new($board);
    $puzzle->solve;

 print $puzzle->solution, "\n";

=head1 AUTHOR

Bob O'Neill, E<lt>bobo@cpan.orgE<gt>
 
=head1 ACKNOWLEDGEMENTS

Thanks to:

Brian Helterline for help in solving 6x6 puzzles and making
this more configurable.

Jean-Pierre Vidal for providing puzzles that the previous
version could not solve.

Eugene Kulesha (L<http://search.cpan.org/~jset/>)
for providing a test that I could not initially pass and for
the idea of keeping test data in data files rather than in
the tests themselves.

Tom Wyant (L<http://search.cpan.org/~wyant/>))
for the idea of using dots rather than spaces to represent
unknowns in the text representation of the board.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bob O'Neill.
All rights reserved.

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<perl>.

=back

=cut
