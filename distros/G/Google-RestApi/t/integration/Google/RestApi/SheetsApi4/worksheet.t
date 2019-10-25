#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use lib "$FindBin::RealBin/../../../../../lib";

use YAML::Any qw(Dump);
use Test::Most tests => 47;

use aliased "Google::RestApi::SheetsApi4";

use Utils;
Utils::init_logger();

my $name = "Sheet1";
my $spreadsheet_name = $Utils::spreadsheet_name;
my $sheets = Utils::sheets_api();
my $spreadsheet = $sheets->create_spreadsheet(title => $spreadsheet_name);
my $worksheet;
my $qr_id = SheetsApi4->Worksheet_Id;
my $qr_uri = SheetsApi4->Worksheet_Uri;

lives_ok sub { $worksheet = $spreadsheet->open_worksheet(id => 0); }, "Opening first worksheet should succeed";
is scalar $spreadsheet->open_worksheet(id => 0), "$worksheet", "Second open should return the same worksheet";

identifiers();
cell_col_row();
cols_rows();
nvp_header();

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
  my $ret_values;
  my $value = 'Fred';
  lives_ok sub { $worksheet->cell("A1", $value); }, "Updating 'A1' to '$value' should live";
  lives_ok sub { $ret_values = $worksheet->cell("A1"); }, "Retreiving 'A1' should live";
  is $ret_values, $value, "Cell value should be valid";

  lives_ok sub { $worksheet->cell(1, 1, $value); }, "Updating '1,1' to '$value' should live";
  lives_ok sub { $ret_values = $worksheet->cell(1, 1); }, "Retreiving '1,1' should live";
  is $ret_values, $value, "Cell value should be valid";


  my @values = ( 1, 2, 3 );
  lives_ok sub { $worksheet->col(1, \@values); }, "Updating column should live";
  lives_ok sub { $ret_values = $worksheet->col(1); }, "Retreiving column should live";
  is_deeply $ret_values, \@values, "Column values should be valid";

  lives_ok sub { $worksheet->row(1, \@values); }, "Updating row should live";
  lives_ok sub { $ret_values = $worksheet->row(1); }, "Retreiving row should live";
  is_deeply $ret_values, \@values, "Row values should be valid";

  return;
}

sub cols_rows {
  my @values = (
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  );
  my $ret_values;
  lives_ok sub { $worksheet->cols([1, 2, 3], \@values); }, "Updating columns should live";
  lives_ok sub { $ret_values = $worksheet->cols([1, 2, 3]); }, "Retreiving columns should live";
  is_deeply $ret_values, \@values, "Columns values should be valid";
  is $worksheet->cell("A3"), 3, "Cell 'A3' should be '3'";
  is $worksheet->cell("C1"), 7, "Cell 'C1' should be '7'";

  lives_ok sub { $worksheet->rows([1, 2, 3], \@values); }, "Updating rows should live";
  lives_ok sub { $ret_values = $worksheet->rows([1, 2, 3]); }, "Retreiving rows should live";
  is_deeply $ret_values, \@values, "Rows values should be valid";
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
  my $ret_values;
  lives_ok sub { $worksheet->cols([1, 2], [[keys %nvp], [values %nvp]]); }, "Setting name-value pairs should live";
  lives_ok sub { $ret_values = $worksheet->name_value_pairs(); }, "Retreiving name-value pairs should live";
  is_deeply $ret_values, \%nvp, "Name-value pairs should be valid";

  lives_ok sub { $worksheet->cols([1, 2], [[values %nvp], [keys %nvp]]); }, "Setting reverse name-value pairs should live";
  lives_ok sub { $ret_values = $worksheet->name_value_pairs(2, 1); }, "Retreiving reverse name-value pairs should live";
  is_deeply $ret_values, \%nvp, "Name-value pairs should be valid";

  $worksheet->cols([1, 2], [[keys %nvp], [values %nvp]]);
  lives_ok sub { $worksheet->range_row(1)->insert_d()->submit_requests(); }, "Inserting name-value pairs header row should live";
  lives_ok sub { $worksheet->row(1, [qw(name value)]); }, "Setting name-value pairs header row should live";
  lives_ok sub { $ret_values = $worksheet->name_value_pairs(); }, "Retreiving name-value pairs without header should live";
  $nvp{name} = 'value';
  is_deeply $ret_values, \%nvp, "Name-value pairs without header should be valid";
  delete $nvp{name};
  lives_ok sub { $ret_values = $worksheet->name_value_pairs(1, 2, 1); }, "Retreiving name-value pairs with header should live";
  is_deeply $ret_values, \%nvp, "Name-value pairs with header should be valid";

  lives_ok sub { $ret_values = $worksheet->header_row(); }, "Retreiving header row should succeed";
  is_deeply $ret_values, [qw(name value)], "Header row should be valid";

  return;
}

$spreadsheet->sheets()->delete_all_spreadsheets($spreadsheet_name);
