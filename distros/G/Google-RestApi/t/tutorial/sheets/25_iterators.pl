#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../../lib";

use Test::Tutorial::Setup;

# init_logger($TRACE);

my $name = "Sheet1";
my $spreadsheet_name = spreadsheet_name();
my $sheets_api = sheets_api();

start_note("20_worksheet.pl to load data into the worksheet to work with");

my $ss = $sheets_api->open_spreadsheet(name => $spreadsheet_name);
my $uri = $ss->spreadsheet_uri();
end("Spreadsheet successfully opened, enter url '$uri' in your browser to follow along.");

$sheets_api->rest_api()->api_callback(\&show_api);

start("Now we will open the spreadsheet and worksheet.");
my $ws0 = $ss->open_worksheet(id => 0);
end_go("Worksheet is now open.");

my $search = 'Freddie Mercury';
my $count = 0;
# simple iterator on a single column.
{
  start("We will now iterate through the name column with a simple iterator looking for '$search'");
  my $name_col = $ws0->range_col('B');
  my $i = $name_col->iterator();
  while (my $cell = $i->next()) {
    $count++;
    my $name = $cell->values();
    last if $name eq $search;
  }
  die "Unable to find '$search', has 20_worksheet.pl been run first?" if !$name;
  end("'$search' is at offset $count.");
}

# simple iterator on a single column, prefetched.
{
  start("Notice the previous iteration required an API call to fetch each cell. You can prevent that by pre-fectching the column by calling 'values()' before iterating it. Let's look for '$search' again but see how many calls it takes this time.");
  my $name_col = $ws0->range_col('B');
  $name_col->values();       # prefetch the column.
  my $i = $name_col->iterator();
  while (my $cell = $i->next()) {
    my $name = $cell->values();
    last if $name eq $search;
  }
  die "Unable to find '$search', has 20_worksheet.pl been run first?" if !$name;
  end("'$search' is customer $count.");
}

my $row;
# iterator on two columns using a range group to look up a customer id.
{
  start("Now we can do a lookup of $search\'s customer ID by using a range group to iterate.");
  my $rg = $ws0->range_group_cols(['A', 'B']);
  $rg->values();             # prefetch the columns.
  my $i = $rg->iterator();
  while (1) {
    $row = $i->next();
    my $name = (($row->ranges())[1])->values();
    last if $name eq $search;
    die "Unable to find '$search', has 20_worksheet.pl been run first?" if !$name;
  }
  my $id = (($row->ranges())[0])->values();
  end("$search\'s customer ID is $id.");
}

{
  start("Now we can will do a lookup of $search\'s customer ID by using a tied hash with column headings for keys.");
  $ws0->enable_header_row();
  my $cols = $ws0->tie_cols(id => 'Id', name => 'Name');
  tied(%$cols)->values();      # prefetch the columns.
  my $i = tied(%$cols)->iterator(from => 1); # from 1 to skip the header row.
  while ($row = $i->iterate()) {
    tied(%$row)->values();
    last if $row->{name} eq $search;
  }
  die "Unable to find '$search', has 20_worksheet.pl been run first?" if !$row->{name};
  end("$search\'s customer ID is $row->{id}.");
}

message('blue', "We are done, here are some api stats:\n", Dump($ss->stats()));
