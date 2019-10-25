package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie;

use Test::Most;
use YAML::Any qw(Dump);

use parent 'Test::Google::RestApi::SheetsApi4::Base';

sub class { 'Google::RestApi::SheetsApi4::RangeGroup::Tie' }

sub tie : Tests(9) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $row;
  lives_ok sub { $row = $worksheet->tie_cells({id => 'B2'}, {name => 'C2'}, {address => 'D2'}); }, "Tie should live";
  lives_ok sub { tied(%$row)->values(); }, "Tied row batch values should live";

  $row->{id} = 1000;
  $row->{name} = "Joe Blogs";
  $row->{address} = "123 Some Street";

  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C2"), undef, "Cell 'C2' is 'undef'";
  is $worksheet->cell("D2"), undef, "Cell 'D2' is 'undef'";

  lives_ok sub { tied(%$row)->submit_values(); }, "Updating a row should live";

  is $worksheet->cell("B2"), 1000, "Cell 'B2' is '1000'";
  is $worksheet->cell("C2"), "Joe Blogs", "Cell 'C2' is 'Joe Blogs'";
  is $worksheet->cell("D2"), "123 Some Street", "Cell 'D2' is '123 Some Street'";

  return;
}

sub tie_cols : Tests(11) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cols;
  lives_ok sub { $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'}); }, "Tie cols should live";

  $cols->{id} = [ 1000, 1001, 1002 ];
  $cols->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $cols->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  lives_ok sub { tied(%$cols)->submit_values(); }, "Updating a row should live";

  is $worksheet->cell("B1"), 1000, "Cell 'B2' is '1000'";
  is $worksheet->cell("C1"), "Joe Blogs", "Cell 'C2' is 'Joe Blogs'";
  is $worksheet->cell("D1"), "123 Some Street", "Cell 'D2' is '123 Some Street'";

  is $worksheet->cell("B2"), 1001, "Cell 'B3' is '1001'";
  is $worksheet->cell("C2"), "Freddie Mercury", "Cell 'C3' is 'Freddie Mercury'";
  is $worksheet->cell("D2"), "345 Some Other Street", "Cell 'D3' is '345 Some Other Street'";

  is $worksheet->cell("B3"), 1002, "Cell 'B4' is '1002'";
  is $worksheet->cell("C3"), "Iggy Pop", "Cell 'C4' is 'Iggy Pop'";
  is $worksheet->cell("D3"), "Another Universe", "Cell 'D4' is 'Another Universe'";

  return;
}

sub tie_cell : Tests(10) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cells;
  lives_ok sub { $cells = $worksheet->tie(); }, "Tie should live";
  my $ranges = $worksheet->tie_cells('A1', { fred => [2, 2] });
  lives_ok sub { tied(%$cells)->add_tied($ranges); }, "Tied cells should live";
  lives_ok sub { tied(%$cells)->values(); }, "Tied cell batch values should live";

  lives_ok sub { $cells->{A1} = 1000; }, "Setting A1 directly should live";
  lives_ok sub { $cells->{fred} = "Joe Blogs"; }, "Setting 'B2' as 'fred' should live";
  lives_ok sub { $cells->{C3} = "123 Some Street"; }, "Setting a new cell 'C3' should live";

  lives_ok sub { tied(%$cells)->submit_values(); }, "Updating cells should live";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_slice : Tests(9) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cells;
  lives_ok sub { $cells = $worksheet->tie(); }, "Tie should live";
  lives_ok sub { @$cells{ 'A1', 'B2', 'C3', 'D4:E5' } = (1000, "Joe Blogs", "123 Some Street", [["Halifax"]]) }, "Hash slice should live";

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C3"), undef, "Cell 'C3' is 'undef'";

  lives_ok sub { tied(%$cells)->submit_values(); }, "Updating cells should live";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_return_objects : Tests(6) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'});
  lives_ok sub { tied(%$cols)->fetch_range(1); }, "Turning on cols return objects should succeed";
  lives_ok sub { $cols->{id}->red(); }, "Setting id to red should succeed";
  lives_ok sub { $cols->{name}->center(); }, "Setting name centered should succeed";
  lives_ok sub { $cols->{address}->font_size(12); }, "Setting address font size should succeed";
  lives_ok sub { tied(%$cols)->fetch_range(); }, "Turning off return objects should succeed";
  lives_ok sub { tied(%$cols)->submit_requests(); }, "Submitting formats should succeed";

  return;
}

1;
