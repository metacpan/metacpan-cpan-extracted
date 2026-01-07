package Test::Google::RestApi::SheetsApi4::Range;

use Test::Unit::Setup;

use Google::RestApi::Types qw( :all );
use Google::RestApi::Utils qw( :all );

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

init_logger;

my $sheet = "'Sheet1'";

sub _constructor : Tests(2) {
  my $self = shift;

  my $range = Google::RestApi::SheetsApi4::Range::factory(
    worksheet => $self->mock_worksheet,
    range     => 'A1:B2',
  );
  isa_ok $range, Range, 'Constructor returns';
  can_ok $range, 'range';

  return;
}

# we don't want to recreate the 'types' tests here, just want to
# ensure that the factory object returns all the right objects.
sub factory : Tests(21) {
  my $self = shift;
  
  my $ws0 = $self->mock_worksheet;

  my $range = $ws0->range_factory('A1:B2');
  is $range->range(), "$sheet!A1:B2", "A1:B2 returns A1:B2";
  isa_ok $range, Range, "A1:B2 returns a Range object";

  
  $range = $ws0->range_factory('A:A');
  is $range->range(), "$sheet!A:A", "A:A returns A:A";
  isa_ok $range, Col, "A:A returns a Col object";

  $range = $ws0->range_factory('A1:A');
  is $range->range(), "$sheet!A1:A", "A1:A returns A1:A";
  isa_ok $range, Col, "A1:A returns a Col object";

  $range = $ws0->range_factory('A:A2');
  is $range->range(), "$sheet!A:A2", "A:A2 returns A:A2";
  isa_ok $range, Col, "A:A2 returns a Col object";

  $range = $ws0->range_factory('A');
  is $range->range(), "$sheet!A:A", "A returns A:A";
  isa_ok $range, Col, "A returns a Col object";

  
  $range = $ws0->range_factory('1:1');
  is $range->range(), "$sheet!1:1", "1:1 returns 1:1";
  isa_ok $range, Row, "1:1 returns a Row object";

  $range = $ws0->range_factory('A1:1');
  is $range->range(), "$sheet!A1:1", "A1:1 returns A1:1";
  isa_ok $range, Row, "A1:1 returns a Row object";

  $range = $ws0->range_factory('1:B1');
  is $range->range(), "$sheet!1:B1", "1:B1 returns 1:B1";
  isa_ok $range, Row, "1:B1 returns a Row object";

  $range = $ws0->range_factory('1');
  is $range->range(), "$sheet!1:1", "1 returns 1:1";
  isa_ok $range, Row, "1 returns a Row object";


  $range = $ws0->range_factory('A1');
  is $range->range(), "$sheet!A1", "A1 returns A1";
  isa_ok $range, Cell, "A1 returns a Cell object";

  $range = $ws0->range_factory("A1");
  is $range->named(), undef, "A1 should not be a named range";

  return;
}

sub clear {
}

sub values {
}

sub values_response_from_api {
}

sub batch_values {
}

sub append {
}

sub range : Tests(2) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet;
  isa_ok my $range = $ws0->range('A1:B2'), Range, "New range 'A1:B2'";
  is $range->range(), "$sheet!A1:B2", "A1:B2 should be '$sheet!A1:B2'";

  return;
}

sub range_to_array {
}

sub range_to_hash {
}

sub range_to_index {
}

sub range_to_dimension {
}

sub cell_at_offset : Tests(24) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet;

  for my $col_row (qw(A:A 1:1)) {
    my $range = $ws0->range($col_row);
    for (qw(col row)) {
      isa_ok my $cell = $range->cell_at_offset(0, $_), Cell, "Cell from $col_row, dim $_ at offset 0";
      is $cell->range(), "$sheet!A1", "Cell from $col_row, dim $_ offset 0 should be '$sheet!A1'";
    }
  }

  my $range = $ws0->range('A1');
  for (qw(col row)) {
    isa_ok my $cell = $range->cell_at_offset(0, $_), Cell, "Cell $_ at offset 0";
    is $cell->range(), "$sheet!A1", "$_ offset 0 should be '$sheet!A1'";
    is $range->cell_at_offset(1, $_), undef, "Cell at offset 1 is undef";
  }

  $range = $ws0->range('A1:B2');
  for (qw(col row)) {
    isa_ok my $cell = $range->cell_at_offset(0, $_), Cell, "Cell $_ at offset 0";
    is $cell->range(), "$sheet!A1", "$_ offset 0 should be '$sheet!A1'";

    isa_ok $cell = $range->cell_at_offset(3, $_), Cell, "Cell $_ at offset 3";
    is $cell->range(), "$sheet!B2", "$_ offset 3 should be '$sheet!B2'";
    
    is $range->cell_at_offset(4, $_), undef, "Cell at offset 4 is undef";
  }

  return;
}

sub offset {
}

sub offsets {
}

sub is_other_inside : Tests() {
  my $self = shift;
  
  my $ws0 = $self->mock_worksheet;

  my $outside = $ws0->range('A1:B2');
  my $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 1 is inside " . flatten_range($outside);

  $inside = $ws0->range('A2');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 2 is inside " . flatten_range($outside);

  $inside = $ws0->range('B1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 3 is inside " . flatten_range($outside);

  $inside = $ws0->range('B2');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 4 is inside " . flatten_range($outside);

  $inside = $ws0->range('C1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 5 is not inside " . flatten_range($outside);

  $inside = $ws0->range('B3');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 6 is not inside " . flatten_range($outside);
  
  $outside = $ws0->range('A');
  $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 7 is inside " . flatten_range($outside);
  $inside = $ws0->range('B1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 8 is not inside " . flatten_range($outside);
  
  $outside = $ws0->range('A2:A');
  $inside = $ws0->range('A2');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 9 is inside " . flatten_range($outside);
  $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 10 is not inside " . flatten_range($outside);
  $inside = $ws0->range('B1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 11 is not inside " . flatten_range($outside);

  $outside = $ws0->range('A2:A3');
  $inside = $ws0->range('A2');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 9 is inside " . flatten_range($outside);
  $inside = $ws0->range('A3');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 9 is inside " . flatten_range($outside);
  $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 10 is not inside " . flatten_range($outside);
  $inside = $ws0->range('B1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 11 is not inside " . flatten_range($outside);

  $outside = $ws0->range('1');
  $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 12 is inside " . flatten_range($outside);
  $inside = $ws0->range('A2');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 13 is not inside " . flatten_range($outside);

  $outside = $ws0->range('B1:1');
  $inside = $ws0->range('B1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 14 is inside " . flatten_range($outside);
  $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 15 is not inside " . flatten_range($outside);
  $inside = $ws0->range('A2');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 16 is not inside " . flatten_range($outside);

  $outside = $ws0->range('B1:C1');
  $inside = $ws0->range('B1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 14 is inside " . flatten_range($outside);
  $inside = $ws0->range('C1');
  is $outside->is_other_inside($inside), 1, flatten_range($inside) . " 14 is inside " . flatten_range($outside);
  $inside = $ws0->range('A1');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 15 is not inside " . flatten_range($outside);
  $inside = $ws0->range('A2');
  is $outside->is_other_inside($inside), undef, flatten_range($inside) . " 16 is not inside " . flatten_range($outside);

  return;
}

1;
