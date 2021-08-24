package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator;

use Test::Unit::Setup;

use parent qw(Test::Unit::TestBase);

use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator';

sub class { Iterator; }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
    get_worksheet_values_cell
    get_worksheet_values_row
    post_worksheet_values_x_y_z
  ));

  return;
}

sub tie_range : Tests(14) {
  my $self = shift;

  $self->_fake_http_response_by_uri();

  my $ws0 = fake_config_worksheet();
  my $cols = $ws0->tie_cols();

  isa_ok my $iterator = tied(%$cols)->iterator(from => 1), Iterator, "Tie iterator creation";

  is $ws0->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $ws0->cell("C2"), undef, "Cell 'C2' is 'undef'";
  is $ws0->cell("D2"), undef, "Cell 'D2' is 'undef'";

  is_hash my $row = $iterator->iterate(), "First tied iteration";

  $row->{id} = 1000;
  $row->{name} = "Joe Blogs";
  $row->{address} = "123 Some Street";
  is_array tied(%$row)->submit_values(), "Updating a row";

  is $ws0->cell("B2"), 1000, "Cell 'B2' is '1000'";
  is $ws0->cell("C2"), "Joe Blogs", "Cell 'C2' is 'Joe Blogs'";
  is $ws0->cell("D2"), "123 Some Street", "Cell 'D2' is '123 Some Street'";

  is_hash $row = $iterator->iterate(), "Second tied iteration";
  $row->{id} = 1001;
  $row->{name} = "Freddie Mercury";
  $row->{address} = "321 Some Other Street";
  is_array tied(%$row)->submit_values(), "Updating a row";

  is $ws0->cell("B3"), 1001, "Cell 'B3' is '1001'";
  is $ws0->cell("C3"), "Freddie Mercury", "Cell 'C3' is 'Freddie Mercury'";
  is $ws0->cell("D3"), "321 Some Other Street", "Cell 'D3' is '321 Some Other Street'";

  return;
}

1;
