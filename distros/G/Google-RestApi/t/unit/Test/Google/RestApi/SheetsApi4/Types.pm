package Test::Google::RestApi::SheetsApi4::Types;

# this does basic tests of each type of range, but does not test
# Range::factory or any more complex tests.

use Test::Unit::Setup;

use parent 'Test::Class';

# steal the flatten_range routine from utils object.
use Google::RestApi::Utils qw(flatten_range);
use Google::RestApi::Types qw( :all );
use Google::RestApi::SheetsApi4::Types qw( :all );

sub range_col : Tests(43) {
  my $self = shift;

  _test_range_col('A', 'A:A');
  _test_range_col('A:A', 'A:A');

  _test_range_col(['A'], 'A:A');
  _test_range_col([['A']], 'A:A');
  _test_range_col([1], 'A:A');
  _test_range_col([[1]], 'A:A');
  
  _test_range_col({col => 'A'}, 'A:A');
  _test_range_col([{col => 'A'}], 'A:A');
  _test_range_col({col => 1}, 'A:A');
  _test_range_col([{col => 1}], 'A:A');

  _test_range_col(['A', undef], 'A:A');
  _test_range_col([['A', undef]], 'A:A');
  _test_range_col(['A', 0], 'A:A');
  _test_range_col([['A', 0]], 'A:A');
  _test_range_col(['A', ''], 'A:A');
  _test_range_col([['A', '']], 'A:A');
  
  _test_range_col('A5:A10', 'A5:A10');

  _test_range_col('AA', 'AA:AA');
  _test_range_col([27], 'AA:AA');  
  _test_range_col({col => 27}, 'AA:AA');  

  is_not_valid {col => 'A', row => 1}, RangeCol, "Column '{col => 'A', row => 1}'";
  is_not_valid {row => 1}, RangeCol, "Column '{row => 1}'";
  is_not_valid ['A', 1], RangeCol, "Column '['A', 1]'";

  return;
}

sub _test_range_col {
  my ($col, $is) = @_;
  my $flat = flatten_range($col);
  my ($valid) = is_valid $col, RangeCol, "Column '$flat'";
  is $valid, $is, "Column is '$is'";
  return;
}

sub range_row : Tests(27) {
  my $self = shift;

  _test_range_row(1, '1:1');
  _test_range_row('1:1', '1:1');

  _test_range_row({row => 1}, '1:1');
  _test_range_row([{row => 1}], '1:1');

  _test_range_row([undef, 1], '1:1');
  _test_range_row([[undef, 1]], '1:1');
  _test_range_row([0, 1], '1:1');
  _test_range_row([[0, 1]], '1:1');
  _test_range_row(['', 1], '1:1');
  _test_range_row([['', 1]], '1:1');
  
  _test_range_row('A1:E1', 'A1:E1');

  _test_range_row(11, '11:11');

  is_not_valid {col => 1, row => 1}, RangeRow, "Row '{col => 1, row => 1}'";
  is_not_valid [1, 1], RangeRow, "Row '[1, 1]'";
  is_not_valid ['A', 1], RangeRow, "Row '['A', 1]'";

  return;
}

sub _test_range_row {
  my ($row, $is) = @_;
  my $flat = flatten_range($row);
  my ($valid) = is_valid $row, RangeRow, "Row '$flat'";
  is $valid, $is, "Row is '$is'";
  return;
}

sub range_cell : Tests(30) {
  my $self = shift;

  _test_range_cell('A1', 'A1');

  _test_range_cell(['A', 1], 'A1');
  _test_range_cell([['A', 1]], 'A1');
  _test_range_cell([1, 1], 'A1');
  _test_range_cell([[1, 1]], 'A1');

  _test_range_cell({col => 'A', row => 1}, 'A1');
  _test_range_cell([{col => 'A', row => 1}], 'A1');
  _test_range_cell({col => 1, row => 1}, 'A1');
  _test_range_cell([{col => 1, row => 1}], 'A1');
  
  _test_range_cell('A1:A1', 'A1');
  
  _test_range_cell('AB12', 'AB12');
  _test_range_cell('AB12:AB12', 'AB12');
  _test_range_cell(['AB', '12'], 'AB12');
  _test_range_cell({col => 'AB', row => 12}, 'AB12');

  is_not_valid {row => 1}, RangeCell, "Cell '{row => 1}'";
  is_not_valid [1], RangeCell, "Cell '[1]'";

  return;
}

sub _test_range_cell {
  my ($cell, $is) = @_;
  my $flat = flatten_range($cell);
  my ($valid) = is_valid $cell, RangeCell, "Cell '$flat'";
  is $valid, $is, "Cell is '$is'";
  return;
}


sub range_any : Tests(32) {
  my $self = shift;
  _test_range_any('A1:B2', 'A1:B2');
  _test_range_any([[1, 1], [2, 2]], 'A1:B2');
  _test_range_any([{col => 1, row => 1}, {col => 2, row => 2}], 'A1:B2');
  _test_range_any(['A1', [2, 2]], "A1:B2");
  _test_range_any(['A1', {col => 2, row => 2}], "A1:B2");
  _test_range_any([{col => 1, row => 1}, 'B2'], "A1:B2");
  _test_range_any([{col => 1, row => 1}, [2, 2]], "A1:B2");
  _test_range_any([[1, 1], {col => 2, row => 2}], "A1:B2");

  _test_range_any([ { col => 'A', row => 5 }, { col => 'A' } ], 'A5:A');
  _test_range_any([ { col => 'A' }, { col => 'A', row => 5 } ], 'A:A5');

  _test_range_any([ { col => 'A', row => 5 }, 'A' ], 'A5:A');
  _test_range_any([ 'A', { col => 'A', row => 5 } ], 'A:A5');

  _test_range_any([ { col => 'E', row => 1 }, { row => 1 } ], 'E1:1');
  _test_range_any([ { row => 1 }, { col => 'E', row => 1 } ], '1:E1');

  _test_range_any([ { col => 'E', row => 1 }, 1 ], 'E1:1');
  _test_range_any([ 1, { col => 'E', row => 1 } ], '1:E1');

  
  return;
}

sub _test_range_any {
  my ($range, $is) = @_;
  my $flat = flatten_range($range);
  my ($valid) = is_valid $range, RangeAny, "Range '$flat'";
  is $valid, $is, "Range is '$is'";
  return;
}

1;
