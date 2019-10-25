package Test::Google::RestApi::SheetsApi4::Worksheet;

use Test::Most;
use YAML::Any qw(Dump);

use aliased 'Google::RestApi::SheetsApi4::Range::Cell';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Base);

sub class { 'Google::RestApi::SheetsApi4::Worksheet' }

# sub constructor : Tests(4) { shift->SUPER::constructor(@_); }

sub tie : Tests(1) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  lives_ok sub { $worksheet->tie(); }, "Tie should live";

  return;
}

sub tie_cells : Tests(21) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cells;
  lives_ok sub { $cells = $worksheet->tie_cells('A1', 'B2'); }, "Tying cells 'A1' and 'B2' should live";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{A1}, Cell, "Key 'A1' should be a cell";
  can_ok $cells->{A1}, 'range';
  is $cells->{A1}->range(), "$self->{name}A1", "Cell 'A1' is range 'A1'";
  isa_ok $cells->{B2}, Cell, "Key 'B2' should be a cell";
  can_ok $cells->{B2}, 'range';
  is $cells->{B2}->range(), "$self->{name}B2", "Cell 'B2' is range 'B2'";

  lives_ok sub { $cells->{C3} = "Charlie"; }, "Auto-creating cell 'C3' should live";
  isa_ok $cells->{C3}, Cell, "Key 'C3' should be a cell";
  can_ok $cells->{C3}, 'range';
  is $cells->{C3}->range(), "$self->{name}C3", "Cell 'C3' is range 'C3'";

  lives_ok sub { $cells = $worksheet->tie_cells({ fred => 'A1' }); }, "Tying cells 'fred => A1' should live";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{fred}, Cell, "Key 'fred' should be a cell";
  can_ok $cells->{fred}, 'range';
  is $cells->{fred}->range(), "$self->{name}A1", "Cell 'fred => A1' is range 'A1'";

  lives_ok sub { $cells = $worksheet->tie_cells({ fred => [1, 1] }); }, "Tying cells 'fred => [1, 1]' should live";
  tied(%$cells)->fetch_range(1);
  isa_ok $cells->{fred}, Cell, "Key 'fred' should be a cell";
  can_ok $cells->{fred}, 'range';
  is $cells->{fred}->range(), "$self->{name}A1", "Cell 'fred => [1, 1]' is 'A1'";

  lives_ok sub { $cells = $worksheet->tie_cells({ fred => [[1,1], [2,2]] }); }, "Tying a cell to a bad range should live";
  tied(%$cells)->fetch_range(1);
  throws_ok sub { $cells->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_cols : Tests(13) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cols;
  lives_ok sub { $cols = $worksheet->tie_cols(1, 2); }, "Tying cols '1' and '2' should live";
  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{1}, Col, "Key '1' should be a col";
  can_ok $cols->{1}, 'range';
  is $cols->{1}->range(), "$self->{name}A:A", "Col '1' is range 'A:A'";
  isa_ok $cols->{2}, Col, "Key '2' should be a col";
  can_ok $cols->{2}, 'range';
  is $cols->{2}->range(), "$self->{name}B:B", "Col '2' is range 'B:B'";

  lives_ok sub { $cols = $worksheet->tie_cols({ fred => '1' }); }, "Tying cols 'fred => 1' should live";
  tied(%$cols)->fetch_range(1);
  isa_ok $cols->{fred}, Col, "Key 'fred' should be a col";
  can_ok $cols->{fred}, 'range';
  is $cols->{fred}->range(), "$self->{name}A:A", "Col 'fred => 1' is range 'A:A'";

  lives_ok sub { $cols = $worksheet->tie_cols({ fred => [[1,1], [2,2]] }); }, "Tying cols to a bad range should live";
  tied(%$cols)->fetch_range(1);
  throws_ok sub { $cols->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

sub tie_rows : Tests(13) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $rows;
  lives_ok sub { $rows = $worksheet->tie_rows(1, 2); }, "Tying rows '1' and '2' should live";
  tied(%$rows)->fetch_range(1);
  isa_ok $rows->{1}, Row, "Key '1' should be a row";
  can_ok $rows->{1}, 'range';
  is $rows->{1}->range(), "$self->{name}1:1", "Key '1' should be range '1:1'";
  isa_ok $rows->{2}, Row, "Key '2' should be a row";
  can_ok $rows->{2}, 'range';
  is $rows->{2}->range(), "$self->{name}2:2", "Key '2' should be range '2:2'";

  lives_ok sub { $rows = $worksheet->tie_rows({ fred => '1' }); }, "Tying rows 'fred => 1' should live";
  tied(%$rows)->fetch_range(1);
  isa_ok $rows->{fred}, Row, "Key 'fred' should be a row";
  can_ok $rows->{fred}, 'range';
  is $rows->{fred}->range(), "$self->{name}1:1", "Row 'fred => 1' is range '1:1'";

  lives_ok sub { $rows = $worksheet->tie_rows({ fred => [[1,1], [2,2]] }); }, "Tying rows to a bad range should live";
  tied(%$rows)->fetch_range(1);
  throws_ok sub { $rows->{fred}->range(); }, qr/Unable to translate/, "Using a bad range should fail";

  return;
}

1;
