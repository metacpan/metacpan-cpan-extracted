#!/usr/bin/env perl

# NOTE: this script needs access to t/lib to find some support modules.
# if you copy any of the scripts in this dir, you must update the 'use lib'
# statements below to resolve what they need in order to run.

use FindBin;
# this needs to point to t/lib in this package. if you copy this script outside
# this pacakage path, you have to update this to properly find t/lib.
use lib "$FindBin::RealBin/../../lib";
# this points to the local copy of Google::RestApi. if you don't need to test a
# local copy of the pacakge, and you have G::R already installed, then you may
# comment this out and G::R will be resolved with the standard installed
# module path in INC.
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;   # in t/lib

# see Test::Utils::init_logger.
# init_logger($TRACE);

my $name = spreadsheet_name();
my $sheets_api = sheets_api();
# clean up any failed previous runs.
$sheets_api->delete_all_spreadsheets($name);
# now set a callback to display the api request/response.
$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will create a new spreadsheet named '$name'.");
my $ss = $sheets_api->create_spreadsheet(title => $name);
my $uri = $ss->spreadsheet_uri();
end("Spreadsheet successfully created, uri: $uri.");

start("Now we will make a copy of the spreadsheet named '${name}_copy'.");
my $ss_copy = $ss->copy_spreadsheet(title => "${name}_copy");
my $uri_copy = $ss_copy->spreadsheet_uri();
end("Spreadsheet successfully copied, uri: '$uri_copy'.");

start("Now we will delete the copy of the spreadsheet.");
$ss_copy->delete_spreadsheet();
end("Spreadsheet successfully deleted.");

message('green', "\nEnter url '$uri' in your browser and proceed to 20_worksheet.pl.\n");

message('blue', "We are done, here are some api stats:\n", Dump($ss->stats()));
