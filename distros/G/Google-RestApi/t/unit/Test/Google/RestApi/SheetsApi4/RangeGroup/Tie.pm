package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie;

use Test::Most;
use YAML::Any qw(Dump);

use parent 'Test::Google::RestApi::SheetsApi4::Base';

use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::RangeGroup::Tie';

use Utils qw(:all);

sub class { 'Google::RestApi::SheetsApi4::RangeGroup::Tie' }

sub tie : Tests(9) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $row;
  is_hash $row = $worksheet->tie_cells({id => 'B2'}, {name => 'C2'}, {address => 'D2'}), "Create tie";
  is_array tied(%$row)->values(), "Tied row batch values";

  $row->{id} = 1000;
  $row->{name} = "Joe Blogs";
  $row->{address} = "123 Some Street";

  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C2"), undef, "Cell 'C2' is 'undef'";
  is $worksheet->cell("D2"), undef, "Cell 'D2' is 'undef'";

  is_array tied(%$row)->submit_values(), "Updating a row";

  is $worksheet->cell("B2"), 1000, "Cell 'B2' is '1000'";
  is $worksheet->cell("C2"), "Joe Blogs", "Cell 'C2' is 'Joe Blogs'";
  is $worksheet->cell("D2"), "123 Some Street", "Cell 'D2' is '123 Some Street'";

  return;
}

sub tie_cols : Tests(11) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cols;
  is_hash $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'}), "Tie cols";

  $cols->{id} = [ 1000, 1001, 1002 ];
  $cols->{name} = [ "Joe Blogs", "Freddie Mercury", "Iggy Pop" ];
  $cols->{address} = [ "123 Some Street", "345 Some Other Street", "Another Universe" ];

  is_array tied(%$cols)->submit_values(), "Updating a row";

  is $worksheet->cell("B1"), 1000, "Cell 'B1' is '1000'";
  is $worksheet->cell("C1"), "Joe Blogs", "Cell 'C1' is 'Joe Blogs'";
  is $worksheet->cell("D1"), "123 Some Street", "Cell 'D1' is '123 Some Street'";

  is $worksheet->cell("B2"), 1001, "Cell 'B2' is '1001'";
  is $worksheet->cell("C2"), "Freddie Mercury", "Cell 'C2' is 'Freddie Mercury'";
  is $worksheet->cell("D2"), "345 Some Other Street", "Cell 'D2' is '345 Some Other Street'";

  is $worksheet->cell("B3"), 1002, "Cell 'B3' is '1002'";
  is $worksheet->cell("C3"), "Iggy Pop", "Cell 'C3' is 'Iggy Pop'";
  is $worksheet->cell("D3"), "Another Universe", "Cell 'D3' is 'Another Universe'";

  return;
}

sub tie_cell : Tests(7) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cells;
  is_hash $cells = $worksheet->tie(), "Create blank tie";
  my $ranges = $worksheet->tie_cells('A1', { fred => [2, 2] });
  is_hash tied(%$cells)->add_tied($ranges), Tie, "Adding tied cells";
  is_array tied(%$cells)->values(), "Tied cell batch values";

  $cells->{A1} = 1000;
  $cells->{fred} = "Joe Blogs";
  $cells->{C3} = "123 Some Street";

  is_array tied(%$cells)->submit_values(), "Updating cells";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_slice : Tests(8) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cells;
  is_hash $cells = $worksheet->tie(), "Create blank tie";
  @$cells{ 'A1', 'B2', 'C3', 'D4:E5' } = (1000, "Joe Blogs", "123 Some Street", [["Halifax"]]);

  is $worksheet->cell("A1"), undef, "Cell 'A1' is 'undef'";
  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C3"), undef, "Cell 'C3' is 'undef'";

  is_array tied(%$cells)->submit_values(), "Updating cells";

  is $worksheet->cell("A1"), 1000, "Cell 'A1' is '1000'";
  is $worksheet->cell("B2"), "Joe Blogs", "Cell 'B2' is 'Joe Blogs'";
  is $worksheet->cell("C3"), "123 Some Street", "Cell 'C3' is '123 Some Street'";

  return;
}

sub tie_return_objects : Tests(6) {
  my $self = shift;

  my $worksheet = $self->worksheet();

  my $cols = $worksheet->tie_cols({id => 'B:B'}, {name => 'C:C'}, {address => 'D:D'});
  isa_ok tied(%$cols)->fetch_range(1), Tie, "Turning on cols return objects";
  isa_ok $cols->{id}->red(), Col, "Setting id to red";
  isa_ok $cols->{name}->center(), Col, "Setting name centered";
  isa_ok $cols->{address}->font_size(12), Col, "Setting address font size";
  isa_ok tied(%$cols)->fetch_range(), Tie, "Turning off return objects";
  is_hash tied(%$cols)->submit_requests(), "Submitting requests";

  return;
}

1;
