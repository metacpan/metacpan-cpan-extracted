#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../integration";

use YAML::Any qw(Dump);
use Utils qw(init_logger message start end end_go show_api);

init_logger();

my $name = $Utils::spreadsheet_name;
my $sheets = Utils::sheets_api();
# clean up any failed previous runs.
$sheets->delete_all_spreadsheets($name);
$sheets->rest_api()->post_process(\&show_api);

start("Now we will create a new spreadsheet named '$name'.");
my $ss = $sheets->create_spreadsheet(title => $name);
end("Spreadsheet successfully created.");

start("Now we will make a copy of the spreadsheet named '${name}_copy'.");
my $ss_copy = $ss->copy_spreadsheet(title => "${name}_copy");
my $uri = $ss_copy->spreadsheet_uri();
end("Spreadsheet successfully copied, uri: '$uri'.");

start("Now we will delete the copy of the spreadsheet.");
$ss_copy->delete_spreadsheet();
end("Spreadsheet successfully deleted.");

# clean up any failed previous runs.
$sheets->delete_all_spreadsheets("${name}_copy");

$uri = $ss->spreadsheet_uri();
message('green', "\nOpen url '$uri' and proceed to the next step.\n");

message('blue', "We are done, here are some api stats:\n", Dump($ss->stats()));
