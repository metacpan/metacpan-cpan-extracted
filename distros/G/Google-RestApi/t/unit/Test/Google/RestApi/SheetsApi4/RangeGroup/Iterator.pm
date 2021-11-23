package Test::Google::RestApi::SheetsApi4::RangeGroup::Iterator;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::RangeGroup';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Iterator';

use parent qw(Test::Unit::TestBase);

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  $self->_uri_responses(qw(
    get_spreadsheet_named_ranges
    get_worksheet_properties_title_sheetid
    get_worksheet_values_cell
    get_worksheet_values_row
    get_worksheet_values_a1_c3
    post_worksheet_values_x_y_z
    put_worksheet_values_a1_c3
  ));

  return;
}

sub iterate : Test(9) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $ws0 = fake_worksheet();
  $ws0->enable_header_row();

  my @values = (
    [ 1, 2, 3],
    [ 4, 5, 6],
    [ 7, 8, 9],
  );
  $ws0->range("A1:C3")->values(values => \@values);

  my $col = $ws0->range_col(1);
  my $row = $ws0->range_row(1);
  my $range_group = $ws0->spreadsheet()->range_group($col, $row);

  my ($i, $rg);

  isa_ok $i = $range_group->iterator(), Iterator, "Iterator creation";

  isa_ok $rg = $i->next(), RangeGroup, "First iteration";
  is_deeply $rg->values(), [1, 1], "First iteration should be [1, 1]";

  isa_ok $rg = $i->next(), RangeGroup, "Second iteration";
  is_deeply $rg->values(), [4, 2], "Second iteration should be [4, 2]";

  isa_ok $rg = $i->next(), RangeGroup, "Third iteration";
  is_deeply $rg->values(), [7, 3], "Third iteration should be [7, 3]";

  isa_ok $rg = $i->next(), RangeGroup, "Forth iteration";
  is_deeply $rg->values(), [undef, undef], "Forth iteration should be undef";

  return;
}

1;
