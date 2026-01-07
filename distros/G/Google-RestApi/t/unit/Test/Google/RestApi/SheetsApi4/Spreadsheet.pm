package Test::Google::RestApi::SheetsApi4::Spreadsheet;

use Test::Unit::Setup;

use Time::HiRes qw(sleep);

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

use parent 'Test::Unit::TestBase';

init_logger;

sub _constructor : Tests(7) {
  my $self = shift;

  throws_ok sub { Spreadsheet->new(sheets_api => mock_sheets_api()) },
    qr/At least one of/i,
    'Constructor with missing params should throw';

  my $ms = $self->mock_spreadsheet();
  my $ms_id = $ms->spreadsheet_id;

  ok my $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), id => $ms_id), 'Constructor should have succeeded';
  isa_ok $ss, Spreadsheet, 'Constructor with "id" returns';

  ok $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), name => mock_spreadsheet_name()),
    'Constructor with "name" should succeed';
  isa_ok $ss, Spreadsheet, 'Constructor with "name" returns';

  ok $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), uri => $self->mock_spreadsheet_uri()),
    'Constructor with "uri`" should succeed';
  isa_ok $ss, Spreadsheet, 'Constructor with "uri" returns';

  return;
}

sub api : Tests(2) {
  my $self = shift;

  my $ss = $self->mock_spreadsheet();
  is_valid $ss->api(), HashRef, 'Get returns hashref';
  my $transaction = $ss->rest_api()->transaction();
  is $transaction->{request}->{uri}, sheets_endpoint() . "/" . $self->mock_spreadsheet_id(),
    'Request base spreadsheet uri string is valid';

  return;
}

sub spreadsheet_id : Tests(4) {
  my $self = shift;

  my $ms = $self->mock_spreadsheet();
  my $ms_id = $ms->spreadsheet_id;

#  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), name => mock_spreadsheet_name2());
#  throws_ok sub { $ss->spreadsheet_id(); }, qr/More than one/i, 'Spreadsheet with more than one name should throw';

  my $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), name => 'no_such_spreadsheet');
  throws_ok sub { $ss->spreadsheet_id(); }, qr/not found/i, 'Spreadsheet with no such name should throw';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), id => $ms_id);
  is $ss->spreadsheet_id(), $ms_id, 'Spreadsheet with "id" returns "id"';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), name => mock_spreadsheet_name());
  is $ss->spreadsheet_id(), $ms_id, 'Spreadsheet with "name" returns "id"';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), uri => $self->mock_spreadsheet_uri());
  is $ss->spreadsheet_id(), $ms_id, 'Spreadsheet with "uri" returns "id"';

  return;
}

sub spreadsheet_name : Tests(3) {
  my $self = shift;

  my $ms = $self->mock_spreadsheet();
  my $ms_id = $ms->spreadsheet_id;

  my $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), id => $ms_id);
  is $ss->spreadsheet_name(), mock_spreadsheet_name(), 'Spreadsheet with "id" returns "name"';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), name => mock_spreadsheet_name());
  is $ss->spreadsheet_name(), mock_spreadsheet_name(), 'Spreadsheet with "name" returns "name"';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), uri => $self->mock_spreadsheet_uri());
  is $ss->spreadsheet_name(), mock_spreadsheet_name(), 'Spreadsheet with "uri" returns "name"';

  return;
}

sub spreadsheet_uri : Tests(3) {
  my $self = shift;

  my $ms = $self->mock_spreadsheet();
  my $ms_id = $ms->spreadsheet_id;

  my $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), id => $ms_id);
  is $ss->spreadsheet_uri(), $self->mock_spreadsheet_uri(), 'Spreadsheet with "id" returns "uri"';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), name => mock_spreadsheet_name());
  is $ss->spreadsheet_uri(), $self->mock_spreadsheet_uri(), 'Spreadsheet with "name" returns "uri"';

  $ss = Spreadsheet->new(sheets_api => mock_sheets_api(), uri => $self->mock_spreadsheet_uri());
  is $ss->spreadsheet_uri(), $self->mock_spreadsheet_uri(), 'Spreadsheet with "uri" returns "uri"';

  return;
}

sub spreadsheet_title : Tests(1) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();
  is $ss->spreadsheet_title(), $ss->spreadsheet_name(), 'Spreadsheet title is the same as name';
  return;
}

