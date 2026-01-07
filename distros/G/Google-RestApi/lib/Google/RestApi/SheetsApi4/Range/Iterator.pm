package Google::RestApi::SheetsApi4::Range::Iterator;

our $VERSION = '1.1.0';

use Google::RestApi::Setup;

sub new {
  my $class = shift;
  state $check = compile_named(
    range => HasMethods[qw(range worksheet)],
    dim   => StrMatch[qr/^(col|row)$/], { default => 'row' },
    by    => PositiveInt, { default => 1 },
    from  => PositiveOrZeroInt, { optional => 1 },
    to    => PositiveOrZeroInt, { optional => 1 },
  );
  my $self = $check->(@_);
  $self->{current} = delete $self->{from} || 0;
  return bless $self, $class;
}

sub iterate {
  my $self = shift;
  return if defined $self->{to} && $self->{current} + 1 > $self->{to};
  my $cell = $self->range()->cell_at_offset($self->{current}, $self->{dim});
  $self->{current} += $self->{by} if $cell;
  return $cell;
}
sub next { iterate(@_); }

sub range { shift->{range}; }
sub worksheet { shift->range()->worksheet(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Iterator - An iterator for an arbitrary Range.

=head1 DESCRIPTION

A Range::Iterator is used to iterate through a range, returning each
cell, one at a time.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(range => <Range>, dim => <dimension>, by => <int>);

Creates a new Iterator object for the given range.

 range: The Range object for which we are iterating.
 dim: The direction of the iteration ('col' or 'row'). The default is 'row'.
 by: The number of cells to skip between each iteration.

'dim' is used to specify which major dimension is used for the iteration.
For a given range 'A1:B2', a 'dim' of 'col' will return A1, A2, B1, B2
for each successive iteration. For a 'dim' of 'row', it will return
A1, B1, A2, B2 for each successive iteration.

'by' is used to allow you to only return, say, every second cell in the
iteration ('by' = '2'). For a given range 'A1:B4' and a 'by' of '2',
it will return A1, A3, B1, B3 for each succesive iteration.

You would not normally call this directly, you'd use the Range::iterator
method to create the iterator object for you.

=item iterate();

Return the next cell in the iteration sequence.

=item next();

An alias for iterate().

=item range();

Returns the Range object for this iterator.

=item worksheet();

# Returns the Worksheet object for this iterator.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
