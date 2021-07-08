#!/usr/bin/perl

use strict;
use warnings;


use Test::Most tests => 6;
use YAML::Any qw(Dump);

use aliased "Google::RestApi::SheetsApi4::RangeGroup";

use Utils qw(:all);
init_logger();

my $spreadsheet = spreadsheet();
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

isa_ok $range_group->batch_values(values => \@values_in), RangeGroup, "Setting up mixed batch values";
is_array $range_group->submit_values(), "Submitting mixed values";
isa_ok $range_group->refresh_values(), RangeGroup, "Refresh values on range group";
is_deeply $range_group->values(), \@values_out, "Range group values should be correct";
is_hash $range_group->clear(), "Range group clear";
is_deeply $range_group->values(), [undef, undef, undef], "Range group values after clear should be empty";

delete_all_spreadsheets($spreadsheet->sheets());
