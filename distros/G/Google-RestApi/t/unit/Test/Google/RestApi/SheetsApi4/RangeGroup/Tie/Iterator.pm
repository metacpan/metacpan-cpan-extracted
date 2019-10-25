package Test::Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator;

use Test::Most;
use YAML::Any qw(Dump);

use parent 'Test::Google::RestApi::SheetsApi4::Base';

sub class { 'Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator' }

sub tie_range : Tests(14) {
  my $self = shift;

  my $worksheet = $self->worksheet();
  my ($row, $iterator);
  my $cols = $worksheet->tie_cols();
  lives_ok sub { $iterator = tied(%$cols)->iterator(from => 1); }, "Tie iterator creation should live";

  is $worksheet->cell("B2"), undef, "Cell 'B2' is 'undef'";
  is $worksheet->cell("C2"), undef, "Cell 'C2' is 'undef'";
  is $worksheet->cell("D2"), undef, "Cell 'D2' is 'undef'";

  lives_ok sub { $row = $iterator->iterate(); }, "First tied iteration should live";
  $row->{id} = 1000;
  $row->{name} = "Joe Blogs";
  $row->{address} = "123 Some Street";
  lives_ok sub { tied(%$row)->submit_values(); }, "Updating a row should live";

  is $worksheet->cell("B2"), 1000, "Cell 'B2' is '1000'";
  is $worksheet->cell("C2"), "Joe Blogs", "Cell 'C2' is 'Joe Blogs'";
  is $worksheet->cell("D2"), "123 Some Street", "Cell 'D2' is '123 Some Street'";

  lives_ok sub { $row = $iterator->iterate(); }, "Second tied iteration should live";
  $row->{id} = 1001;
  $row->{name} = "Freddie Mercury";
  $row->{address} = "321 Some Other Street";
  lives_ok sub { tied(%$row)->submit_values(); }, "Updating a row should live";

  is $worksheet->cell("B3"), 1001, "Cell 'B3' is '1001'";
  is $worksheet->cell("C3"), "Freddie Mercury", "Cell 'C3' is 'Freddie Mercury'";
  is $worksheet->cell("D3"), "321 Some Other Street", "Cell 'D3' is '321 Some Other Street'";

  return;
}

1;
