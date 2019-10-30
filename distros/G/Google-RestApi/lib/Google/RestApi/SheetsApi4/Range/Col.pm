package Google::RestApi::SheetsApi4::Range::Col;

use strict;
use warnings;

our $VERSION = '0.2';

use 5.010_000;

use autodie;
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str Int ArrayRef Any slurpy);
use YAML::Any qw(Dump);
use Google::RestApi::Utils qw(named_extra);

no autovivification;

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent 'Google::RestApi::SheetsApi4::Range';

do 'Google/RestApi/logger_init.pl';

sub new { shift->SUPER::new(@_, dim => 'col'); }

sub range {
  my $self = shift;
  return $self->{normalized_range} if $self->{normalized_range};
  $self->{range} = { col => $self->{range} } if !ref($self->{range});
  my $range = $self->SUPER::range(@_);
  my $colA1 = Range->ColA1;
  die "Unable to translate '$range' into a worksheet column"
    if !$self->is_named() && $range !~ qr/$colA1/;
  return $range;
}

sub values {
  my $self = shift;
  my $p = _update_values(@_);
  my $values = $self->SUPER::values(%$p);
  return $values->[0];
}

sub batch_values {
  my $self = shift;
  my $p = _update_values(@_);
  return $self->SUPER::batch_values(%$p);
}

sub _update_values {
  state $check = compile_named(
    values  => ArrayRef[Str], { optional => 1 },
    _extra_ => slurpy Any,
  );
  my $p = named_extra($check->(@_));
  $p->{values} = [$p->{values}] if defined $p->{values};
  return $p;
}

sub cell {
  my $self = shift;
  state $check = compile(Int, { default => 0 });
  my ($offset) = $check->(@_);
  my $range = $self->range_to_array();
  $range->[1] = ($range->[1] || 1) + $offset;
  return Cell->new(worksheet => $self->worksheet(), range => $range);
}

sub range_to_index {
  my $self = shift;
  my $range = $self->SUPER::range_to_index(@_);
  delete @$range{qw(startRowIndex endRowIndex)};
  return $range;
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

Copyright (c) 2019, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
