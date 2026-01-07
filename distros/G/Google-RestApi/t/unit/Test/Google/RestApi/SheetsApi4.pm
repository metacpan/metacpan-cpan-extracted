package Test::Google::RestApi::SheetsApi4;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

use parent 'Test::Unit::TestBase';

init_logger;

sub dont_create_mock_spreadsheets { 1; }

sub _constructor : Tests(2) {
  my $self = shift;
  ok my $spreadsheets = SheetsApi4->new(api => mock_rest_api()), 'Constructor should succeed';
  isa_ok $spreadsheets, SheetsApi4, 'Constructor returns';
  return;
}

sub api : Tests(1) {
  my $self = shift;
  my $sheets_api = mock_sheets_api();
  throws_ok sub { $sheets_api->api(uri => 'x') }, qr/NOT_FOUND/s, 'Get with invalid spreadsheet name should 404';
  return;
}

sub ordered_tests : Tests(16) {
  my $self = shift;
  $self->create_spreadsheet;
  $self->copy_spreadsheet;
  $self->spreadsheets;
  $self->delete_spreadsheet;
  $self->delete_all_spreadsheets_by_filters;
  return;
}

sub create_spreadsheet {
  my $self = shift;
  my $sheets_api = mock_sheets_api();

  throws_ok sub { $sheets_api->create_spreadsheet(eman => mock_spreadsheet_name()) }, qr/should be supplied/, "No name or title should fail";
  
  isa_ok my $ss0 = $sheets_api->create_spreadsheet(title => mock_spreadsheet_name()), Spreadsheet, "Create sheet by title";
  ok $ss0->spreadsheet_id, "Spreadhseet has an id";
  $self->{mock_spreadsheet_id} = $ss0->spreadsheet_id;

  isa_ok my $ss2 = $sheets_api->create_spreadsheet(name => mock_spreadsheet_name2()), Spreadsheet, "Create sheet by name";
  $self->{mock_spreadsheet_id2} = $ss0->spreadsheet_id;

  return;
}

sub copy_spreadsheet {
  my $self = shift;
  my $sheets_api = mock_sheets_api();

  isa_ok $sheets_api->copy_spreadsheet(spreadsheet_id => $self->{mock_spreadsheet_id}), Spreadsheet, "Copy sheet";

  isa_ok $sheets_api->copy_spreadsheet(
    spreadsheet_id => $self->{mock_spreadsheet_id},
    name           => mock_spreadsheet_name(),
  ), Spreadsheet, "Copy sheet with name";

  isa_ok $sheets_api->copy_spreadsheet(
    spreadsheet_id => $self->{mock_spreadsheet_id2},
    title          => mock_spreadsheet_name2(),
  ), Spreadsheet, "Copy sheet with title";

  return;
}

sub spreadsheets {
  my $self = shift;
  my $sheets_api = mock_sheets_api();

  my @spreadsheets = $sheets_api->spreadsheets(mock_spreadsheet_name());
  ok scalar @spreadsheets >= 2, "There are two (or more) spreadsheets named " . mock_spreadsheet_name();
  my $qr_id = $Google::RestApi::SheetsApi4::Spreadsheet_Id;
  is_valid \@spreadsheets, ArrayRef[Dict[id => StrMatch[qr/$qr_id/], name => Str]], "Spreadsheets return";

  @spreadsheets = $sheets_api->spreadsheets_by_filter("name contains 'mock_spreadsheet'");
  ok scalar @spreadsheets >= 4, "There are four (or more) spreadsheet names containing 'mock_spreadsheet'";

  return;
}

sub delete_spreadsheet {
  my $self = shift;
  my $sheets_api = mock_sheets_api();

  throws_ok(sub { $sheets_api->delete_spreadsheet('x') }, qr/File not found/s, 'Delete non-existent by id should die');
  is_deeply $sheets_api->delete_spreadsheet($self->{mock_spreadsheet_id2}), 1, 'Delete by id should return 1';

  return;
}

sub delete_all_spreadsheets_by_filters {
  my $self = shift;
  my $sheets_api = mock_sheets_api();

  is $sheets_api->delete_all_spreadsheets_by_filters("name = 'no_such_spreadsheet'"), 0, 'Delete non-existant should return 0';
  ok $sheets_api->delete_all_spreadsheets_by_filters("name contains 'mock_spreadsheet1'") >= 2, 'Delete existing should return at least 2';
  ok $sheets_api->delete_all_spreadsheets_by_filters("name contains 'mock_spreadsheet2'") >= 1, 'Delete existing should return at least 1 (other deleted by delete_spreadsheet)';
  is $sheets_api->delete_all_spreadsheets_by_filters("name contains 'mock_spreadsheet'"), 0, 'Delete prefix should return 0';

  return;
}

1;
