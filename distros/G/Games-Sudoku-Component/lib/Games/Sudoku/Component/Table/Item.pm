package Games::Sudoku::Component::Table::Item;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.01';

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    croak "Row is undefined"     unless defined $options{row};
    croak "Col is undefined"     unless defined $options{col};
    croak "Allowed is undefined" unless defined $options{allowed};
    croak "Allowed should be array_ref"
      if ref $options{allowed} ne 'ARRAY';

    $this->{row}      = $options{row};
    $this->{col}      = $options{col};
    $this->{allowed}  = $options{allowed};
    $this->{value}    = $options{value};

    $this;
  }

  sub row      { $_[0]->{row} }
  sub col      { $_[0]->{col} }
  sub value    { $_[0]->{value} }
  sub allowed  { @{ $_[0]->{allowed} } }

  sub random_value {
    my $this = shift;

    my @allowed = @{ $this->{allowed} };
    my $value = splice(@allowed, int(rand(@allowed)), 1);

    $this->{allowed}  = \@allowed;
    $this->{value} = $value;

    $value;
  }

  sub as_string {
    my $this = shift;

    my $row     = $this->{row}   || 0;
    my $col     = $this->{col}   || 0;
    my $value   = $this->{value} || 0;
    my @allowed = @{ $this->{allowed} };

    sprintf('(%d, %d): %d (allowed: %s)',
      $row, $col, $value, join(', ', @allowed),
    );
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Table::Item

=head1 SYNOPSIS

  use Games::Sudoku::Component::Table::Item;

  my $item = Games::Sudoku::Component::Table::Item->new(
    row     => 2,
    col     => 3,
    allowed => [2, 3, 4],
  );

  my $next_candidate = $item->random_value;

=head1 DESCRIPTION

This module is mainly used to bridge between ::Controller::History
object and ::Table (and ::Table::Cell) object. Maybe you don't need
to touch this explicitly.

=head1 METHODS

=head2 new (I<hash> or I<hashref>)

Creates an object. Below options are mandatory:

=over 4

=item row (I<integer>)

=item col (I<integer>)

Row/column id of the item (cell), respectively.

=item allowed (I<arrayref>)

Arrayref of allowed values for the item (cell).

=back

Below is optional:

=over 4

=item value

Initial value.

=back

=head2 row

=head2 col

Returns a row/column id of the item (cell), respectively.

=head2 value

Returns a value of the item (cell).

=head2 allowed

Returns an array of allowed values of the item (cell).

=head2 random_value

Returns one of the allowed values of the item (cell).
The value is pulled out of the array of allowed values.

=head2 as_string

Returns a dump string of the item (cell), maybe just for debugging.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>,

=item L<Games::Sudoku::Component::Table>,

=item L<Games::Sudoku::Component::Table::Cell>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
