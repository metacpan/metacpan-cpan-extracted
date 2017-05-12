#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 112;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/basic.html";

use HTML::TableExtract;

# By count
my $label = 'by depth and count';
my $te = HTML::TableExtract->new(
  depth     => 0,
  count     => 2,
);
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', 1, "$label (extract count)");
good_data($_, "$label (data)") foreach @tablestates;
