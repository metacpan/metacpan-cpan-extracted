package Test::Google::RestApi::SheetsApi4::Worksheet;

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use aliased 'Google::RestApi::SheetsApi4::Worksheet';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';

# init_logger($TRACE);

sub class { Worksheet; }

sub setup : Tests(setup) {
  my $self = shift;
  $self->SUPER::setup(@_);

  $self->_uri_responses(qw(
    get_worksheet_properties_title_sheetid
    get_worksheet_values_col
    get_worksheet_values_cols
    get_worksheet_values_row
    get_worksheet_values_rows
    post_worksheet_values_x_y_z
    put_worksheet_values_col
    put_worksheet_values_row
  ));
  $self->_fake_http_auth();
  $self->_fake_http_no_retries();

  return;
}

sub _constructor : Tests(8) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $class = $self->class();

  use_ok $self->class();

  ok my $ws0 = $self->_fake_worksheet(), 'Constructor should succeed';
  isa_ok $ws0, $class, 'Constructor with "id" returns';

  ok $ws0 = $self->_fake_worksheet(name => fake_worksheet_name()),
    'Constructor with "name" should succeed';
  isa_ok $ws0, $class, 'Constructor with "name" returns';

  ok $ws0 = $self->_fake_worksheet(uri => fake_worksheet_uri()),
    'Constructor with "uri`" should succeed';
  isa_ok $ws0, $class, 'Constructor with "uri" returns';

  throws_ok sub { $ws0 = $class->new(spreadsheet => fake_spreadsheet()) },
    qr/At least one of/i,
    'Constructor with missing params should throw';

  return;
}

sub worksheet_id : Tests() {
  my $self = shift;
  return;
}

sub worksheet_name : Tests() {
  my $self = shift;
  return;
}

sub worksheet_uri : Tests() {
  my $self = shift;
  return;
}

sub properties : Tests() {
  my $self = shift;
  return;
}

sub col : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $ws0 = $self->_fake_worksheet();
  is $ws0->col('A'), undef, 'Col returns undef';
  is_deeply $ws0->col('A', [qw(joe)]), [qw(joe)], 'Col returns the correct array of values';
  # just do a basic test to make sure bad range args are not accepted. range tests will
  # do more comprehensive negative tests. we are only testing worksheet::col here.
  throws_ok sub { $ws0->col('A1:B2') }, qr/Unable to translate/i, 'Bad col throws';
  
  return;
}

sub cols : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $ws0 = $self->_fake_worksheet();
  is_valid $ws0->cols(['A', 'B', 'C']), ArrayRef[Undef], 'Cols returns undef';
  my $cols = [['joe'], ['fred'], ['charlie']];
  is_deeply $ws0->cols(['A', 'B', 'C'], $cols), $cols, 'Cols returns the correct array of values';
  throws_ok sub { $ws0->cols(['A1:B2']) }, qr/Unable to translate/i, 'Bad cols throws';
  
  return;
}

sub row : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $ws0 = $self->_fake_worksheet();
  is $ws0->row(1), undef, 'Row returns undef';
  is_deeply $ws0->row(1, [qw(joe)]), [qw(joe)], 'Row returns an array of values';
  throws_ok sub { $ws0->row('A1:B2') }, qr/Must be a positive integer/i, 'Bad row throws';
  
  return;
}

sub rows : Tests(3) {
  my $self = shift;

  $self->_fake_http_response_by_uri();
  my $ws0 = $self->_fake_worksheet();
  is_valid $ws0->rows([1, 2, 3]), ArrayRef[Undef], 'Rows returns undef';
  my $rows = [['joe'], ['fred'], ['charlie']];
  is_deeply $ws0->rows([1, 2, 3], $rows), $rows, 'Rows returns the correct array of values';
  throws_ok sub { $ws0->rows(['A1:B2']) }, qr/did not pass type constraint/i, 'Bad rows throws';
  
  return;
}

sub cell : Tests() {
  my $self = shift;
}

sub cells : Tests() {
  my $self = shift;
  return;
}

sub enable_header_col : Tests() {
  my $self = shift;
  return;
}

sub header_row : Tests() {
  my $self = shift;
  return;
}

sub name_value_pairs : Tests() {
  my $self = shift;
  return;
}

sub tie_ranges : Tests() {
  my $self = shift;
  return;
}

sub tie_cols : Tests() {
  my $self = shift;
  return;
}

sub tie_rows : Tests() {
  my $self = shift;
  return;
}

sub tie_cells : Tests() {
  my $self = shift;
  return;
}

sub tie : Tests() {
  my $self = shift;
  return;
}

sub submit_requests : Tests() {
  my $self = shift;
  return;
}

sub config : Tests() {
  my $self = shift;
  return;
}

sub _fake_worksheet {
  my $self = shift;
  my %p = @_;
  $p{id} = fake_worksheet_id() if !%p;
  return $self->class()->new(%p, spreadsheet => fake_spreadsheet());
}

1;
