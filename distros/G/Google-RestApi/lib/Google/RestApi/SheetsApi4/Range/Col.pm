package Google::RestApi::SheetsApi4::Range::Col;

our $VERSION = '1.0.4';

use Google::RestApi::Setup;

use Try::Tiny qw( try catch );

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent Range;

sub new {
  my $class = shift;
  my %self = @_;

  $self{dim} = 'col';
  $self{range} = _col_i2a($self{range});

  # this is fucked up, but want to support creating this object directly and also
  # via the range::factory method, so have to handle both cases here. try to create
  # the col directly first (which could also come via the factory method, which will
  # have already translated the address into a col), and failing that, see if the
  # range factory can create a col (which will resolve any named or header references).
  # this has the potential of looping between this and factory method.

  # if factory has already been used, then this should resolve here.
  my $err;
  try {
    state $check = compile(RangeCol);
    ($self{range}) = $check->($self{range});
  } catch {
    $err = $_;
  };
  return $class->SUPER::new(%self) if !$err;

  # see if the range passed can be translated to what we want via the factory.
  my $factory_range;
  try {
    $factory_range = Google::RestApi::SheetsApi4::Range::factory(%self);
  } catch {};
  return $factory_range if $factory_range && $factory_range->isa(__PACKAGE__);

  LOGDIE sprintf("Unable to translate '%s' into a worksheet column: $err", flatten_range($self{range}));
}

sub _col_i2a {
  my $col = shift;
  return $col if $col =~ qr/\D/;  # if any non-digits found, we're good.
  my $l = int($col / 27);
  my $r = $col - $l * 26;
  return $l > 0 ? (pack 'CC', $l+64, $r+64) : (pack 'C', $r+64);
}

sub values {
  my $self = shift;
  state $check = compile_named(
    values => ArrayRef[Str], { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [ $p->{values} ] if defined $p->{values};
  my $values = $self->SUPER::values(%$p);
  return defined $values ? $values->[0] : undef;
}

sub batch_values {
  my $self = shift;
  state $check = compile_named(
    values => ArrayRef[Str], { optional => 1 },
  );
  my $p = $check->(@_);
  $p->{values} = [ $p->{values} ] if $p->{values};
  return $self->SUPER::batch_values(%$p);
}

sub cell_at_offset {
  my $self = shift;

  state $check = compile(Int, DimColRow, { optional => 1 });
  my ($offset) = $check->(@_);   # we're a column, no dim required.

  my $col_range = $self->range_to_array($Google::RestApi::SheetsApi4::Range::RANGE_EXPANDED);  # can't use aliased.
  my $cell_range = $col_range->[0];
  $cell_range->[1] = ($cell_range->[1] || 1) + $offset;
  return if $col_range->[1]->[1] && $cell_range->[1] > $col_range->[1]->[1];

  my $cell = Cell->new(worksheet => $self->worksheet(), range => $cell_range);
  $cell->share_values($self);
  return $cell;
}

sub is_other_inside {
  my $self = shift;

  state $check = compile(HasRange);
  my ($inside_range) = $check->(@_);

  my $range = $self->range_to_hash($Google::RestApi::SheetsApi4::Range::RANGE_EXPANDED);
  $inside_range = $inside_range->range_to_hash($Google::RestApi::SheetsApi4::Range::RANGE_EXPANDED);  # can't use aliased.

  return if $range->[0]->{col} < $inside_range->[0]->{col};
  return if $range->[1]->{col} > $inside_range->[1]->{col};
  return if $range->[0]->{row} && $range->[0]->{row} > $inside_range->[0]->{row};
  return if $range->[1]->{row} && $range->[1]->{row} < $inside_range->[1]->{row};
  
  return 1;
}

sub freeze {
  my $self = shift;
  my $range = $self->range_to_dimension('col');
  return $self->freeze_cols($range->{endIndex});
}

sub thaw {
  my $self = shift;
  my $range = $self->range_to_dimension('col');
  return $self->freeze_cols($range->{startIndex});
}

sub heading { shift->SUPER::heading(@_)->right()->freeze(); }
sub insert_d { shift->insert_dimension(inherit => shift); }
sub insert_dimension { shift->SUPER::insert_dimension(dimension => 'col', @_); }
sub move_dimension { shift->SUPER::move_dimension(dimension => 'col', @_); }
sub delete_dimension { shift->SUPER::delete_dimension(dimension => 'col', @_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Col - Represents a column within a Worksheet.

=head1 DESCRIPTION

A Range::Col object modifies the behaviour of the parent Range object
to treat the values used within the range as a column in the spreadsheet,
in other words, a single flat array instead of arrays of arrays. This
object will encapsulate the passed flat array value into a [$value]
array of arrays when interacting with Google API.

It also adjusts calls defined in Request::Spreadsheet::Worksheet::Range
to reflect using a column instead of a general range.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
