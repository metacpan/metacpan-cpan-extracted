package Games::Sudoku::Component::Controller;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.02';

  use Games::Sudoku::Component::Table;
  use Games::Sudoku::Component::Table::Item;
  use Games::Sudoku::Component::Controller::History;
  use Games::Sudoku::Component::Controller::Status;

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    $this->{table} = Games::Sudoku::Component::Table->new(
      size         => $options{size},
      block_width  => $options{block_width},
      block_height => $options{block_height},
    );

    my $size = $this->{table}->size;

    $this->{status}  = Games::Sudoku::Component::Controller::Status->new(
      rewind_max => $options{rewind_max} || $size,
      retry_max  => $options{retry_max}  || int(sqrt($size)),
    );
    $this->{history} = Games::Sudoku::Component::Controller::History->new;

    $this;
  }

  sub table   { $_[0]->{table}; }
  sub history { $_[0]->{history}; }
  sub status  { $_[0]->{status}; }

  sub clear {
    my $this = shift;

    $this->{table}->clear;
    $this->{history}->clear;
    $this->{status}->clear;
  }

  sub load {
    my $this = shift;

    require Games::Sudoku::Component::Controller::Loader;
    my @cells = Games::Sudoku::Component::Controller::Loader->load(@_);

    my $table = $this->{table};
    foreach my $item (@cells) {
      $table->cell($item->row,$item->col)->value($item->value);
      $table->cell($item->row,$item->col)->lock if $item->value;
    }
    $this->{history}->clear;
  }

  sub set {
    my ($this, $row, $col, $value) = @_;

    my $table   = $this->{table};
    my @allowed = $table->cell($row,$col)->allowed;

    $table->cell($row,$col)->value($value);

    $table->check_tmpvalue($row,$col);

    my $item = Games::Sudoku::Component::Table::Item->new(
      row     => $row,
      col     => $col,
      allowed => \@allowed,
      value   => $value,
    );

    $this->{history}->push($item);
  }

  sub find_and_set {
    my ($this, $item) = @_;

    my $table = $this->{table};

    $item ||= $table->find_next;

    return 0 unless defined $item;

    $table->cell($item->row,$item->col)->value($item->random_value);

    $this->{history}->push($item);

    return $item;
  }

  sub find_hints { $_[0]->{table}->find_all; }

  sub next {
    my $this = shift;

    my $status = $this->{status};

    $status->turn_to_ok if $status->is_null;

    my $result;
    if ($status->is_ok) {
      $result = $this->find_and_set;

      unless ($result) {
        if ($this->{table}->is_finished) {
          $status->turn_to_solved;
        }
        else {
          if ($status->can_rewind) {
            $status->turn_to_rewind;
          }
          else {
            if ($status->can_retry) {
              $this->rewind_all;
              $status->turn_to_ok;
            }
            else {
              $status->turn_to_giveup;
            }
          }
        }
      }
    }
    if ($status->is_rewind) {
      $result = $this->rewind;

      if ($result) {
        if ($result->allowed) {
          $this->find_and_set($result);
          $status->turn_to_ok;
        }
      }
      else {
        if ($status->can_retry) {
          $status->turn_to_ok;
        }
        else {
          $status->turn_to_giveup;
        }
      }
    }
    return $result;
  }

  sub solve {
    my $this = shift;

    $this->{status}->clear;

    until($this->{status}->is_finished) {
      $this->next;
    }
  }

  sub make_blank {
    my ($this, $count) = @_;

    my $table = $this->{table};
    my $size  = $table->size;

    croak "Invalid count: $count"
      if $count > ($size ** 2) || $count < 1;

    $table->lock_all;

    foreach my $id (1..$count) {
      my $row = int(rand($size)) + 1;
      my $col = int(rand($size)) + 1;
      redo unless $table->cell($row,$col)->value;
      $table->cell($row,$col)->unlock;
      my $prev = $table->cell($row,$col)->value;
      $table->cell($row,$col)->value(0);
    }

    $this->{status}->clear;
    $this->{history}->clear;
  }

  sub rewind {
    my $this = shift;

    my $table = $this->{table};
    my $item  = $this->{history}->pop;

    $table->cell($item->row,$item->col)->value(0) if defined $item;

    $item;
  }

  sub rewind_all {
    my $this = shift;

    foreach (1..$this->{history}->count) {
      $this->rewind;
    }
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Controller

=head1 SYNOPSIS

  use Games::Sudoku::Component::Controller;

  # Let's create a default 9x9 puzzle.

  my $c = Games::Sudoku::Component::Controller->new;

  # Solve the (currently blank) puzzle

  $c->solve;

  # Then, make blanks

  $c->make_blank(50);

  # Voila! Let's see.

  $c->table->as_HTML;

  # If all you want is the result, just solve.

  $c->solve;

  # If you want to do something, then try this loop.

  until ($c->status->is_solved) {

    # Solve only one step forward (or backward)

    $c->next;

    # do something, such as updating a session file, printing
    # a result, etc.
  }

=head1 DESCRIPTION

This is a main controller.

=head1 ACCESSOR

=head2 table

=head2 history

=head2 status

Returns L<Games::Sudoku::Component::Table>, 
L<Games::Sudoku::::Component::Controller::History>, 
L<Games::Sudoku::::Component::Controller::Status> object respectively.

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

=head2 load (I<string> or I<hash> or I<hashref>)

Loads and parses puzzle data from file or string. If there is only one 
argument, it is assumed to be raw puzzle data.

=over 4

  $sudoku->load(<<'EOT');
  4 . . . . 1
  2 1 . . 5 .
  3 5 1 2 6 .
  1 . . . 3 .
  6 . . 5 1 2
  5 . . . 4 6
  EOT

=back

If the argument seems to be a hash, data will be loaded from
$hash{filename} (or $hash{file}, for short).

=head2 next

Does what should be done next, i.e. finds a cell that has
least value possibilities, decides which value should be 
set (or should be tried), rewinds a step while rewinding.

=head2 find_and_set

Finds a cell that has least value possibilities and decides
which value should be set (or should be tried).

=head2 set (I<row>, I<column>, I<value>)

Tries to set a value of cell(I<row>, I<column>) to I<value>.
Though the value is not allowed in fact, the cell stores
the value temporarily.

=head2 find_hints

Finds all the cells that have least value possibilities.

=head2 solve

Solves the puzzle that you generated or loaded. You can solve
a 'blank' puzzle.

=head2 make_blank (I<integer>)

Makes specified number of blanks for the (solved) puzzle
randomly. This is useful but the puzzles made through this
method may have several solutions.

=head2 rewind

Rewinds a stacked step. Mainly used when the solver is stuck.
However, this is only useful when possible solutions are few.
When there are too much solutions, C<rewind_all> may be a better
choice.

=head2 rewind_all

Rewinds all the steps stacked in the history stack, i.e. restores
the generated or loaded puzzle afresh. Mainly used when the solver
is stuck several times. As C<next> (or C<find_and_set>) sets
values a bit randomly, it tends to be faster to retry from the
start than to rewind again and again.

=head2 clear

Clears all (the generated or loaded puzzle, and history stack).

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>

=item L<Games::Sudoku::Component::Controller::History>

=item L<Games::Sudoku::Component::Controller::Loader>

=item L<Games::Sudoku::Component::Controller::Status>

=item L<Games::Sudoku::Component::Table>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
