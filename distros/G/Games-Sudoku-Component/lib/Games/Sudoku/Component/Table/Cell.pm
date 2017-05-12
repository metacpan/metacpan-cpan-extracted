package Games::Sudoku::Component::Table::Cell;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.01';

  use base qw/Games::Sudoku::Component::Base/;

  sub _initialize {
    my ($this, %options) = @_;

    $this->{row}  = $this->_check($options{row});
    $this->{col}  = $this->_check($options{col});

    my $perm = $options{permission} || $options{perm};

    croak 'Invalid perm: '.(ref $perm)
      if ref $perm ne 'Games::Sudoku::Component::Table::Permission';

    $this->{perm} = $perm;

    $this->{value}    = 0;
    $this->{tmpvalue} = 0;

    $this->{locked}   = 0;
  }

  sub row       { $_[0]->{row} }
  sub col       { $_[0]->{col} }
  sub realvalue { $_[0]->{value} || 0; }
  sub tmpvalue  { $_[0]->{tmpvalue}; }

  sub lock      { $_[0]->{locked} = 1; }
  sub unlock    { $_[0]->{locked} = 0; }
  sub is_locked { $_[0]->{locked}; }

  sub value {
    my ($this, $value) = @_;

    if (defined $value && !$this->{locked}) {
      my $old = $this->{value};
      my $row = $this->{row};
      my $col = $this->{col};

      if ($old) {
        $this->{value} = 0;
        $this->{perm}->allow($row,$col,$old);
      }

      if ($value && !$this->is_allowed($value)) {
        $this->{tmpvalue} = $this->_check($value);
        $value = 0;
      }
      else {
        $this->{tmpvalue} = 0;
        $this->{value} = $this->_check0($value);
      }

      $this->{perm}->deny($row,$col,$value) if $value;
    }

    $this->{tmpvalue} || $this->{value} || 0;
  }

  sub is_allowed {
    my ($this, $value) = @_;

    return $this->{perm}->result(
      result => 0,
      reason => 'has other value'
    ) if $this->{value};

    $this->{perm}->is_allowed($this->{row},$this->{col},$value);
  }

  sub allowed {
    my $this = shift;

    return () if $this->{value};

    my @allowed = $this->{perm}->allowed($this->{row},$this->{col});
  }

  sub _permissions { $_[0]->{perm}; }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Table::Cell

=head1 SYNOPSIS

  my $table = Games::Sudoku::Component::Table->new;

  foreach my $cell ($table->cells) {

    # Now $cell is a Games::Sudoku::Component::Table::Cell object.

    my $item = Games::Sudoku::Component::Table::Item->new(
      row     => $cell->row,
      col     => $cell->col,
      allowed => [ $cell->allowed ],
    );
    ...
  }

  # Also, $table->cell(row, col) returns a ::Cell object.

  $table->cell(5,5)->value(3);

=head1 DESCRIPTION

This module is for a cell of a puzzle board (table). There are several
methods here, but some of them are mainly used internally. What you'll
actually use are: value, allowed, is_locked, and maybe, row and col.

=head1 METHODS

=head2 new (I<hash> or I<hashref>)

Creates an object. Below options are mandatory:

=over 4

=item row (I<integer>)

=item col (I<integer>)

Row/column id of the cell, respectively.

=item permission (or C<perm>, for short)

L<Games::Sudoku::Component::Table::Permission> object.

=back

See also the base class L<Games::Sudoku::Component::Base>.
Actually size related options are required, too.

=head2 row

=head2 col

Returns a row/column id of the cell respectively, just for convenience.

=head2 value (I<integer>)

As a getter, this returns a surface value of the cell, that is, 
if the cell has a temporary (denied) value, returns it; otherwise, 
returns a real (allowed) value.

As a setter, you can set (or reset) a value of the cell, regardless 
of its permission. If the value is not allowed, the value is held 
as a temporary one. However, it is totally ignored if the cell is 
locked.

=head2 realvalue

Returns a real value of the cell. If the cell has a temporary value, 
returns 0.

=head2 tmpvalue

Returns a temporary value of the cell. If the cell has a real value, 
returns 0.

=head2 allowed

Returns an array of allowed values for the cell.

=head2 is_allowed (I<integer>)

Returns true if the argument value is allowed for the cell.

=head2 lock

Locks the cell to keep the original puzzle untainted. The locked cell 
will ignore any new values until it is unlocked.

=head2 unlock

Unlocks the cell to make it accept new values.

=head2 is_locked

Returns true if the cell is locked.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>,

=item L<Games::Sudoku::Component::Base>,

=item L<Games::Sudoku::Component::Table>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
