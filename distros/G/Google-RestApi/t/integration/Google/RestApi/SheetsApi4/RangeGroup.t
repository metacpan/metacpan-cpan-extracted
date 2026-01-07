use Test::Integration::Setup;

use Test::Most tests => 8;

use aliased "Google::RestApi::SheetsApi4::RangeGroup";

# use Carp::Always;
init_logger;

delete_all_spreadsheets(sheets_api());

my $spreadsheet = spreadsheet();
my $ws0 = $spreadsheet->open_worksheet(id => 0);

my @values_in = (
  [1,  2, 3],  # column b
  [4,  5, 6],  # row 2
      99,      # the middle bit
);
my @values_out = (
  [1, 99, 3],
  [4, 99, 6],
      99,
);

my $col = $ws0->range_col("B");
my $row = $ws0->range_row(2);
my $cell = $ws0->range_cell([2,2]);
my $range_group = $spreadsheet->range_group($col, $row, $cell);

isa_ok $range_group->batch_values(values => \@values_in), RangeGroup, "Setting up mixed batch values";
is_array my $values = $range_group->submit_values(), "Submitting mixed values";
# at this point, each transaction for each range ran independently, so values will look like original values.
is_deeply $values, \@values_in, "Range group submit values should be correct";

is_array $values = $range_group->refresh_values(), "Refresh values";
# because the ranges in the group overlap, a refresh will now show the overlapped values.
is_deeply $values, \@values_out, "Range group refresh values should be correct";
is_deeply $range_group->values(), \@values_out, "Range group values should be correct";

is_hash $range_group->clear(), "Range group clear";
is_deeply $range_group->values(), [undef, undef, undef], "Range group values after clear should be empty";

delete_all_spreadsheets(sheets_api());
