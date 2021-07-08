package Test::Google::RestApi::SheetsApi4::Range;

use YAML::Any qw(Dump);
use Test::Most;

use Utils qw(:all);

use aliased 'Google::RestApi::SheetsApi4::Range';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

sub class { 'Google::RestApi::SheetsApi4::Range' }

my $sheet = 'Customer Addresses';

sub constructor : Tests(4) {
  my $self = shift;
  $self->SUPER::constructor(
    worksheet => $self->worksheet(),
    range     => "A1",
  );
  can_ok $self, 'range';
  return;
}

sub range : Tests(6) {
  my $self = shift;

  my $x = "A1:B2";

  my $range;
  isa_ok $range = $self->new_range($x), Range, "New range '$x'";
  is $range->range(), "$self->{name}$x", "A1:B2 should be $x";

  $range = $self->new_range([[1,1], [2,2]]);
  is $range->range(), "$self->{name}$x", "[[1,1], [2,2]] should be $x";

  $range = $self->new_range([['A',1], ['B',2]]);
  is $range->range(), "$self->{name}$x", "[[A,1], [B,2]] should be $x";

  $range = $self->new_range([{row => 1, col => 1}, {row => 2, col => 2}]);
  is $range->range(), "$self->{name}$x", "[{row => 1, col => 1}, {row => 2, col => 2}] should be $x";

  $range = $self->new_range([{row => 1, col => 'A'}, {row => 2, col =>'B'}]);
  is $range->range(), "$self->{name}$x", "[{row => 1, col => A}, {row => 2, col => B}] should be $x";

  return;
}

sub range_col : Tests(27) {
  my $self = shift;

  my $col = $self->class()->can('is_colA1');

  is $col->("A"), 1, "Range A should be a col";
  is $col->("A:A"), 1, "Range A:A should be a col";
  is $col->("A1:A"), 1, "Range A1:A should be a col";
  is $col->("A1:A2"), 1, "Range A1:A2 should be a col";

  is $col->("$sheet!A"), 1, "Range $sheet!A should be a col";
  is $col->("$sheet!A:A"), 1, "Range $sheet!A:A should be a col";
  is $col->("$sheet!A1:A"), 1, "Range $sheet!A1:A should be a col";
  is $col->("$sheet!A1:A2"), 1, "Range $sheet!A1:A2 should be a col";

  is $col->("'$sheet'!A"), 1, "Range '$sheet'!A should be a col";
  is $col->("'$sheet'!A:A"), 1, "Range '$sheet'!A:A should be a col";
  is $col->("'$sheet'!A1:A"), 1, "Range '$sheet'!A1:A should be a col";
  is $col->("'$sheet'!A1:A2"), 1, "Range '$sheet'!A1:A2 should be a col";
  is $col->("'$sheet'!A5:A"), 1, "Range '$sheet'!A5:A should be a col";

  is $col->("AZ"), 1, "Range AZ should be a col";
  is $col->("AZ:AZ"), 1, "Range AZ:AZ should be a col";
  is $col->("AZ1:AZ"), 1, "Range AZ1:AZ should be a col";
  is $col->("AZ1:AZ2"), 1, "Range AZ1:AZ2 should be a col";

  is $col->("AA:AZ"), undef, "Range AA:AZ should not be a col";
  is $col->("AA1:AZ"), undef, "Range AA1:AZ should not be a col";
  is $col->("AA1:AZ2"), undef, "Range AA1:AZ2 should not be a col";

  is $col->("1"), undef, "Range 1 should not be a col";
  is $col->("1:1"), undef, "Range 1:1 should not be a col";
  is $col->("A1:1"), undef, "Range A1:1 should not be a col";
  is $col->("A1"), undef, "Range A1 should not be a col";
  is $col->("A1:B2"), undef, "Range A1:B2 should not be a col";

  is $col->([[1, 1]]), undef, "Range [[1, 1]] should not be a col";
  is $col->({ col => 1, row => 1 }), undef, "Range { col => 1, row => 1 } should not be a col";

  return;
}

