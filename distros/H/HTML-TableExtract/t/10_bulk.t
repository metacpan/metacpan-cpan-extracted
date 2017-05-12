#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 52;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/ugly.html";

BEGIN { require_ok('HTML::TableExtract') }

# by bulk, lineage integrity
my $label = 'by bulk with lineage check';
my $te = HTML::TableExtract->new();
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', @LINEAGE_DATA, "$label (extract count)");
foreach my $tsc (0 .. $#tablestates) {
  my $ts = $tablestates[$tsc];
  foreach (0 .. $#{$ts->{lineage}}) {
    cmp_ok(join(',', @{$ts->{lineage}[$_]}), 'eq',
      $LINEAGE_DATA[$tsc][$_], "$label (data)");
  }
  my $mod = 1;
  $mod = 0 unless $ts->{headers} && !$ts->{keep_headers};
  my @rows = $ts->rows;
  cmp_ok(@rows, '==', @{$ts->{grid}}-$mod, "rows() returns correct number of rows");
}
