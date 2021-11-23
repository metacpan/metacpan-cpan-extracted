package Test::Google::RestApi::SheetsApi4::RangeGroup;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::RangeGroup';

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
  ));

  return;
}

sub _constructor : Tests(2) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my @ranges = _new_ranges("A1", "B2");
  my $range_group = RangeGroup->new(
    spreadsheet => fake_spreadsheet(),
    ranges      => \@ranges,
  );
  isa_ok $range_group, RangeGroup, 'Constructor returns';
  can_ok $range_group, 'ranges';

  return;
}

sub _new_ranges {
  my @ranges = map { fake_worksheet()->range($_); } @_;
  return @ranges;
}

sub _new_range_group {
  my @ranges = _new_ranges(@_);
  return RangeGroup->new(spreadsheet => fake_spreadsheet(), ranges => \@ranges);
}

sub ranges : Tests(1) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $range_group = _new_range_group("A1", "B2");
  isa_ok $range_group->bold()->red(0.1), RangeGroup, "Setting bold and red";

  return;
}

1;
