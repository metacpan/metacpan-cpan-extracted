#!/usr/bin/perl

use strict;
use warnings;

use YAML::Any qw(Dump);
use Test::Most tests => 8;

use aliased "Google::RestApi::SheetsApi4::RangeGroup::Tie";

use Utils qw(:all);
init_logger();

my $text1 = "This is text for A1";
my $text2 = "This is text for A2";

my $spreadsheet = spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

my $tied;
is_hash $tied = $worksheet->tie(), "Simple tie";
is $tied->{A1} = $text1, $text1, "Setting tied A1 text should succeed";
is $tied->{A2} = $text2, $text2, "Setting tied A2 text should succeed";
is_array sub { tied(%$tied)->submit_values(); }, "Updating tied values";

my $ranges;
is_hash $tied = $worksheet->tie_cells(qw(A1 A2)), "Tie with simple cells";
is_array sub { tied(%$tied)->values(); }, "Fetching tied values";
is $tied->{A1}, $text1, "Checking tied A1 text should succeed";
is $tied->{A2}, $text2, "Checking tied A2 text should succeed";

delete_all_spreadsheets($spreadsheet->sheets());
