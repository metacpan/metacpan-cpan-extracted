#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../../t/lib";
use lib "$FindBin::RealBin/../../lib";

use Tutorial::Setup;

init_logger($TRACE) if $ENV{DEBUG};

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will delete all the spreadsheets we created by listing all spreadsheets deleting any named $name.");
my $count = $sheets_api->delete_all_spreadsheets_by_filters(["name = '$name'", "name = '${name}_copy'"]);
end_go("Delete complete, deleted $count spreadsheets.");

message('blue', "We are done, here are some api stats:\n", Dump($sheets_api->stats()));
