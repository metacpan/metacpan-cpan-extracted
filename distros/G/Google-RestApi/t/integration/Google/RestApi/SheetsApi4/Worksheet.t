use Test::Integration::Setup;

use Test::Most tests => 39;

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Worksheet';

# init_logger($DEBUG);

my $name = "Sheet1";
my $sheets_api = sheets_api();
my $spreadsheet = $sheets_api->create_spreadsheet(title => spreadsheet_name());
my $worksheet;
my $qr_id = SheetsApi4->Worksheet_Id;
my $qr_uri = SheetsApi4->Worksheet_Uri;

open_worksheet(); # this must be run to populate the worksheet var.
identifiers();
cell_col_row();
cols_rows();
nvp_header();

sub open_worksheet {
  isa_ok $worksheet = $spreadsheet->open_worksheet(id => 0), Worksheet, "Opening a worksheet";
  is scalar $spreadsheet->open_worksheet(id => 0), "$worksheet", "Second open should return the same worksheet";
}

sub identifiers {
  my ($id, $uri);
  like $id = $worksheet->worksheet_id(), qr/$qr_id/, "Should find worksheet ID";
  like $uri = $worksheet->worksheet_uri(), qr/$qr_uri/, "Should find worksheet URI";
  like $name = $worksheet->worksheet_name(), qr/^$name$/, "Should find worksheet name";

  delete @$worksheet{qw(id uri)};
  $worksheet->{name} = $name;
  like $worksheet->worksheet_id(), qr/$qr_id/, "Should find worksheet ID when URI is missing";

  delete @$worksheet{qw(id name)};
  $worksheet->{uri} = $uri;
  like $worksheet->worksheet_id(), qr/$qr_id/, "Should find worksheet ID when name is missing";

  delete @$worksheet{qw(uri name)};
  $worksheet->{id} = $id;
  like $worksheet->worksheet_uri(), qr/$qr_uri/, "Should find worksheet URI when name is missing";

  delete @$worksheet{qw(uri id)};
  $worksheet->{name} = $name;
  like $worksheet->worksheet_uri(), qr/$qr_uri/, "Should find worksheet URI when ID is missing";

  delete @$worksheet{qw(name uri)};
  $worksheet->{id} = $id;
  like $worksheet->worksheet_name(), qr/^$name$/, "Should find worksheet name when URI is missing";

  delete @$worksheet{qw(name id)};
  $worksheet->{uri} = $uri;
  like $worksheet->worksheet_name(), qr/^$name$/, "Should find worksheet name when ID is missing";
}

sub cell_col_row {
  my $value = 'Fred';
  is $worksheet->cell("A1", $value), $value, "Updating 'A1' to '$value' should return '$value'";
  is $worksheet->cell("A1"), $value, "Retreiving 'A1' should return '$value'";

  is $worksheet->cell(1, 1, $value), $value, "Updating '1,1' to '$value' should return '$value'";
  is $worksheet->cell(1, 1), $value, "Retreiving '1,1' should return '$value'";

  my @values = ( 1, 2, 3 );
  is_deeply $worksheet->col(1, \@values), \@values, "Updating column should return same values";
  is_deeply $worksheet->col(1), \@values, "Retreiving column should return correct values";

  is_deeply $worksheet->row(1, \@values), \@values, "Updating row should return same values";
  is_deeply $worksheet->row(1), \@values, "Retreiving row should return correct values";

  return;
}

sub cols_rows {
  my @values = (
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  );

  is_deeply $worksheet->cols([1, 2, 3], \@values), \@values, "Updating columns should return same values";
  is_deeply $worksheet->cols([1, 2, 3]), \@values, "Retreiving columns should return correct values";
  is $worksheet->cell("A3"), 3, "Cell 'A3' should be '3'";
  is $worksheet->cell("C1"), 7, "Cell 'C1' should be '7'";

  is_deeply $worksheet->rows([1, 2, 3], \@values), \@values, "Updating rows should return same values";
  is_deeply $worksheet->rows([1, 2, 3]), \@values, "Retreiving rows should return correct values";
  is $worksheet->cell("A3"), 7, "Cell 'A3' should be '7'";
  is $worksheet->cell("C1"), 3, "Cell 'C1' should be '3'";

  return;
}

sub nvp_header {
  my %nvp = (
    fred    => 1,
    pete    => 2,
    charlie => 3,
  );

  my $ss_values;
  # returns:
  # - - fred
  #   - pete
  #   - charlie
  # - - 1
  #   - 2
  #   - 3
  is_deeply $worksheet->cols([1, 2], [[keys %nvp], [values %nvp]]), [[keys %nvp], [values %nvp]], "Setting name-value pairs should be valid";
  is_deeply $worksheet->name_value_pairs(), \%nvp, "Name-value pairs should be valid";

  is_deeply $worksheet->cols([1, 2], [[values %nvp], [keys %nvp]]), [[values %nvp], [keys %nvp]], "Setting reverse name-value pairs";
  is_deeply $worksheet->name_value_pairs(2, 1), \%nvp, "Name-value pairs should be valid";

  $worksheet->cols([1, 2], [[keys %nvp], [values %nvp]]);
  is_hash $worksheet->range_row(1)->insert_d()->submit_requests(), "Inserting name-value pairs header row";
  is_array $worksheet->row(1, [qw(name value)]), "Setting name-value pairs header row";

  is_hash $ss_values = $worksheet->name_value_pairs(), "Retreiving name-value pairs without header";
  $nvp{name} = 'value';
  is_deeply $ss_values, \%nvp, "Name-value pairs without header should be valid";
  delete $nvp{name};

  is_hash $ss_values = $worksheet->name_value_pairs(1, 2, 1), "Retreiving name-value pairs with header";
  is_deeply $ss_values, \%nvp, "Name-value pairs with header should be valid";

  is_array $ss_values = $worksheet->header_row(), "Retreiving header row";
  is_deeply $ss_values, [qw(name value)], "Header row should be valid";

  return;
}

delete_all_spreadsheets(sheets_api);
