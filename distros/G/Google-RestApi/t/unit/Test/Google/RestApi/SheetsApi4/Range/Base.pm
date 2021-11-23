package Test::Google::RestApi::SheetsApi4::Range::Base;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Worksheet';

use parent 'Test::Unit::TestBase';

use Scalar::Util qw(looks_like_number);

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->{err} = qr/Unable to translate/;

  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  $self->_uri_responses(qw(
    get_spreadsheet_named_range_george
    get_worksheet_properties_title_sheetid
    get_worksheet_values_col
    get_worksheet_values_row
    get_worksheet_values_cell
  ));

  return;
}

sub _to_str {
  my $self = shift;
  my $x = shift;
  return 'undef' if !defined $x;
  return $x if looks_like_number($x);
  return "'$x'";
}

1;
