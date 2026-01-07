package Test::Google::RestApi::SheetsApi4::Worksheet;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Worksheet';

use parent 'Test::Unit::TestBase';

init_logger;

sub setup : Tests(setup) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  my $all = $ws0->range("A1:C1000");
  $all->reset()->submit_requests;

  return;
}

sub _constructor : Tests(7) {
  my $self = shift;

  my $ms = $self->mock_spreadsheet();
  my $ms_id = $ms->spreadsheet_id;

  throws_ok sub { Worksheet->new(spreadsheet => $ms) },
    qr/At least one of/i,
    'Constructor with missing params should throw';

  ok my $ws0 = Worksheet->new(spreadsheet => $ms, id => 0), 'Constructor with "id" should succeed';
  isa_ok $ws0, Worksheet, 'Constructor with "id" returns';

  ok $ws0 = Worksheet->new(spreadsheet => $ms, name => mock_worksheet_name()),
    'Constructor with "name" should succeed';
  isa_ok $ws0, Worksheet, 'Constructor with "name" returns';

  ok $ws0 = Worksheet->new(spreadsheet => $ms, uri => $self->mock_worksheet_uri()),
    'Constructor with "uri`" should succeed';
  isa_ok $ws0, Worksheet, 'Constructor with "uri" returns';

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

  my $ws0 = $self->mock_worksheet();
  is $ws0->col('A'), undef, 'Col returns undef';
  is_deeply $ws0->col('A', [qw(joe)]), [qw(joe)], 'Col returns the correct array of values';
  # just do a basic test to make sure bad range args are not accepted. range tests will
  # do more comprehensive negative tests. we are only testing worksheet::col here.
  throws_ok sub { $ws0->col('A1:B2') }, qr/Unable to translate/i, 'Bad col throws';
  
  return;
}

sub cols : Tests(3) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  is_valid $ws0->cols(['A', 'B', 'C']), ArrayRef[Undef], 'Cols returns undef';
  my $cols = [['joe'], ['fred'], ['charlie']];
  is_deeply $ws0->cols(['A', 'B', 'C'], $cols), $cols, 'Cols returns the correct array of values';
  throws_ok sub { $ws0->cols(['A1:B2']) }, qr/Unable to translate/i, 'Bad cols throws';
  
  return;
}

sub row : Tests(3) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  is $ws0->row(1), undef, 'Row returns undef';
  is_deeply $ws0->row(1, [qw(joe)]), [qw(joe)], 'Row returns an array of values';
  throws_ok sub { $ws0->row('A1:B2') }, qr/Unable to translate/i, 'Bad row throws';
  
  return;
}

sub rows : Tests(3) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet();
  is_valid $ws0->rows([1, 2, 3]), ArrayRef[Undef], 'Rows returns undef';
  my $rows = [['joe'], ['fred'], ['charlie']];
  is_deeply $ws0->rows([1, 2, 3], $rows), $rows, 'Rows returns the correct array of values';
  throws_ok sub { $ws0->rows(['A1:B2']) }, qr/Unable to translate/i, 'Bad rows throws';
  
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

1;
