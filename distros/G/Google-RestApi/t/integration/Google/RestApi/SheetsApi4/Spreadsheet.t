use Test::Integration::Setup;

use Test::Most tests => 15;

use aliased "Google::RestApi::SheetsApi4";

# init_logger($DEBUG);

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
my $spreadsheet = $sheets_api->create_spreadsheet(title => $name);

my ($id, $uri);
my $qr_id = SheetsApi4->Spreadsheet_Id;
my $qr_uri = SheetsApi4->Spreadsheet_Uri;

like $id = $spreadsheet->spreadsheet_id(), qr/^$qr_id$/, "Should find spreadsheet ID";
like $uri = $spreadsheet->spreadsheet_uri(), qr/^$qr_uri/, "Should find spreadsheet URI";
like $name = $spreadsheet->spreadsheet_name(), qr/^$name$/, "Should find spreadsheet name";

delete @$spreadsheet{qw(id uri)};
$spreadsheet->{name} = $name;
like $spreadsheet->spreadsheet_id(), qr/^$qr_id$/, "Should find spreadsheet ID when URI is missing";

delete @$spreadsheet{qw(id name)};
$spreadsheet->{uri} = $uri;
like $spreadsheet->spreadsheet_id(), qr/^$qr_id$/, "Should find spreadsheet ID when name is missing";

delete @$spreadsheet{qw(uri name)};
$spreadsheet->{id} = $id;
like $spreadsheet->spreadsheet_uri(), qr/^$qr_uri/, "Should find spreadsheet URI when name is missing";

delete @$spreadsheet{qw(uri id)};
$spreadsheet->{name} = $name;
like $spreadsheet->spreadsheet_uri(), qr/^$qr_uri/, "Should find spreadsheet URI when ID is missing";

delete @$spreadsheet{qw(name uri)};
$spreadsheet->{id} = $id;
like $spreadsheet->spreadsheet_name(), qr/^$name$/, "Should find spreadsheet name when URI is missing";

delete @$spreadsheet{qw(name id)};
$spreadsheet->{uri} = $uri;
like $spreadsheet->spreadsheet_name(), qr/^$name$/, "Should find spreadsheet name when ID is missing";

my $properties;
is_hash $properties = $spreadsheet->properties('title'), "Retreiving properties";
is $properties->{title}, $name, "Title property should be the correct name";

my $worksheets;
is_array $worksheets = $spreadsheet->worksheet_properties('title'), "Retreiving worksheets";
is_hash $worksheets->[0], "First worksheet";
is $worksheets->[0]->{title}, 'Sheet1', "First worksheet title should be 'Sheet1'";

is $spreadsheet->delete_spreadsheet(), 1, "Deleting spreadsheet should return 1";

$sheets_api->delete_all_spreadsheets($name);
