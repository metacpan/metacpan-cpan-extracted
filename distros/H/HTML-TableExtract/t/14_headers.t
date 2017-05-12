#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 464;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/basic.html";

use HTML::TableExtract;

# By headers
my $label = 'by headers';
my $te = HTML::TableExtract->new(
    headers => [qw(Eight Six Four Two Zero)],
);
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', 5, "$label (extract count)");
good_data($_, "$label (data)") foreach @tablestates;

$te = HTML::TableExtract->new(
    headers => [qw(Eight Two)],
);
ok($te->parse_file($file), "$label (parse_file)");
@tablestates = $te->tables;
cmp_ok(@tablestates, '==', 5, "$label (extract count)");
good_slice_data($_, "$label (data)", 0, 3) foreach @tablestates;