sub range_row : Tests(27) {
  my $self = shift;

  my $row = $self->class()->can('is_rowA1');

  is $row->("1"), 1, "Range 1 should be a row";
  is $row->("1:1"), 1, "Range 1:1 should be a row";
  is $row->("1:A1"), 1, "Range 1:A1 should be a row";
  is $row->("A1:B1"), 1, "Range A1:B1 should be a row";

  is $row->("$sheet!1"), 1, "Range $sheet!1 should be a row";
  is $row->("$sheet!1:1"), 1, "Range $sheet!1:1 should be a row";
  is $row->("$sheet!1:A1"), 1, "Range $sheet!1:A1 should be a row";
  is $row->("$sheet!A1:B1"), 1, "Range $sheet!A1:B1 should be a row";

  is $row->("'$sheet'!1"), 1, "Range '$sheet'!1 should be a row";
  is $row->("'$sheet'!1:1"), 1, "Range '$sheet'!1:1 should be a row";
  is $row->("'$sheet'!A1:1"), 1, "Range '$sheet'!A1:1 should be a row";
  is $row->("'$sheet'!A1:B1"), 1, "Range '$sheet'!A1:B1 should be a row";
  is $row->("'$sheet'!D1:1"), 1, "Range '$sheet'!D1:1 should be a row";

  is $row->("11"), 1, "Range 11 should be a row";
  is $row->("11:Z11"), 1, "Range 11:Z11 should be a row";
  is $row->("Z11:11"), 1, "Range Z11:11 should be a row";
  is $row->("A11:Z11"), 1, "Range A11:Z11 should be a row";

  is $row->("11:12"), undef, "Range 11:12 should not be a row";
  is $row->("A11:A12"), undef, "Range A11:A12 should not be a row";
  is $row->("A11:AZ12"), undef, "Range A11:AZ12 should not be a row";

  is $row->("A"), undef, "Range A should not be a row";
  is $row->("A:A"), undef, "Range A:A should not be a row";
  is $row->("A1:A"), undef, "Range A1:A should not be a row";
  is $row->("A1"), undef, "Range A1 should not be a row";
  is $row->("A1:B2"), undef, "Range A1:B2 should not be a row";

  is $row->([[1, 1]]), undef, "Range [[1, 1]] should not be a row";
  is $row->({ col => 1, row => 1 }), undef, "Range { col => 1, row => 1 } should not be a row";

  return;
}

sub range_cell : Tests(14) {
  my $self = shift;

  my $cell = $self->class()->can('is_cellA1');

  is $cell->("A1"), 1, "Range A1 should be a cell";
  is $cell->("AZ99"), 1, "Range AZ99 should be a cell";
  is $cell->("$sheet!AZ99"), 1, "Range $sheet!AZ99 should be a cell";
  is $cell->("'$sheet'!AZ99"), 1, "Range '$sheet'!AZ99 should be a cell";

  is $cell->("A1:B2"), undef, "Range A1:B2 should not be a cell";
  is $cell->("A"), undef, "Range A should not be a cell";
  is $cell->("A:A"), undef, "Range A:A should not be a cell";
  is $cell->("A1:A"), undef, "Range A1:A should not be a cell";

  is $cell->("1"), undef, "Range 1 should not be a cell";
  is $cell->("1:1"), undef, "Range 1:1 should not be a cell";
  is $cell->("1:A1"), undef, "Range 1:A1 should not be a cell";
  is $cell->("A1:1"), undef, "Range A1:1 should not be a cell";

  is $cell->([[1, 1]]), undef, "Range [[1, 1]] should not be a cell";
  is $cell->({ col => 1, row => 1 }), undef, "Range { col => 1, row => 1 } should not be a cell";

  return;
}

