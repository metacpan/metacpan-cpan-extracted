use Test::Integration::Setup;

use Test::Most tests => 8;

use aliased "Google::RestApi::SheetsApi4::RangeGroup::Tie";

# use Carp::Always;
# init_logger($DEBUG);

delete_all_spreadsheets(sheets_api());

my $text1 = "This is text for A1";
my $text2 = "This is text for A2";

my $spreadsheet = spreadsheet();
my $ws0 = $spreadsheet->open_worksheet(id => 0);

is_hash my $tied = $ws0->tie(), "Simple tie";
is $tied->{A1} = $text1, $text1, "Setting tied A1 text should succeed";
is $tied->{A2} = $text2, $text2, "Setting tied A2 text should succeed";
is_array sub { tied(%$tied)->submit_values(); }, "Updating tied values";
#tied(%$tied)->fetch_range();
#warn Dump($tied);
#tied(%$tied)->fetch_range(0);

is_hash $tied = $ws0->tie_cells({ A1 => 'A1', A2 => 'A2' }), "Tie with simple cells";
is_array sub { tied(%$tied)->values(); }, "Fetching tied values";
is $tied->{A1}, $text1, "Checking tied A1 text should succeed";
is $tied->{A2}, $text2, "Checking tied A2 text should succeed";
#tied(%$tied)->fetch_range();
#warn Dump($tied);
#tied(%$tied)->fetch_range(0);

delete_all_spreadsheets(sheets_api());
