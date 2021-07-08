package Test::Google::RestApi::SheetsApi4::Worksheet;

use Test::Most;
use YAML::Any qw(Dump);

use Utils qw(:all);

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Base);

sub class { 'Google::RestApi::SheetsApi4::Worksheet' }

# sub constructor : Tests(4) { shift->SUPER::constructor(@_); }

sub tie : Tests(1) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  is_hash $worksheet->tie(), "Empty tie";

  return;
}

sub tie_cells : Tests(16) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cells;
  is_hash $cells = $worksheet->tie_cells('A1', 'B2'), "Tying cells 'A1' and 'B2'";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{A1}, Cell, "Key 'A1' should be a cell";
  is $cells->{A1}->range(), "$self->{name}A1", "Cell 'A1' is range 'A1'";
  isa_ok $cells->{B2}, Cell, "Key 'B2' should be a cell";
  is $cells->{B2}->range(), "$self->{name}B2", "Cell 'B2' is range 'B2'";

  isa_ok $cells->{C3} = "Charlie", Cell, "Auto-creating cell 'C3'";
  isa_ok $cells->{C3}, Cell, "Key 'C3' should be a cell";
  is $cells->{C3}->range(), "$self->{name}C3", "Cell 'C3' is range 'C3'";

  is_hash $cells = $worksheet->tie_cells({ fred => 'A1' }), "Tying cells 'fred => A1'";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{fred}, Cell, "Key 'fred' should be a cell";
  is $cells->{fred}->range(), "$self->{name}A1", "Cell 'fred => A1' is range 'A1'";

  is_hash $cells = $worksheet->tie_cells({ fred => [1, 1] }), "Tying cells 'fred => [1, 1]'";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{fred}, Cell, "Key 'fred' should be a cell";
  is $cells->{fred}->range(), "$self->{name}A1", "Cell 'fred => [1, 1]' is 'A1'";

  is_hash $cells = $worksheet->tie_cells({ fred => [[1,1], [2,2]] }), "Tying a cell to a bad range";
  tied(%$cells)->fetch_range(1);
  throws_ok sub { $cells->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_cols : Tests(10) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cols;
  is_hash $cols = $worksheet->tie_cols(1, 2), "Tying cols '1' and '2'";
  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{1}, Col, "Key '1' should be a col";
  is $cols->{1}->range(), "$self->{name}A:A", "Col '1' is range 'A:A'";
  isa_ok $cols->{2}, Col, "Key '2' should be a col";
  is $cols->{2}->range(), "$self->{name}B:B", "Col '2' is range 'B:B'";

  is_hash $cols = $worksheet->tie_cols({ fred => '1' }), "Tying cols 'fred => 1'";
  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{fred}, Col, "Key 'fred' should be a col";
  is $cols->{fred}->range(), "$self->{name}A:A", "Col 'fred => 1' is range 'A:A'";

  is_hash $cols = $worksheet->tie_cols({ fred => [[1,1], [2,2]] }), "Tying cols to a bad range";
  tied(%$cols)->fetch_range(1);
  throws_ok sub { $cols->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_rows : Tests(10) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $rows;
  is_hash $rows = $worksheet->tie_rows(1, 2), "Tying rows '1' and '2'";
  tied(%$rows)->fetch_range(1);
  isa_ok $rows->{1}, Row, "Key '1' should be a row";
  is $rows->{1}->range(), "$self->{name}1:1", "Key '1' should be range '1:1'";
  isa_ok $rows->{2}, Row, "Key '2' should be a row";
  is $rows->{2}->range(), "$self->{name}2:2", "Key '2' should be range '2:2'";

  is_hash $rows = $worksheet->tie_rows({ fred => '1' }), "Tying rows 'fred => 1'";
  tied(%$rows)->fetch_range(1);
  isa_ok $rows->{fred}, Row, "Key 'fred' should be a row";
  is $rows->{fred}->range(), "$self->{name}1:1", "Row 'fred => 1' is range '1:1'";

  is_hash $rows = $worksheet->tie_rows({ fred => [[1,1], [2,2]] }), "Tying rows to a bad range";
  tied(%$rows)->fetch_range(1);
  throws_ok sub { $rows->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

1;
