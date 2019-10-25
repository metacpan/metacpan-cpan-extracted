#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../..";
use lib "$FindBin::RealBin/../../../../../../lib";

use YAML::Any qw(Dump);
use Test::Most tests => 22;

use Utils;
Utils::init_logger();

my $spreadsheet = Utils::spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

my @values = (
  [ 1, 2, 3],
  [ 4, 5, 6],
  [ 7, 8, 9],
);
$worksheet->range("A1:C3")->values(values => \@values);

my $col = $worksheet->range_col(1);
my $row = $worksheet->range_row(1);
my $range_group = $spreadsheet->range_group($col, $row);

defaults();
by();
from();
to();

sub defaults {
  my ($i, $rg);
  lives_ok sub { $i = $range_group->iterator(); }, "Iterator creation should live";
  lives_ok sub { $rg = $i->next(); }, "First iteration should live";
  is_deeply $rg->values(), [1, 1], "First iteration should be [1, 1]";
  lives_ok sub { $rg = $i->next(); }, "Third iteration should live";
  is_deeply $rg->values(), [4, 2], "Third iteration should be [4, 2]";
  lives_ok sub { $rg = $i->next(); }, "Forth iteration should live";
  is_deeply $rg->values(), [7, 3], "Forth iteration should be [7, 3]";
  lives_ok sub { $rg = $i->next(); }, "Fifth iteration should live";
  is_deeply $rg->values(), [undef, undef], "Fifth iteration should be undef";
  return;
}

sub by {
  my ($i, $rg);
  lives_ok sub { $i = $range_group->iterator(by => 2); }, "'By' iterator creation should live";
  $rg = $i->next() for (1..2);
  is_deeply $rg->values(), [7, 3], "Second 'by' iteration should be [7, 3]";
  lives_ok sub { $rg = $i->next(); }, "Third 'by' iteration should live";
  is_deeply $rg->values(), [undef, undef], "Third 'by' iteration should be undef";
  return;
}

sub from {
  my ($i, $rg);
  lives_ok sub { $i = $range_group->iterator(from => 2); }, "'From' iterator creation should live";
  $rg = $i->next();
  is_deeply $rg->values(), [7, 3], "Second 'by' iteration should be [7, 3]";
  lives_ok sub { $rg = $i->next(); }, "Third 'by' iteration should live";
  is_deeply $rg->values(), [undef, undef], "Third 'by' iteration should be undef";
  return;
}

sub to {
  my ($i, $rg);
  lives_ok sub { $i = $range_group->iterator(to => 1); }, "'To' iterator creation should live";
  lives_ok sub { $rg = $i->next(); }, "First 'to' iteration should live";
  is_deeply $rg->values(), [1, 1], "First 'to' iteration should be [1, 1]";
  lives_ok sub { $rg = $i->next(); }, "Second 'to' iteration should live";
  is $rg, undef, "Second 'to' iteration should be undef";
  return;
}

Utils::delete_all_spreadsheets($spreadsheet->sheets());

# use YAML::Any qw(Dump);
# warn Dump($spreadsheet->stats());
