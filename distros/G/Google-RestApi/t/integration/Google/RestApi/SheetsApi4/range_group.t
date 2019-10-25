#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use lib "$FindBin::RealBin/../../../../../lib";

use Test::Most tests => 4;
use YAML::Any qw(Dump);

use Utils;
Utils::init_logger();

my $spreadsheet = Utils::spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

my @values_in = (
  [1,  2, 3],
  [4,  5, 6],
      99,
);
my @values_out = (
  [1, 99, 3],
  [4, 99, 6],
      99,
);

my $col = $worksheet->range_col("B");
my $row = $worksheet->range_row(2);
my $cell = $worksheet->range_cell([2,2]);
my $range_group = $spreadsheet->range_group($col, $row, $cell);

lives_ok sub { $range_group->batch_values(values => \@values_in), }, "Setting up mixed batch values should live";
lives_ok sub { $range_group->submit_values(); }, "Submitting mixed values should live";
lives_ok sub { $range_group->refresh_values(); }, "Refresh values on range group should live";
is_deeply $range_group->values(), \@values_out, "Range group values should be correct";

Utils::delete_all_spreadsheets($spreadsheet->sheets());
