package Google::RestApi::SheetsApi4::Range::Iterator;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Type::Params qw(compile_named);
use Types::Standard qw(StrMatch Int HasMethods);
use YAML::Any qw(Dump);

no autovivification;

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;
  state $check = compile_named(
    range  => HasMethods[qw(range worksheet)],
    dim    => StrMatch[qr/^(col|row)$/], { default => 'row' },
    by     => Int->where('$_ > 0'), { default => 1 },
  );
  my $self = $check->(@_);
  $self->{cell} = $self->{range}->range_to_hash();
  $self->{cell} = $self->{cell}->[0] if ref($self->{cell}) eq 'ARRAY';
  $self->{first} = 1;
  return bless $self, $class;
}

sub iterate {
  my $self = shift;

  my $cell = $self->{cell};
  my $range = $self->range()->range_to_hash();
  $range = [$range, $range] if !ref($range->[0]);  # is just a cell.

  my $dim = $self->{dim};
  my $other_dim = $dim eq 'col' ? 'row' : 'col';
  my $new_dim = $cell->{$dim} + $self->{by};
  if ($new_dim > $range->[1]->{$dim}) {
    $cell->{$dim} = $range->[0]->{$dim};
    $cell->{$other_dim}++ unless $self->{first};
    return if $cell->{$other_dim} > $range->[1]->{$other_dim};
  } else {
    $cell->{$dim} = $new_dim unless $self->{first};
  }

  delete $self->{first};
  my $new_cell = $self->worksheet()->range_cell($cell);
  $new_cell->share_values($self->range());

  return $new_cell;
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

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
