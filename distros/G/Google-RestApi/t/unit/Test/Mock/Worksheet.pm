package Test::Mock::Worksheet;

use strict;
use warnings;

use aliased 'Google::RestApi::SheetsApi4::Worksheet';
use Test::MockObject::Extends;

use Test::Mock::Spreadsheet;
 
sub new {
  my $self = Worksheet->new(
    spreadsheet => Test::Mock::Spreadsheet->new(),
    config_id   => 'addresses',
  );

  $self = Test::MockObject::Extends->new($self);

  $self->mock(
    'worksheet_id', sub { 'mock_worksheet_id'; }
  )->mock(
    'header_row', sub { ['', 'Customer ID', 'Customer Name', 'Address']; }
  )->mock(
    'header_col', sub { ['', 'Sam Brady', 'George Jones']; }
  );

  return $self;
}

1;