sub range_config : Tests(9) {
  my $self = shift;

  my $x = 'B';
  my $y = 3;

  my $range = $self->new_range([['id'],['id']]);
  is $range->range(), "$self->{name}$x:$x", "[['id'],['id']] should be $x:$x";

  $range = $self->new_range([['id']]);
  is $range->range(), "$self->{name}$x:$x", "[['id']] should be $x:$x";

  $range = $self->new_range(['id']);
  is $range->range(), "$self->{name}$x:$x", "['id'] should be $x:$x";

  $range = $self->new_range([['id', 5],['id']]);
  is $range->range(), "$self->{name}${x}5:$x", "[['id', 5],['id']] should be ${x}5:$x";

  $range = $self->new_range([[undef, 'george'],[undef, 'george']]);
  is $range->range(), "$self->{name}$y:$y", "[[undef, 'george'],[undef, 'george']] should be $y:$y";
  $range = $self->new_range([[0, 'george'],[0, 'george']]);
  is $range->range(), "$self->{name}$y:$y", "[[0, 'george'],[0, 'george']] should be $y:$y";
  $range = $self->new_range([['', 'george'],['', 'george']]);
  is $range->range(), "$self->{name}$y:$y", "[['', 'george'],['', 'george']] should be $y:$y";

  $range = $self->new_range([['id', 'sam'],['address', 'george']]);
  is $range->range(), "$self->{name}B2:D3", "[['id', 'sam'],['address', 'george']] should be B2:D3";

  $range = $self->new_range([ {col => 'id', row => 'sam'}, {col => 'address', row => 'george'} ]);
  is $range->range(), "$self->{name}B2:D3", "[ {col => 'id', row => 'sam'}, {col => 'address', row => 'george'} ] should be B2:D3";

  return;
}

sub range_named : Tests(3) {
  my $self = shift;
  is $self->new_range("George")->is_named(), 1, "George should be a named range";
  is $self->new_range("A1")->is_named(), undef, "A1 should not be a named range";
  is $self->new_range("A1:B2")->is_named(), undef, "A1:B2 should not be a named range";
  return;
}

sub range_mixed : Tests(6) {
  my $self = shift;

  my $range = $self->new_range(['A1', [2, 2]]);
  is $range->range(), "$self->{name}A1:B2", "[A1, [2, 2]] should be A1:B2";

  $range = $self->new_range(['A1', {col => 2, row => 2}]);
  is $range->range(), "$self->{name}A1:B2", "[A1, {col => 2, row => 2}] should be A1:B2";

  $range = $self->new_range([[1, 1], 'B2']);
  is $range->range(), "$self->{name}A1:B2", "[[1, 1], 'B2'] should be A1:B2";

  $range = $self->new_range([{col => 1, row => 1}, 'B2']);
  is $range->range(), "$self->{name}A1:B2", "[{col => 1, row => 1}, 'B2'] should be A1:B2";

  $range = $self->new_range([{col => 1, row => 1}, [2, 2]]);
  is $range->range(), "$self->{name}A1:B2", "[{col => 1, row => 1}, [2, 2]] should be A1:B2";

  $range = $self->new_range([[1, 1], {col => 2, row => 2}]);
  is $range->range(), "$self->{name}A1:B2", "[[1, 1], {col => 2, row => 2}] should be A1:B2";

  return;
}

sub range_bad : Tests(3) {
  my $self = shift;

  # should be able to support this but will make the range routine too
  # unnecessarily complex, and the easy workaround is 'A1:B2'.
  my $range = $self->new_range(["A1", "B2"]);
  throws_ok { $range->range() } $self->{err}, "[A1, B2] should fail";

  $range = $self->new_range('bad');
  throws_ok { $range->range() } $self->{err}, "'bad' should fail";

  $range = $self->new_range(['bad']);
  throws_ok { $range->range() } $self->{err}, "['bad'] should fail";

  return;
}

1;
