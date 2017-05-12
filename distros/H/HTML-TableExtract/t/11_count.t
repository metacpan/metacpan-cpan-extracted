#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 222;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/basic.html";

use HTML::TableExtract;

# By count
my $label = 'by count';
my $te = HTML::TableExtract->new( count => 1 );
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', 2, "$label (extract count)");
good_data($_, "$label (data)") foreach @tablestates;
