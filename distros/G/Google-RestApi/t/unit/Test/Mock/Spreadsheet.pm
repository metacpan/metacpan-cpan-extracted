package Test::Mock::Spreadsheet;

use strict;
use warnings;

use Test::MockObject::Extends;

use Test::Mock::SheetsApi4;
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';
 
sub new {
  my $self = Spreadsheet->new(
    sheets    => Test::Mock::SheetsApi4->new(),
    config_id => 'customers',
  );

  $self = Test::MockObject::Extends->new($self);

  $self->mock(
    'spreadsheet_id', sub { 'mock_sheets_id'; }
  )->mock(
    'open_worksheet', sub { Test::Mock::Worksheet->new() }
  );

  return $self;
}

1;
