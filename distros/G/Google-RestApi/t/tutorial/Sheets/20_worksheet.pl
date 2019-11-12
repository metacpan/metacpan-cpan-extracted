#!/usr/bin/perl

use strict;
use warnings;

# use Carp::Always;
use FindBin;
use lib "$FindBin::RealBin/../../../lib";
use lib "$FindBin::RealBin/../../integration";

use YAML::Any qw(Dump);
use Utils qw(init_logger message start end end_go show_api);

init_logger();

my $name = "Sheet1";
my $spreadsheet_name = $Utils::spreadsheet_name;
my $sheets = Utils::sheets_api(post_process => \&show_api);

start("Now we will open the spreadsheet and worksheet.");
my $ss = $sheets->open_spreadsheet(name => $spreadsheet_name);
my $ws0 = $ss->open_worksheet(id => 0);
end_go("Worksheet is now open.");

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
$ss->submit_requests(requests => [$all, $col, $row]);
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
# no batch used, values instantly update.
start("Now we will insert some column headings.");
$row->insert_d()->freeze()->submit_requests();
$row->values(values => [qw(ID Name Tax Salary)]);
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
$rg->bold()->italic()->submit_requests();
end("Totals should now be set with formulas.");

message('blue', "We are done, here are some api stats:\n", Dump($ss->stats()));
