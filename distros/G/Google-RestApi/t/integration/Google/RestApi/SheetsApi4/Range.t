use Test::Integration::Setup;

use Test::Most tests => 34;

# init_logger($DEBUG);

use aliased 'Google::RestApi::SheetsApi4::Range';
use aliased 'Google::RestApi::SheetsApi4::Range::Col';
use aliased 'Google::RestApi::SheetsApi4::Range::Row';
use aliased 'Google::RestApi::SheetsApi4::Range::Cell';

my $spreadsheet = spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

clear();
named();
formulas();
requests();

sub clear {
  my $range = $worksheet->range("A1:Z99");
  is_hash sub { $range->clear(); }, "Clearing a range";
  return;
}

sub named {
  my @values = (
    [ 1, 2, 3 ],
    [ 4, 5, 6 ],
  );
  my $range = $worksheet->range("B3:D5");

  is_hash sub { $range->add_named(name => "xxx")->submit_requests() }, "Adding named range";
  throws_ok sub { $range->add_named(name => "xxx")->submit_requests(); },
    qr/a named range with that name already exists/, "Creating same named range should fail";

  isa_ok $range = $worksheet->range("xxx"), Range, "Adding named range";
  is_deeply $range->values(values => \@values), \@values, "Setting named range values should return same values";

  isa_ok $range = $worksheet->range_col("xxx"), Col, "Adding named range as a col";
  throws_ok sub { $range->range(); }, qr/Unable to translate/, "Using a non-col named range should die";

  isa_ok $range = $worksheet->range_row("xxx"), Row, "Adding named range as a row";
  throws_ok sub { $range->range(); }, qr/Unable to translate/, "Using a non-row named range should die";

  isa_ok $range = $worksheet->range_cell("xxx"), Cell, "Adding named range as a cell";
  throws_ok sub { $range->range(); }, qr/Unable to translate/, "Using a non-cell named range should die";

  my $col = "A1:A10";
  $range = $worksheet->range($col);
  is_hash sub { $range->add_named(name => "col_named_range")->submit_requests() }, "Adding col named range";
  isa_ok $range = $worksheet->range_col("col_named_range"), Col, "Creating col named range as a col";
  $spreadsheet->cache_seconds(5);
  like $worksheet->range("col_named_range")->range(), qr/$col$/, "Normalized range should be $col";

  my $row = "A1:J10";
  $range = $worksheet->range($row);
  is_hash sub { $range->add_named(name => "row_named_range")->submit_requests() }, "Adding row named range";
  isa_ok $range = $worksheet->range_row("row_named_range"), Row, "Creating row named range as a row";
  $spreadsheet->cache_seconds(5);
  like $worksheet->range("row_named_range")->range(), qr/$row$/, "Normalized range should be $row";

  my $named = $spreadsheet->range_group(
    map { $worksheet->range($_); } qw(xxx col_named_range row_named_range)
  );
  is_hash $named->delete_named()->submit_requests(), "Delete of named ranges";
  return;
}

sub formulas {
  my $sum = '=SUM(A1:B1)';
  my @values = (
    [ 1, 1, $sum ],
  );
  my $range = $worksheet->range("A1:C1");
  $range->values(values => \@values);

  is $worksheet->range_cell('C1')->values(), 2, "Returned formula value should be 2";
  is $worksheet->range_cell('C1')->values(
    params => {
      valueRenderOption => 'FORMULA',
    }
  ), $sum, "Returned formula value should be '$sum'";

  is_array $range->values(
    values => \@values,
    params => {
      includeValuesInResponse => 'true',
    },
  ), "Returning values in response";
  is $range->values()->[0]->[2], 2, "Returned formula value should be 2";

  is_array $range->values(
    values => \@values,
    params => {
      includeValuesInResponse   => 'true',
      responseValueRenderOption => 'FORMULA',
    },
  ), "Returning values in response";
  is $range->values()->[0]->[2], $sum, "Returned formula value should be '$sum'";

  is_hash $range->batch_values(values => \@values), "Returning batch values";
  is_array $range->submit_values(
    content => { includeValuesInResponse   => 'true' },
  ),"Submitting batch values in response";
  is $range->values()->[0]->[2], 2, "Returned batch formula value should be 2";

  is_hash $range->batch_values(values => \@values), "Returning batch values";
  is_array $range->submit_values(
    content => {
      includeValuesInResponse   => 'true',
      responseValueRenderOption => 'FORMULA',
    },
  ), "Returning batch values in response";
  is $range->values()->[0]->[2], $sum, "Returned batch formula value should be '$sum'";

  return;
}

sub requests {
  my $range = $worksheet->range("A1:B2");
  isa_ok $range->
       bold()->bold(0)->red()->bk_blue(0.5)->merge_both()->
       bd_blue('top')->bd_red(0.3, 'bottom')->bd_green(0, 'left')->
       bd_dashed()->bd_dashed('inner')->bd_repeat_cell()->bd_red('bottom')->bd_dashed(),
     Range, "Range format batch";
  is_hash $range->submit_requests(), "Submitting batch requests";

  is_array my $requests_response = $range->requests_response_from_api(), "Obtaining the request response";
  is scalar @$requests_response, 3, "There should be three responses in the response array";
}

delete_all_spreadsheets($spreadsheet->sheets_api());
