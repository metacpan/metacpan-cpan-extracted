#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;

# init_logger($DEBUG);

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will delete all the worksheets we created.");
my $count = $sheets_api->delete_all_spreadsheets([$name, "${name}_copy"]);
end_go("Delete complete, deleted $count spreadsheets.");

message('blue', "We are done, here are some api stats:\n", Dump($sheets_api->stats()));
