package Test::Google::RestApi::SheetsApi4::Spreadsheet;

use Test::Unit::Setup;

use Time::HiRes qw(sleep);

use Google::RestApi::Types qw( :all );

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

use parent 'Test::Unit::TestBase';

# init_logger();

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_uri_responses(qw(
    get_spreadsheets
    get_spreadsheet_properties_defaultformat_backgroundcolor
    get_spreadsheet_properties_defaultformat_backgroundcolor_red
    get_spreadsheet_properties_locale
    get_spreadsheet_properties_title
    get_spreadsheet_uri
    get_spreadsheet_attrs_joe
    get_worksheet_properties_index
    get_worksheet_properties_rowcount
    get_worksheet_properties_index_rowcount
    delete_spreadsheet
    post_spreadsheet_copy
  ));
  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  return;
}

sub _constructor : Tests(7) {
  my $self = shift;

  ok my $ss = $self->_fake_spreadsheet(), 'Constructor should succeed';
  isa_ok $ss, Spreadsheet, 'Constructor with "id" returns';

  ok $ss = $self->_fake_spreadsheet(name => fake_spreadsheet_name()),
    'Constructor with "name" should succeed';
  isa_ok $ss, Spreadsheet, 'Constructor with "name" returns';

  ok $ss = $self->_fake_spreadsheet(uri => fake_spreadsheet_uri()),
    'Constructor with "uri`" should succeed';
  isa_ok $ss, Spreadsheet, 'Constructor with "uri" returns';

  throws_ok sub { $ss = Spreadsheet->new(sheets_api => fake_sheets_api()) },
    qr/At least one of/i,
    'Constructor with missing params should throw';

  return;
}

sub api : Tests(2) {
  my $self = shift;

  $self->_fake_http_response();
  my $ss = $self->_fake_spreadsheet();
  is_valid $ss->api(), EmptyHashRef, 'Empty get';
  my $transaction = $ss->rest_api()->transaction();
  is $transaction->{request}->{uri}, sheets_endpoint() . "/" . fake_spreadsheet_id(),
    'Request base spreadsheet uri string is valid';

  return;
}

sub spreadsheet_id : Tests(5) {
  my $self = shift;

  my $ss = $self->_fake_spreadsheet();
  $self->_fake_http_response(response => 'die');  # should not have to make a call.
  is $ss->spreadsheet_id(), fake_spreadsheet_id(), 'Spreadsheet with "id" returns "id"';

  $ss = $self->_fake_spreadsheet(name => fake_spreadsheet_name());
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_id(), fake_spreadsheet_id(), 'Spreadsheet with "name" returns "id"';

  $ss = $self->_fake_spreadsheet(uri => fake_spreadsheet_uri());
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_id(), fake_spreadsheet_id(), 'Spreadsheet with "uri" returns "id"';

  $ss = $self->_fake_spreadsheet(name => fake_spreadsheet_name2());
  $self->_fake_http_response_by_uri();
  throws_ok sub { $ss->spreadsheet_id(); }, qr/More than one/i, 'Spreadsheet with more than one name should throw';

  $ss = $self->_fake_spreadsheet(name => 'no_shuch_spreadsheet');
  $self->_fake_http_response_by_uri();
  throws_ok sub { $ss->spreadsheet_id(); }, qr/not found/i, 'Spreadsheet with no such name should throw';

  return;
}

sub spreadsheet_name : Tests(3) {
  my $self = shift;

  my $ss = $self->_fake_spreadsheet();
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_name(), fake_spreadsheet_name(), 'Spreadsheet with "id" returns "name"';

  $ss = $self->_fake_spreadsheet(name => fake_spreadsheet_name());
  $self->_fake_http_response(response => 'die');  # should not have to make a call.
  is $ss->spreadsheet_name(), fake_spreadsheet_name(), 'Spreadsheet with "name" returns "name"';

  $ss = $self->_fake_spreadsheet(uri => fake_spreadsheet_uri());
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_name(), fake_spreadsheet_name(), 'Spreadsheet with "uri" returns "name"';

  return;
}

sub spreadsheet_uri : Tests(3) {
  my $self = shift;

  my $ss = $self->_fake_spreadsheet();
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_uri(), fake_spreadsheet_uri(), 'Spreadsheet with "id" returns "uri"';

  $ss = $self->_fake_spreadsheet(name => fake_spreadsheet_name());
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_uri(), fake_spreadsheet_uri(), 'Spreadsheet with "name" returns "uri"';

  $ss = $self->_fake_spreadsheet(uri => fake_spreadsheet_uri());
  $self->_fake_http_response(response => 'die');  # should not have to make a call.
  is $ss->spreadsheet_uri(), fake_spreadsheet_uri(), 'Spreadsheet with "uri" returns "uri"';

  return;
}

sub spreadsheet_title : Tests(1) {
  my $self = shift;
  my $ss = $self->_fake_spreadsheet();
  $self->_fake_http_response_by_uri();
  is $ss->spreadsheet_title(), $ss->spreadsheet_name(), 'Spreadsheet title is the same as name';
  return;
}

sub attrs : Tests(2) {
  my $self = shift;
  $self->_fake_http_response_by_uri();
  my $ss = $self->_fake_spreadsheet();
  my $uri = fake_spreadsheet_uri();
  like $ss->attrs('spreadsheetUrl')->{spreadsheetUrl}, qr|\Q$uri\E|, 'Attrs retrieves spreadsheet uri';
  throws_ok sub { $ss->attrs('joe') }, qr|INVALID_ARGUMENT|, 'Bad attrs should throw';
  return;
}

sub properties : Tests(4) {
  my $self = shift;
  $self->_fake_http_response_by_uri();
  my $ss = $self->_fake_spreadsheet();
  is $ss->properties('locale')->{'locale'}, 'en_US', 'Locale is en_US';
  is $ss->properties('defaultFormat.backgroundColor')->{defaultFormat}->{backgroundColor}->{green},
    1, 'Background has green';
  is $ss->properties('defaultFormat.backgroundColor.red')->{defaultFormat}->{backgroundColor}->{red},
    1, 'Background has red';
  is $ss->properties('defaultFormat.backgroundColor.red')->{defaultFormat}->{backgroundColor}->{green},
    undef, 'Background color not asked for is undef';
  return;
}

sub worksheet_properties : Tests(5) {
  my $self = shift;
  $self->_fake_http_response_by_uri();
  my $ss = $self->_fake_spreadsheet();

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
  $self->_fake_http_response_by_uri();
  my $ss = $self->_fake_spreadsheet();

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

sub copy_spreadsheet : Tests(3) {
  my $self = shift;
  $self->_fake_http_response_by_uri();
  my $ss = $self->_fake_spreadsheet();
  
  isa_ok $ss->copy_spreadsheet(), Spreadsheet, 'Copy sheet';
  isa_ok $ss->copy_spreadsheet(
    name => fake_spreadsheet_name()
  ), Spreadsheet, 'Copy sheet with name';
  isa_ok $ss->copy_spreadsheet(
    title => fake_spreadsheet_name()
  ), Spreadsheet, 'Copy sheet with title';

  return;
}

sub delete_spreadsheet : Tests(1) {
  my $self = shift;
  my $ss = $self->_fake_spreadsheet();
  $self->_fake_http_response_by_uri();

  is $ss->delete_spreadsheet(), 1, 'Delete should return 1';

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

sub _fake_spreadsheet {
  my $self = shift;
  my %p = @_;
  $p{id} = fake_spreadsheet_id() if !%p;
  return Spreadsheet->new(%p, sheets_api => fake_sheets_api());
}

1;
