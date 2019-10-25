#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../../..";
use lib "$FindBin::RealBin/../../../../../../../lib";

use Test::Most tests => 32;

use Utils;
Utils::init_logger();

my $spreadsheet = Utils::spreadsheet();
my $worksheet = $spreadsheet->open_worksheet(id => 0);

my @values = (
  [ '',        'Freddie', 'Iggy' ],
  [ 'Mercury', 1,         2      ],
  [ 'Pop',     3,         4      ],
);
$worksheet->range("A1:C3")->values(values => \@values);

cols_read();
rows_read();
cols_write();
rows_write();

sub cols_read {
  my $cols = $worksheet->tie_cols(qw(Freddie Iggy));

  my ($i, $row);
  lives_ok sub { $i = tied(%$cols)->iterator(from => 1); }, "Tied row iterator should live";
  lives_ok sub { $row = $i->next(); }, "First tied row iteration should live";
  lives_ok sub { tied(%$row)->values(); }, "Retrieving row iterator values should live";
  is $row->{Freddie}, 1, "Freddie should be 1";
  is $row->{Iggy}, 2, "Iggy should be 2";

  lives_ok sub { $row = $i->next(); }, "Third tied row iteration should live";
  lives_ok sub { tied(%$row)->values(); }, "Retrieving row iterator values should live";
  is $row->{Freddie}, 3, "Freddie should be 3";
  is $row->{Iggy}, 4, "Iggy should be 4";

  lives_ok sub { $row = $i->next(); }, "Forth tied row iteration should live";
  lives_ok sub { tied(%$row)->values(); }, "Retrieving row iterator values should live";
  is $row->{Freddie}, undef, "Freddie should be undef";
  is $row->{Iggy}, undef, "Iggy should be undef";

  return;
}

sub cols_write {
  my $cols = $worksheet->tie_cols(qw(Freddie Iggy));

  my ($i, $row);
  $i = tied(%$cols)->iterator(from => 1);
  $row = $i->next();
  $row->{Freddie} = 10;
  $row->{Iggy} = 20;
  lives_ok sub { tied(%$row)->submit_values(); }, "Submitting row values should live";
  is_deeply $worksheet->row(2), ['Mercury', 10, 20], "Updated row values should be set";

  return;
}

sub rows_read {
  my $rows = $worksheet->tie_rows(qw(Mercury Pop));

  my ($i, $col);
  lives_ok sub { $i = tied(%$rows)->iterator(from => 1); }, "Tied col iterator should live";
  throws_ok sub { $col = $i->next(); }, qr/Unable to translate row/, "First tied col iteration should die";
  lives_ok sub { $worksheet->enable_header_col(1); }, "Enabling header col should live";
  lives_ok sub { $col = $i->next(); }, "First tied col iteration should live";
  lives_ok sub { tied(%$col)->values(); }, "Retrieving col iterator values should live";
  is $col->{Mercury}, 1, "Mercury should be 1";
  is $col->{Pop}, 3, "Pop should be 3";

  lives_ok sub { $col = $i->next(); }, "Third tied col iteration should live";
  lives_ok sub { tied(%$col)->values(); }, "Retrieving col iterator values should live";
  is $col->{Mercury}, 2, "Mercury should be 2";
  is $col->{Pop}, 4, "Pop should be 4";

  lives_ok sub { $col = $i->next(); }, "Forth tied col iteration should live";
  lives_ok sub { tied(%$col)->values(); }, "Retrieving col iterator values should live";
  is $col->{Mercury}, undef, "Mercury should be undef";
  is $col->{Pop}, undef, "Pop should be undef";

  return;
}

sub rows_write {
  my $cols = $worksheet->tie_rows(qw(Mercury Pop));

  my $i = tied(%$cols)->iterator(from => 1);
  my $col = $i->next();
  $col->{Mercury} = 30;
  $col->{Pop} = 40;
  lives_ok sub { tied(%$col)->submit_values(); }, "Submitting col values should live";
  is_deeply $worksheet->col(2), ['Freddie', 30, 40], "Updated col values should be set";

  return;
}

Utils::delete_all_spreadsheets($spreadsheet->sheets());

# use YAML::Any qw(Dump);
# warn Dump($spreadsheet->stats());
