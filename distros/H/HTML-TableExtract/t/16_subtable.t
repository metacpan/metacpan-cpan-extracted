#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 692;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/basic.html";

use HTML::TableExtract;

# By count
my $label = 'by subtable scoop';
my $te = HTML::TableExtract->new(
  depth     => 0,
  count     => 2,
  subtables => 1,
);
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', 3, "$label (extract count)");
good_data($_, "$label (data)") foreach @tablestates;

# Check subtable slice immunity
$file = "$Dat_Dir/subtable.html";
$label = 'by subtable, slice immune';
$te = HTML::TableExtract->new(
  headers   => [('SubtableHead Eight', 'SubtableHead Two')],
  subtables => 1,
);
ok($te->parse_file($file), "$label (parse_file)");
@tablestates = $te->tables;
cmp_ok(@tablestates, '==', 4, "$label (extract count)");
my $mule = splice(@tablestates, 0, 1);
my @mrows = $mule->rows;
cmp_ok(@mrows, '==', 1, "$label (mule row check)");
cmp_ok(@{$mrows[0]}, '==', 4, "$label (mule col check)");
good_slice_data($tablestates[-1], "$label (data)", 0, 3);
good_data($_, "$label (data)") foreach @tablestates[0,1];

# Check subtable slice precedence
$label = 'by subtable, slice precedence';
$te = HTML::TableExtract->new(
  headers   => [('Head.*Eight', 'Head.*Two')],
  subtables => 1,
);
ok($te->parse_file($file), "$label (parse_file)");
@tablestates = $te->tables;
cmp_ok(@tablestates, '==', 4, "$label (extract count)");
$mule = splice(@tablestates, 2, 1);
@mrows = $mule->rows;
cmp_ok(@mrows, '==', 1, "$label (mule row check)");
cmp_ok(@{$mrows[0]}, '==', 4, "$label (mule col check)");
good_slice_data($tablestates[-1], "$label (data)", 0, 3);
good_data($_, "$label (data)", 2, 8) foreach @tablestates[0,1];
