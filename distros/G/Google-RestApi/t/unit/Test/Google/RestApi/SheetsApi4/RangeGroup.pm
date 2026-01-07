package Test::Google::RestApi::SheetsApi4::RangeGroup;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::RangeGroup';

init_logger;

sub _constructor : Tests(2) {
  my $self = shift;

  my @ranges = $self->_new_ranges("A1", "B2");
  my $range_group = RangeGroup->new(
    spreadsheet => $self->mock_spreadsheet(),
    ranges      => \@ranges,
  );
  isa_ok $range_group, RangeGroup, 'Constructor returns';
  can_ok $range_group, 'ranges';

  return;
}

sub ranges : Tests(1) {
  my $self = shift;
  my $range_group = $self->_new_range_group("A1", "B2");
  isa_ok $range_group->bold()->red(0.1), RangeGroup, "Setting bold and red";
  return;
}

sub _new_range_group {
  my $self = shift;
  my @ranges = $self->_new_ranges(@_);
  return RangeGroup->new(spreadsheet => $self->mock_spreadsheet(), ranges => \@ranges);
}

sub _new_ranges {
  my $self = shift;
  map { $self->mock_worksheet()->range($_); } @_;
}

1;
