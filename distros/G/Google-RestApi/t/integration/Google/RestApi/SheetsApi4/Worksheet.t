use Test::Integration::Setup;

use Test::Most tests => 37;

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Worksheet';

# use Carp::Always;
# init_logger($DEBUG);

delete_all_spreadsheets(sheets_api());

my $spreadsheet = sheets_api()->create_spreadsheet(title => spreadsheet_name());

my $ws0;
my $name = "Sheet1";
my $qr_id = SheetsApi4->Worksheet_Id;
my $qr_uri = SheetsApi4->Worksheet_Uri;

open_worksheet(); # this must be run to populate the worksheet var.
identifiers();
cell_col_row();
cols_rows();
nvp_header();

sub open_worksheet {
  isa_ok $ws0 = $spreadsheet->open_worksheet(id => 0), Worksheet, "Opening a worksheet";
  is scalar $spreadsheet->open_worksheet(id => 0), "$ws0", "Second open should return the same worksheet";
  return;
}

sub identifiers {
  my ($id, $uri);
  like $id = $ws0->worksheet_id(), qr/$qr_id/, "Should find worksheet ID";
  like $uri = $ws0->worksheet_uri(), qr/$qr_uri/, "Should find worksheet URI";
  like $name = $ws0->worksheet_name(), qr/^$name$/, "Should find worksheet name";

  delete @$ws0{qw(id uri)};
  $ws0->{name} = $name;
  like $ws0->worksheet_id(), qr/$qr_id/, "Should find worksheet ID when URI is missing";

  delete @$ws0{qw(id name)};
  $ws0->{uri} = $uri;
  like $ws0->worksheet_id(), qr/$qr_id/, "Should find worksheet ID when name is missing";

  delete @$ws0{qw(uri name)};
  $ws0->{id} = $id;
  like $ws0->worksheet_uri(), qr/$qr_uri/, "Should find worksheet URI when name is missing";

  delete @$ws0{qw(uri id)};
  $ws0->{name} = $name;
  like $ws0->worksheet_uri(), qr/$qr_uri/, "Should find worksheet URI when ID is missing";

  delete @$ws0{qw(name uri)};
  $ws0->{id} = $id;
  like $ws0->worksheet_name(), qr/^$name$/, "Should find worksheet name when URI is missing";

  delete @$ws0{qw(name id)};
  $ws0->{uri} = $uri;
  like $ws0->worksheet_name(), qr/^$name$/, "Should find worksheet name when ID is missing";

  return;
}

sub cell_col_row {
  my $value = 'Fred';

  is $ws0->cell("A1", $value), $value, "Updating 'A1' to '$value' should return '$value'";
  is $ws0->cell("A1"), $value, "Retreiving 'A1' should return '$value'";

  is $ws0->cell([1, 1], $value), $value, "Updating '1,1' to '$value' should return '$value'";
  is $ws0->cell([1, 1]), $value, "Retreiving '1,1' should return '$value'";

  my @values = ( 1, 2, 3 );
  is_deeply $ws0->col(1, \@values), \@values, "Updating column should return same values";
  is_deeply $ws0->col(1), \@values, "Retreiving column should return correct values";

  is_deeply $ws0->row(1, \@values), \@values, "Updating row should return same values";
  is_deeply $ws0->row(1), \@values, "Retreiving row should return correct values";

  return;
}

sub cols_rows {
  my @values = (
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  );

  is_deeply $ws0->cols([1, 2, 3], \@values), \@values, "Updating columns should return same values";
  is_deeply $ws0->cols([1, 2, 3]), \@values, "Retreiving columns should return correct values";
  is $ws0->cell("A3"), 3, "Cell 'A3' should be '3'";
  is $ws0->cell("C1"), 7, "Cell 'C1' should be '7'";

  is_deeply $ws0->rows([1, 2, 3], \@values), \@values, "Updating rows should return same values";
  is_deeply $ws0->rows([1, 2, 3]), \@values, "Retreiving rows should return correct values";
  is $ws0->cell("A3"), 7, "Cell 'A3' should be '7'";
  is $ws0->cell("C1"), 3, "Cell 'C1' should be '3'";

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
  is_deeply $ws0->cols([1, 2], [[keys %nvp], [values %nvp]]), [[keys %nvp], [values %nvp]], "Setting name-value pairs should be valid";
  is_deeply $ws0->name_value_pairs(), \%nvp, "Name-value pairs should be valid";

  is_deeply $ws0->cols([1, 2], [[values %nvp], [keys %nvp]]), [[values %nvp], [keys %nvp]], "Setting reverse name-value pairs";
  is_deeply $ws0->name_value_pairs(2, 1), \%nvp, "Reverse name-value pairs should be valid";

  $ws0->cols([1, 2], [[keys %nvp], [values %nvp]]);
  is_hash $ws0->range_row(1)->insert_d()->submit_requests(), "Inserting name-value pairs header row";
  is_deeply $ws0->row(1, [qw(name value)]), [qw(name value)], "Setting name-value pairs header row";

  is_hash $ss_values = $ws0->name_value_pairs(), "Retreiving name-value pairs without header";
  $nvp{name} = 'value';
  is_deeply $ss_values, \%nvp, "Name-value pairs without header should be valid";
  delete $nvp{name};

  $ws0->enable_header_row(1);
  is_hash $ss_values = $ws0->name_value_pairs(), "Retreiving name-value pairs with header";
  is_deeply $ss_values, \%nvp, "Name-value pairs with header should be valid";

  return;
}

delete_all_spreadsheets(sheets_api());
