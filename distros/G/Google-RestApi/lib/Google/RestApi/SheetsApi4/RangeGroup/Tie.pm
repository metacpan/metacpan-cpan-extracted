package Google::RestApi::SheetsApi4::RangeGroup::Tie;

use strict;
use warnings;

our $VERSION = '0.4';

use 5.010_000;

use autodie;
use Tie::Hash;
use Type::Params qw(compile compile_named);
use Types::Standard qw(Int StrMatch ArrayRef HashRef HasMethods Any slurpy);
use YAML::Any qw(Dump);

use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator';

use parent -norequire, 'Tie::StdHash';

no autovivification;

do 'Google/RestApi/logger_init.pl';

sub iterator {
  my $self = shift;

  my %ranges = map {
    my $range = $self->ranges()->{$_};
    $range->can('cell') ? ($_ => $range) : ();
  } keys %{ $self->ranges() };
  my $tied = $self->spreadsheet()->tie(%ranges);

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
  state $check = compile(slurpy ArrayRef[HasMethods[qw(range)]]);
  $check->(CORE::values %ranges);
  @{ $self->{ranges} }{ keys %ranges } = CORE::values %ranges;
  return;
}

sub add_tied {
  my $self = shift;
  state $check = compile(HashRef);
  my ($tied) = $check->(@_);
  tied(%$tied)->fetch_range(1);
  return $self->add_ranges(%$tied);
}

sub fetch_range {
  my $self = shift;
  if (shift) {
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
    HasMethods[qw(tie_ranges tie_cells)],
  );
  my ($worksheet) = $check->(@_);
  $self->{worksheet} = $worksheet;
  return;
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
    or die "No range found for key '$key'";
  return $self->{fetch_range} ? $range : $range->values();
}

sub STORE {
  my $self = shift;

  my ($key, $value) = @_;
  if (!$self->ranges()->{$key}) {
    my $worksheet = $self->worksheet()
      or die "No default worksheet provided for new range '$key'. Call default_worksheet() first.";
    # have to make assumptions here. if there is a : somewhere in
    # the range, assume it's a range, else a cell. this may not
    # always do the right thing. in those cases, the initial tie
    # should specify the range you want instead of auto-creating
    # it here.
    my $tied = $key =~ /\:/
      ? $worksheet->tie_ranges($key)
      : $worksheet->tie_cells($key);
    $self->add_tied($tied);
  }

  if (ref($value) eq "HASH") {
    $self->ranges()->{$key}->batch_requests($value);
  } else {
    $self->ranges()->{$key}->batch_values(values => $value);
  }

  return;
}

sub refresh_values { shift->range_group()->refresh_values(@_); }
sub submit_values { shift->range_group()->submit_values(@_); }
sub submit_requests { shift->range_group()->submit_requests(@_); }
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

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
