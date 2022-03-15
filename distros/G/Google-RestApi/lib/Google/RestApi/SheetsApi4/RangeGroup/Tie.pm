package Google::RestApi::SheetsApi4::RangeGroup::Tie;

our $VERSION = '1.0.2';

use Google::RestApi::Setup;

use Tie::Hash ();
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator';
use parent -norequire, 'Tie::StdHash';

sub iterator {
  my $self = shift;

  my $tied = $self->spreadsheet()->tie(%{ $self->ranges() });
  tied(%$tied)->default_worksheet($self->worksheet())
    if $self->worksheet();

  return Iterator->new(@_, tied => $tied);
}

sub values {
  my $self = shift;
  my $range_group = $self->range_group();
  return $range_group->values(@_);
}

sub batch_values {
  my $self = shift;
  my $range_group = $self->range_group();
  return $range_group->batch_values(@_);
}

sub add_ranges {
  my $self = shift;
  my %ranges = @_;
  state $check = compile(slurpy ArrayRef[HasRange]);
  $check->(CORE::values %ranges);
  @{ $self->{ranges} }{ keys %ranges } = CORE::values %ranges;
  return \%ranges;
}

sub add_tied {
  my $self = shift;
  state $check = compile(HashRef);
  my ($tied) = $check->(@_);

  my $fetch_range = tied(%$tied)->fetch_range();
  tied(%$tied)->fetch_range(1);
  $self->add_ranges(%$tied);
  tied(%$tied)->fetch_range($fetch_range);

  return $tied;
}

# fetch_range(1) turns it on, fetch_range(0) turns it off.
# fetch_range() returns current setting. return $self so it can be
# chained with requests.
sub fetch_range {
  my $self = shift;
  my $fetch_range = shift;
  return $self->{fetch_range} if !defined $fetch_range;

  if ($fetch_range) {
    $self->{fetch_range} = 1;
  } else {
    delete $self->{fetch_range};
  }

  return $self;
}

sub range_group {
  my $self = shift;
  return $self->spreadsheet()->range_group(CORE::values %{ $self->ranges() });
}

sub default_worksheet {
  my $self = shift;
  state $check = compile(
    HasMethods[qw(tie_ranges tie_cells)], { optional => 1 },
  );
  my ($worksheet) = $check->(@_);
  $self->{worksheet} = $worksheet if $worksheet;
  return $self->{worksheet};
}

sub TIEHASH  {
  my $class = shift;
  state $check = compile(
    HasMethods[qw(range_group)],
  );
  my ($spreadsheet) = $check->(@_);
  my $self = bless {}, $class;
  $self->{spreadsheet} = $spreadsheet;
  return $self;
}

sub FIRSTKEY {
  my $self = shift;
  my $a = keys %{ $self->ranges() };  # reset each() iterator
  return each %{ $self->ranges() };
}

sub NEXTKEY {
  return each %{ shift->ranges() };
}

sub FETCH {
  my $self = shift;
  my $key = shift;
  my $range = $self->ranges()->{$key}
    or LOGDIE "No range found for key '$key'";
  return $self->{fetch_range} ? $range : $range->values();
}

sub STORE {
  my $self = shift;

  my ($key, $value) = @_;
  if (!$self->ranges()->{$key}) {
    my $worksheet = $self->worksheet()
      or LOGDIE "No default worksheet provided for new range '$key'. Call default_worksheet() first.";    
    my $tied = $worksheet->tie_ranges({ $key => $key });
    $self->add_tied($tied);
  }

  if (ref($value) eq "HASH") {
    $self->ranges()->{$key}->batch_requests($value);
  } else {
    $self->ranges()->{$key}->batch_values(values => $value);
  }

  return;
}

sub clear_cached_values { shift->range_group()->clear_cached_values(@_); }
sub refresh_values { shift->range_group()->refresh_values(@_); }
sub submit_values { shift->range_group()->submit_values(@_); }
sub submit_requests { shift->range_group()->submit_requests(@_); }
sub transaction { shift->range_group()->transaction(); }
sub ranges { shift->{ranges}; }
sub worksheet { shift->{worksheet}; }
sub spreadsheet { shift->{spreadsheet}; }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::RangeGroup::Tie - Makes Ranges addressible via a hash key.

=head1 DESCRIPTION

A RangeGroup::Tie is a 

See the description and synopsis at Google::RestApi::SheetsApi4.

=head1 SUBROUTINES

=over

=item iterator(%args);

Returns an iterator for this tied range group. Each call to 'iterate'
(or 'next') will return a tied range group of individual cells
representing the iteration at that point.

Any 'args' are passed through to RangeGroup::Iterator::new.

=item values(%args);

Gets the values for the underlying range group.

Any 'args' are passed through to RangeGroup::Iterator::values.

=item batch_values {

Gets or sets the queued batch values for the underlying range group.

Any 'args' are passed through to RangeGroup::Iterator::batch_values.

=item add_ranges(<hash<Range>>);

Adds the passed 'index => Range' pairs to this tied range group.

=item add_tied(<hashref<Range>>);

Adds the passed tied range group to this tied range group.

=item fetch_range(<bool>);

Sets the option to return the underlying ranges when fetching the
value. This allows you to set things like formatting on the underlying
ranges when fetching by index.

=item range_group();

Returns the parent RangeGroup object.

=item default_worksheet();

Sets the default worksheet to be used when auto-creating a new
index. Each index points to a range, and each range must have
a worksheet with which it is associated. So if a new index is
created, we need to know to which worksheet that index needs
to point.

=item refresh_values();

Calls the parent RangeGroup's refresh_values routine.

=item submit_values();

Calls the parent RangeGroup's submit_values routine.

=item submit_requests();

Calls the parent RangeGroup's submit_requests routine.

=item ranges();

Calls the parent RangeGroup's ranges routine.

=item worksheet();

Returns the parent default Worksheet object.

=item spreadsheet();

Returns the parent Spreadsheet object.

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
