use Test::Integration::Setup;

use Test::Most tests => 3;

use aliased 'Google::RestApi::SheetsApi4';
use aliased 'Google::RestApi::SheetsApi4::Spreadsheet';

# use Carp::Always;
init_logger;

my ($sheets_api, $spreadsheet, @spreadsheets);
isa_ok $sheets_api = SheetsApi4->new(api => rest_api()), SheetsApi4, "New sheets API object";
isa_ok $spreadsheet = $sheets_api->create_spreadsheet(title => spreadsheet_name()), Spreadsheet, "New spreadsheet object";
is $sheets_api->delete_spreadsheet($spreadsheet->spreadsheet_id()), 1, "Deleting spreadsheet";
