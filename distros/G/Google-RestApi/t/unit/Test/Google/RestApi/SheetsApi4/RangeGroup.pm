package Test::Google::RestApi::SheetsApi4::RangeGroup;

use YAML::Any qw(Dump);
use Test::Most;

use aliased 'Google::RestApi::SheetsApi4::RangeGroup';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Base);

sub class { 'Google::RestApi::SheetsApi4::RangeGroup' }

sub constructor : Tests(4) {
  my $self = shift;
  my @ranges = $self->new_ranges("A1", "B2");
  $self->SUPER::constructor(
    spreadsheet => $self->spreadsheet(),
    ranges      => \@ranges,
  );
  can_ok $self, 'ranges';
  return;
}

sub spreadsheet { shift->worksheet()->spreadsheet(); }

sub new_ranges {
  my $self = shift;
  my @ranges = map { $self->worksheet()->range($_); } @_;
  return @ranges;
}

sub new_range_group {
  my $self = shift;
  my @ranges = $self->new_ranges(@_);
  return $self->class()->new(spreadsheet => $self->spreadsheet(), ranges => \@ranges);
}

sub ranges : Tests(1) {
  my $self = shift;

  my $range_group = $self->new_range_group("A1", "B2");
  isa_ok $range_group->bold()->red(0.1), RangeGroup, "Setting bold and red";

  return;
}

1;