sub attrs : Tests(2) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();
  my $uri = $self->mock_spreadsheet_uri();
  like $ss->attrs('spreadsheetUrl')->{spreadsheetUrl}, qr|\Q$uri\E|, 'Attrs retrieves spreadsheet uri';
  throws_ok sub { $ss->attrs('joe') }, qr|INVALID_ARGUMENT|, 'Bad attrs should throw';
  return;
}

sub properties : Tests(3) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();
  $ss->cache_seconds(0);
  is $ss->properties('locale')->{'locale'}, 'en_GB', 'Locale is en_GB';
  ok $ss->properties('defaultFormat.backgroundColor')->{defaultFormat}->{backgroundColor},
    "Background color property fetch is successful";
  is $ss->properties('defaultFormat.backgroundColor')->{defaultFormat}->{backgroundColor}->{green},
    1, 'Background has green';
  return;
}

sub worksheet_properties : Tests(5) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();

  is $ss->worksheet_properties('index')->[0]->{'index'}, 0, 'Worksheet index is 0';
  is $ss->worksheet_properties('gridProperties.rowCount')->[0]->{gridProperties}->{rowCount},
    1000, 'Row count is 1000';
  
  my $properties;
  lives_ok sub { $properties = $ss->worksheet_properties('(index,gridProperties.rowCount)') },
    'Geting multiple worksheet properties lives'; 
  is $properties->[0]->{'index'}, 0, 'Multiple properties worksheet index is 0';
  is $properties->[0]->{gridProperties}->{rowCount}, 1000, 'Muiltiple properties row count is 1000';
  return;
}

sub cache : Tests(8) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();

  $ss->reset_stats;
  $ss->cache_seconds(1);
  $ss->properties('locale');
  is $ss->stats()->{get}, 1, 'First call to cache, number of gets is 1';
  $ss->properties('locale');
  is $ss->stats()->{get}, 1, 'Second call to cache, number of gets is still 1';

  lives_ok sub { $ss->cache_seconds(0) }, 'Turning off cache lives';
  $ss->properties('locale');
  is $ss->stats()->{get}, 2, 'Third call to cache, number of gets is 2';

  lives_ok sub { $ss->cache_seconds(1.25) }, 'Setting cache to 1.25 lives';
  $ss->properties('locale');
  is $ss->stats()->{get}, 3, 'Forth call to cache, number of gets is 3';
  $ss->properties('locale');
  is $ss->stats()->{get}, 3, 'Fifth call to cache, number of gets is still 3';
  sleep(1.5);
  $ss->properties('locale');
  is $ss->stats()->{get}, 4, 'Sixth call to cache after sleep, number of gets is 4';
  
  return;
}

sub copy_spreadsheet : Tests(6) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();
  
  isa_ok my $copy = $ss->copy_spreadsheet(), Spreadsheet, 'Copy sheet';
  is $copy->delete_spreadsheet(), 1, 'Delete should return 1';

  isa_ok $copy = $ss->copy_spreadsheet(
    name => mock_spreadsheet_name()
  ), Spreadsheet, 'Copy sheet with name';
  is $copy->delete_spreadsheet(), 1, 'Delete should return 1';

  isa_ok $copy = $ss->copy_spreadsheet(
    title => mock_spreadsheet_name()
  ), Spreadsheet, 'Copy sheet with title';
  is $copy->delete_spreadsheet(), 1, 'Delete should return 1';

  return;
}

sub delete_spreadsheet : Tests(2) {
  my $self = shift;
  my $ss = $self->mock_spreadsheet();

  isa_ok my $copy = $ss->copy_spreadsheet(), Spreadsheet, 'Copy sheet';
  is $copy->delete_spreadsheet(), 1, 'Delete should return 1';

  return;
}

sub range_group : Tests() {
  my $self = shift;
}

sub tie : Tests() {
  my $self = shift;
}

sub submit_values : Tests() {
  my $self = shift;
}

sub submit_requests : Tests() {
  my $self = shift;
}

sub named_ranges : Tests() {
  my $self = shift;
}

sub protected_ranges : Tests() {
  my $self = shift;
}

sub delete_all_protected_ranges : Tests() {
  my $self = shift;
}

sub open_worksheet : Tests() {
  my $self = shift;
}

sub sheets_config : Tests() {
  my $self = shift;
}

sub config : Tests() {
  my $self = shift;
}

1;
