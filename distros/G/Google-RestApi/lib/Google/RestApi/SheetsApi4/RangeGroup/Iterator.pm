package Google::RestApi::SheetsApi4::RangeGroup::Iterator;

our $VERSION = '1.0.0';

use Google::RestApi::Setup;

use aliased 'Google::RestApi::SheetsApi4::RangeGroup';

sub new {
  my $class = shift;
  state $check = compile_named(
    range_group => HasMethods[qw(ranges)],
    dim         => StrMatch[qr/^(col|row)$/], { default => 'row' },
    by          => PositiveInt, { default => 1 },
    from        => PositiveOrZeroInt, { optional => 1 },
    to          => PositiveOrZeroInt, { optional => 1 },
  );
  my $self = $check->(@_);
  $self->{current} = delete $self->{from} || 0;
  return bless $self, $class;
}

sub iterate {
  my $self = shift;

  return if defined $self->{to} && $self->{current} + 1 > $self->{to};

  my @ranges = map {
    $_->cell_at_offset($self->{current}, $self->{dim});
  } $self->range_group()->ranges();
  return if grep { undef; } @ranges;

  $self->{current} += $self->{by};

  return $self->spreadsheet()->range_group(@ranges);
}
sub next { iterate(@_); }

sub range_group { shift->{range_group}; }
sub spreadsheet { shift->range_group()->spreadsheet(); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::RangeGroup::Iterator - An iterator for a group of Ranges.

=head1 DESCRIPTION

A RangeGroup::Iterator is used to iterate through a range group, returning
a range group of cells, one group at a time.

Iterating over a range group assumes the range group is made up of
a series of ranges that implement a 'cell_at_offset' subroutine. This
routine is called on each iteration to return a Cell object that
represents that iteration at a particular offset. The offset increases
for each iteration.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item new(range => <Range>, dim => <dimension>, by => <int>);

Creates a new Iterator object for the given range group.

 range_group: The parent range group for this iterator.
 by: The number of cells to skip between each iteration. Defaults to 1.
 from: The offset from which to start the iteration. Defaults to 0.
 to: The offset to stop the iteration. No default.

'by' is used to allow you to only return, say, every second cell in the
iteration ('by' = '2').

If you don't specify a 'to' then you will need to have a method to
end the iteration yourself (e.g. 'last if cell value eq ""') or you
will iterate off the end of the sheet and get a 403 back.

You would not normally call this directly, you'd use the RangeGroup::iterator
method to create the iterator object for you.

=item iterate();

Return the next group of cells in the iteration sequence.

=item next();

An alias for iterate().

=item range_group();

Returns the RangeGroup object for this iterator.

=item spreadsheet();

Returns the Spreadsheet object for this iterator.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
