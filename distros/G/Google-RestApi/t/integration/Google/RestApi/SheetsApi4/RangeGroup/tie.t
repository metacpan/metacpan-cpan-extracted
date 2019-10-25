#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../..";
use lib "$FindBin::RealBin/../../../../../../lib";

use YAML::Any qw(Dump);
use Test::Most tests => 8;

use Utils;
Utils::init_logger();

my $spreadsheet = Utils::spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

my $tied;
lives_ok sub { $tied = $worksheet->tie(); }, "Simple tie should succeed";
lives_ok sub { $tied->{A1} = "This is text for A1"; }, "Setting tied A1 text should succeed";
lives_ok sub { $tied->{A2} = "This is text for A2"; }, "Setting tied A2 text should succeed";
lives_ok sub { tied(%$tied)->submit_values(); }, "Updating tied values should succeed";

my $ranges;
lives_ok sub { $tied = $worksheet->tie_cells(qw(A1 A2)); }, "Tie with simple cells should succeed";
lives_ok sub { tied(%$tied)->values(); }, "Fetching tied values should succeed";
is $tied->{A1}, "This is text for A1", "Checking tied A1 text should succeed";
is $tied->{A2}, "This is text for A2", "Checking tied A2 text should succeed";
