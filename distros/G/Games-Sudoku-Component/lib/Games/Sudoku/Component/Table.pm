package Games::Sudoku::Component::Table;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.02';

  use base qw/Games::Sudoku::Component::Base/;
  use Games::Sudoku::Component::Table::Cell;
  use Games::Sudoku::Component::Table::Item;
  use Games::Sudoku::Component::Table::Permission;

  sub _initialize {
    my ($this, %options) = @_;

    my $size         = $this->{size};
    my $block_width  = $this->{block_width};
    my $block_height = $this->{block_height};

    my $perm = Games::Sudoku::Component::Table::Permission->new(
      block_width  => $block_width,
      block_height => $block_height,
    );

    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        my $cell_id = $this->_cell_id($row, $col);
        $this->{cells}->[$cell_id] =
          Games::Sudoku::Component::Table::Cell->new(
            row          => $row,
            col          => $col,
            block_width  => $block_width,
            block_height => $block_height,
            perm         => $perm,
          );
      }
    }
  }

  sub cells {
    my $this = shift;

    my @cells = @{ $this->{cells} };
  }

  sub cell {
    my ($this, $row, $col) = @_;

    my $cell_id = $this->_cell_id($row, $col);

    $this->{cells}->[$cell_id];
  }

  sub _cell_id {
    my ($this, $row, $col) = @_;

    croak "Invalid row: $row" unless $this->_check($row);
    croak "Invalid col: $col" unless $this->_check($col);

    ($row - 1) * $this->{size} + ($col - 1);
  }

  sub clear {
    my $this = shift;

    foreach my $cell ($this->cells) {
      $cell->unlock;
      $cell->value(0);
    }
  }

  sub find_next {
    my $this = shift;

    my $size = $this->{size};
    my $min  = $size + 1;
    my $next = undef;
    foreach my $cell ($this->cells) {
      my @allowed = $cell->allowed or next;

      if (scalar @allowed < $min) {
        $min  = scalar @allowed;
        $next = {
          row     => $cell->row,
          col     => $cell->col,
          allowed => \@allowed,
        };
      }
      last if $min == 1;
    }
    $next ? Games::Sudoku::Component::Table::Item->new($next) : undef;
  }

  sub find_all {
    my $this = shift;

    my $size = $this->{size};
    my $min  = $size + 1;
    my @all  = ();
    foreach my $cell ($this->cells) {
      my @allowed = $cell->allowed or next;
      if (scalar @allowed < $min) {
        @all = ();
        $min  = scalar @allowed;
      }
      if (scalar @allowed == $min) {
        push @all, Games::Sudoku::Component::Table::Item->new(
          row     => $cell->row,
          col     => $cell->col,
          allowed => \@allowed,
        );
      }
    }
    @all;
  }

  sub lock_all {
    my $this = shift;

    foreach my $cell ($this->cells) {
      $cell->lock if $cell->realvalue;
    }
  }

  sub unlock_all {
    my $this = shift;

    foreach my $cell ($this->cells) {
      $cell->unlock;
    }
  }

  sub check_tmpvalue {
    my $this = shift;

    my $size = $this->{size};

    foreach my $cell ($this->cells) {
      my $tmpvalue = $cell->tmpvalue or next;
      if ($cell->is_allowed($tmpvalue)) {
        $cell->value($tmpvalue);
      }
    }
  }

  sub num_of_finished {
    my $this = shift;

    my $sum = 0;
    foreach my $cell ($this->cells) {
      $sum++ if $cell->realvalue;
    }
    $sum;
  }

  sub is_finished {
    my $this = shift;

    foreach my $cell ($this->cells) {
      return 0 unless $cell->realvalue;
    }
    return 1;
  }

  sub as_string {
    my $this = shift;

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    my $separator = $options{separator} || ' ';
    my $break     = $options{linebreak} || "\n";

    my $size   = $this->{size};
    my $digit  = int(log($size) / log(10)) + 1;
    my $numfmt = '%'.$digit.'d';

    my @lines;
    foreach my $row (1..$size) {
      my @cells;
      foreach my $col (1..$size) {
        my $value = $this->cell($row, $col)->value;
        push @cells, sprintf($numfmt,$value);
      }
      push @lines, join $separator, @cells;
    }
    join $break, @lines;
  }

  sub as_HTML {
    my $this = shift;

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    my $border = $options{border}    || 1;
    my $break  = $options{linebreak} || "\n";

    my $size = $this->{size};

    my @lines;
    push @lines, qq{<table class="sudoku" border="$border">};
    foreach my $row (1..$size) {
      my @cells;
      foreach my $col (1..$size) {
        my $value = $this->cell($row, $col)->value;
        my $class;
        if ($options{color_by_block}) {
          $class =
            $this->_block_id($row, $col) % 2 ? 'odd' : 'even';
        }
        if ($options{color_by_cell}) {
          $class =
            $this->_cell_id($row, $col) % 2 ? 'odd' : 'even';
        }
        push @cells, 
          $class ? qq{<td class="$class">} : qq{<td>},
          qq{$value</td>};
      }
      my $tds = join '', @cells;
      push @lines, qq{<tr>$tds</tr>};
    }
    push @lines, qq{</table>};
    join $break, @lines;
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Table

=head1 SYNOPSIS

  use Games::Sudoku::Component::Table;

  # Let's create a default (9x9) table.

  my $t = Games::Sudoku::Component::Table->new;

  $t->

=head1 DESCRIPTION

=head1 METHODS

=head2 new (I<hash> or I<hashref>)

Creates an object. Options are:

=over 4

=item size

Specifies the size of a puzzle board (table). The default is 9.
Actually this value is assumed to be a square of another integer.

=item block_width

=item block_height

Specify the width/height of internal blocks, respectively.
(C<block_width> x C<block_height> = C<size>)

=back

=head2 cell (I<row>, I<column>)

Returns the specified cell object (L<Games::Sudoku::Component::Table::Cell>).

=head2 cells

Returns all the cell objects. Mainly used in C<foreach> loops.

=head2 check_tmpvalue

Checks permissions and if there are any values stored temporarily
but allowed now, store them again as real values.

=head2 clear

Clears all the values.

=head2 find_all

Finds all the cells that have least value possibilities.

=head2 find_next

Finds a cell that have least value possibilities.

=head2 is_finished

Returns true if all the cells have a real value.

=head2 num_of_finished

Returns a number of the cells that have a real value.

=head2 lock_all

Locks all the cells that have a real value, mainly to protect
the generated or loaded puzzle, so that players cannot, 
intentionally or unintentionally, change it.

=head2 unlock_all

Unlocks the cells. Use before creating or loading a new
puzzle.

=head2 as_string

Returns a loadable set of strings for the puzzle.

=head2 as_HTML

Returns an HTML table for the puzzle.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>

=item L<Games::Sudoku::Component::Table::Cell>

=item L<Games::Sudoku::Component::Table::Item>

=item L<Games::Sudoku::Component::Table::Permission>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
