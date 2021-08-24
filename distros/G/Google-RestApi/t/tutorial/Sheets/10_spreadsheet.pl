#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;

# init_logger($DEBUG);

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
# clean up any failed previous runs.
$sheets_api->delete_all_spreadsheets($name);
$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will create a new spreadsheet named '$name'.");
my $ss = $sheets_api->create_spreadsheet(title => $name);
my $uri = $ss->spreadsheet_uri();
end("Spreadsheet successfully created, uri: $uri.");

start("Now we will make a copy of the spreadsheet named '${name}_copy'.");
my $ss_copy = $ss->copy_spreadsheet(title => "${name}_copy");
$uri = $ss_copy->spreadsheet_uri();
end("Spreadsheet successfully copied, uri: '$uri'.");

start("Now we will delete the copy of the spreadsheet.");
$ss_copy->delete_spreadsheet();
end("Spreadsheet successfully deleted.");

# clean up any failed previous runs.
$sheets_api->delete_all_spreadsheets("${name}_copy");

$uri = $ss->spreadsheet_uri();
message('green', "\nOpen url '$uri' and proceed to the next step.\n");

message('blue', "We are done, here are some api stats:\n", Dump($ss->stats()));
