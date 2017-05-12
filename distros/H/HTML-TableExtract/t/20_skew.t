#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 121;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file = "$Dat_Dir/skew.html";

use HTML::TableExtract;

# By count
my $label = 'by header with span correction';
my $te = HTML::TableExtract->new(
  headers => [ qw(head0 head1 head2 head3) ],
);
ok($te->parse_file($file), "$label (parse_file)");
my @tablestates = $te->tables;
cmp_ok(@tablestates, '==', 1, "$label (extract count)");
good_skew_data($_, "$label (skew data)")     foreach @tablestates;
good_sticky_data($_, "$label (sticky data)") foreach @tablestates;

# test aliasing directly -- this is tightly coupled with a cell in the
# skew.html test file.
my $str = "BIG\nJUNK";
$label = 'alias (no headers)';
alias_test($te->first_table_found, 2, 1, $str, $label);

$label = 'alias (keep headers)';
$te = HTML::TableExtract->new(
  headers      => [ qw(head0 head1 head2 head3) ],
  keep_headers => 1,
);
ok($te->parse_file($file), "alias parse (keep headers)");
alias_test($te->first_table_found, 3, 1, $str, $label);

sub alias_test {
  my($ts, $r, $c, $str, $label) = @_;
  my $item1  = $ts->row($r)->[$c];
  my @rows   = $ts->rows;
  my $item2  = $rows[$r][$c];
  my $cell   = $ts->cell($r,$c);
  my $cellno = $ts->cell($r+2,$c+1);
  my $space  = $ts->space($r+2,$c+1);
  cmp_ok($str, 'eq',  $item1,  "$label (via row)");
  cmp_ok($str, 'eq',  $item2,  "$label (via rows)");
  cmp_ok($str, 'eq',  $cell,   "$label (via cell)");
  cmp_ok($str, 'eq',  $space,  "$label (via space)");
  cmp_ok(defined undef, '==', defined $cellno, "$label (undef via cell)");
}
