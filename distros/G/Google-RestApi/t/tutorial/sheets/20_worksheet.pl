#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;

# init_logger($TRACE);

my $name = "Sheet1";
my $spreadsheet_name = spreadsheet_name();
my $sheets_api = sheets_api();

start_note("10_spreadsheet.pl to create a spreadsheet to work with");

my $ss = $sheets_api->open_spreadsheet(name => $spreadsheet_name);
my $uri = $ss->spreadsheet_uri();
end("Spreadsheet successfully opened, enter url '$uri' in your browser to follow along.");

$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will open the spreadsheet and worksheet");
$ss->add_worksheet(name => 'Fred')->submit_requests();
my $ws0 = $ss->open_worksheet(name => 'Fred');
$ws0->ws_rename('Joe');
end_go("Worksheet 'Joe' is now open.");

# resets the spreadsheet. collects up a bunch of batch requests, then
# gets the spreadsheet to run them. running 'submit_requests' against
# just one of the ranges does only that one. saving up a bunch and getting
# the spreadsheet to run them all creates a single batch request.
start("Now we will clear the 'Payroll' spreadsheet from any previous run.");
# my $all = $ws0->range_all();
my $all = $ws0->range("A1:E8");
$all->reset();
my $col = $ws0->range_col(1);
my $row = $ws0->range_row(1);
$col->thaw();
$row->thaw();
$ss->submit_requests(ranges => [$all, $col, $row]);
end("'Payroll' spreadsheet should now be blank.");

# load up some sample data without any batch processing.
start("Now we will load the 'Payroll' spreadsheet with data.");
my @rows = (
  [ 1001, "Herb Ellis", "100", "10000" ],
  [ 1002, "Bela Fleck", "200", "20000" ],
  [ 1003, "Freddie Mercury", "999", "99999" ],
);
$ws0->rows([1, 2, 3], \@rows);
end("'Payroll' worksheet should now have some data.");

# still points to row 1 after the insert.
# insert a row and freeze it using batch request.
start("Now we will insert some column headings.");
$row->insert_d()->freeze()->submit_requests();
# no batch used, values instantly update.
$row->values(values => [qw(Id Name Tax Salary)]);
end("'Payroll' worksheet should now have headings.");

# 'heading' sets a bunch of formats at once.
# could achieve a similar result with 
# $heading->bold->center->font_size(12)->etc.
# ranges can be specified in very flexible ways.
start("Now we will format the column headings.");
my $heading = $ws0->range([
  "A1",                          # cell a1
  [ scalar(@{ $rows[0] }), 1 ]   # to D1
]);
$heading->heading()->submit_requests();
end("'Payroll' worksheet headings should now be formatted.");

# a column could start at the second row and still be called a column.
start("Now we will bold the IDs column.");
$ws0->range_col("A2:A")->bold()->submit_requests();
end("IDs should now be bolded.");

# do a batch update and formatting request via a range group.
# range groups can be used to format each range in the range group.
# ranges can be specified in very flexible ways.
start("Now we will set a couple of formulas via batch.");
my $tax = $ws0->range_cell([ 3, 5 ]);                    # same as "C5"
my $salary = $ws0->range_cell({ row => 5, col => "D" }); # same as "D5"
$tax->batch_values(values => "=SUM(C2:C4)");
$salary->batch_values(values => "=SUM(D2:D4)");
my $rg = $ss->range_group($tax, $salary);
$rg->submit_values();
$rg->bold()->italic()->bd_solid()->bd_thick('bottom')->submit_requests();
end("Totals should now be set with formulas.");

message('green', "\nProceed to 25_worksheet.pl.\n");

message('blue', "We are done, here are some api stats:\n", Dump($ss->stats()));
