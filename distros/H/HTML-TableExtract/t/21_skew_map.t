#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 26;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/skew.html";

use HTML::TableExtract;

# By count
my $label = 'by header with column mapping';
my $te = HTML::TableExtract->new(
  headers => [ qw(head3 head2 head1 head0) ],
);
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', 1, "$label (extract count)");
good_skew_data($_, "$label (data)") foreach @tablestates;
