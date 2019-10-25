#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../..";
use lib "$FindBin::RealBin/../../../../../../lib";

use Test::Most tests => 31;

use Utils;
Utils::init_logger();

my $spreadsheet = Utils::spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

my @values = (
  [ 1,  2,  3,  4],
  [ 5,  6,  7,  8],
  [ 9, 10, 11, 12],
  [13, 14, 15, 16],
);

my ($range, $i, $cell);

$range = $worksheet->range("A1:D4");
$range->values(values => \@values);

iterate_by_col();
iterate_by_row();
iterate_by_2();

sub iterate_by_col {
  lives_ok sub { $i = $range->iterator(dim => 'col'); }, "Col iterator creation should live";
  lives_ok sub { $cell = $i->next(); }, "First col iteration should live";
  is $cell->values(), 1, "First col iteration should be '1'";
  lives_ok sub { $cell = $i->next(); }, "Second col iteration should live";
  is $cell->values(), 2, "Second col iteration should be '2'";
  $cell = $i->next() for (1..3);
  is $cell->values(), 5, "Col iteration to next row should be '5'";
  $cell = $i->next() for (1..11);
  is $cell->values(), 16, "Col iteration to last cell should be '16'";
  lives_ok sub { $cell = $i->next(); }, "Last col iteration should live";
  is $cell, undef, "Last col iteration should be undefined";
}

sub iterate_by_row {
  lives_ok sub { $i = $range->iterator(); }, "Row iterator creation should live";
  lives_ok sub { $cell = $i->next(); }, "First row iteration should live";
  is $cell->values(), 1, "First row iteration should be '1'";
  lives_ok sub { $cell = $i->next(); }, "Second row iteration should live";
  is $cell->values(), 5, "Second row iteration should be '5'";
  $cell = $i->next() for (1..3);
  is $cell->values(), 2, "Row iteration to next col should be '2'";
  $cell = $i->next() for (1..11);
  is $cell->values(), 16, "Row iteration last cell should be '16'";
  lives_ok sub { $cell = $i->next(); }, "Last row iteration should live";
  is $cell, undef, "Last row iteration should be undefined";
}

sub iterate_by_2 {
  lives_ok sub { $i = $range->iterator(by => 2); }, "By 2 iterator creation should live";
  lives_ok sub { $cell = $i->next(); }, "First by 2 iteration should live";
  is $cell->values(), 1, "First by 2 iteration should be '1'";
  lives_ok sub { $cell = $i->next(); }, "Second by 2 iteration should live";
  is $cell->values(), 9, "Second by 2 iteration should be '9'";
  lives_ok sub { $cell = $i->next(); }, "Third by 2 iteration should live";
  is $cell->values(), 2, "Third by 2 iteration should be '2'";
  lives_ok sub { $cell = $i->next(); }, "Forth by 2 iteration should live";
  is $cell->values(), 10, "Forth by 2 iteration should be '10'";
  $cell = $i->next() for (1..3);
  lives_ok sub { $cell = $i->next(); }, "By 2 iteration to last cell should live";
  is $cell->values(), 12, "By 2 iteration should be '12'";
  lives_ok sub { $cell = $i->next(); }, "Last by 2 iteration should live";
  is $cell, undef, "Last by 2 iteration should be undefined";
}

Utils::delete_all_spreadsheets($spreadsheet->sheets());

# use YAML::Any qw(Dump);
# warn Dump($spreadsheet->stats());
