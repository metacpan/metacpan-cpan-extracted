package Test::Google::RestApi::SheetsApi4::Range::Cell;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

init_logger;

my $sheet = "'Sheet1'";

sub range : Tests(13) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet;

  is $ws0->range_cell('A1')->range(),       "$sheet!A1", "A1 should be A1";
  is $ws0->range_cell(['A', 1])->range(),   "$sheet!A1", "['A', 1] should be A1";
  is $ws0->range_cell([['A', 1]])->range(), "$sheet!A1", "[['A', 1]] should be A1";
  is $ws0->range_cell([1, 1])->range(),     "$sheet!A1", "[1, 1] should be A1";
  is $ws0->range_cell([[1, 1]])->range(),   "$sheet!A1", "[[1, 1]] should be A1";
  is $ws0->range_cell({row => 1, col => 'A'})->range(),     "$sheet!A1", "{row => 1, col => 'A'} should be A1";
  is $ws0->range_cell([ {row => 1, col => 'A'} ])->range(), "$sheet!A1", "[{row => 1, col => 'A'}] should be A1";
  is $ws0->range_cell({row => 1, col => 1})->range(),       "$sheet!A1", "{row => 1, col => 1} should be A1";
  is $ws0->range_cell([ {row => 1, col => 1} ])->range(),   "$sheet!A1", "[{row => 1, col => 1}] should be A1";
  is $ws0->range_cell([['A', 1], ['A', 1]])->range(),       "$sheet!A1", "[['A', 1], ['A', 1]] should be A1";
  is $ws0->range_cell([[1, 1], [1, 1]])->range(),           "$sheet!A1", "[[1, 1], [1, 1]] should be A1";
  is $ws0->range_cell( {row => 1, col => 'A'}, {row => 1, col => 'A'} )->range(), "$sheet!A1", "{row => 1, col => 'A'}, {row => 1, col => 'A'} should be A1";
  is $ws0->range_cell( {row => 1, col => 1}, {row => 1, col => 1} )->range(), "$sheet!A1", "{row => 1, col => 1}, {row => 1, col => 1} should be A1";

  return;
}

1;
