package Google::RestApi::SheetsApi4::Range::Cell;

our $VERSION = '0.9';

use Google::RestApi::Setup;

use Try::Tiny qw( try catch );

use aliased 'Google::RestApi::SheetsApi4::Range';

use parent Range;

# make sure the translated range refers to a single cell (no ':').
sub new {
  my $class = shift;
  my %self = @_;

  # this is fucked up, but want to support creating this object directly and also
  # via the range::factory method, so have to handle both cases here. try to create
  # the cell directly first (which could also come via the factory method, which will
  # have already translated the address into a cell), and failing that, see if the
  # range factory can create a cell (which will resolve any named or header references).
  # this has the potential of looping between this and factory method.

  # if factory has already been used, then this should resolve here.
  my $err;
  try {
    state $check = compile(RangeCell);
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

  LOGDIE sprintf("Unable to translate '%s' into a worksheet cell: $err", flatten_range($self{range}));
}

sub values {
  my $self = shift;
  state $check = compile_named(
    values => Str, { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [[ $p->{values} ]] if defined $p->{values};
  my $values = $self->SUPER::values(%$p);
  return defined $values ? $values->[0]->[0] : undef;
}

sub batch_values {
  my $self = shift;

  state $check = compile_named(
    values => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  $p->{values} = [[ $p->{values} ]] if $p->{values};
  return $self->SUPER::batch_values(%$p);
}

# is this 0 or infinity? return self if offset is 0, undef otherwise.
sub cell_at_offset {
  my $self = shift;
  state $check = compile(Int, DimColRow, { optional => 1 });
  my ($offset) = $check->(@_);   # we're a cell, no dim required.
  return $self if !$offset;
  return;
}

sub is_other_inside {
  my $self = shift;
  state $check = compile(HasRange);
  my ($inside_range) = $check->(@_);
  return $self->range() eq $inside_range->range();
}

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Range::Cell - Represents a cell within a Worksheet.

=head1 DESCRIPTION

A Range::Cell object modifies the behaviour of the parent Range object
to treat the values used within the range as a plain string instead of
arrays of arrays. This object will encapsulate the passed string value
into a [[$value]] array of arrays when interacting with Goolge API.

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
