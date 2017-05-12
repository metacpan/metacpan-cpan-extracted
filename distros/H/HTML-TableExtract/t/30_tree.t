#!/usr/bin/perl

my $test_count;
BEGIN { $test_count = 126 }

use strict;
use lib './lib';
use Test::More tests => $test_count;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $et_version = '1.17';

my($tb_present, $et_present);
eval  "use HTML::TreeBuilder";
$tb_present = !$@;
eval  "use HTML::ElementTable $et_version";
$et_present = !$@;

SKIP: {
  skip "HTML::TreeBuilder not installed",
       $test_count unless $tb_present;
  skip "HTML::ElementTable $et_version not installed",
       $test_count unless $et_present;
  use_ok("HTML::TableExtract", qw(tree));
  my $file = "$Dat_Dir/gnarly.html";
  my $label = 'element table';
  my $te = HTML::TableExtract->new();
  isa_ok($te, 'HTML::TreeBuilder', "$label - HTML::TableExtract");
  ok($te->parse_file($file), "$label (parse_file)");
  my @tablestates = $te->tables;
  cmp_ok(@tablestates, '==', 1, "$label (extract count)");
  good_gnarly_data($_, "$label (data)") foreach @tablestates;
  my $tree = $te->tree;
  ok($tree, 'treetop');
  isa_ok($tree, 'HTML::Element');
  foreach my $ts ($te->tables) {
    my $tree = $ts->tree;
    ok($tree, 'tabletop');
    isa_ok($tree, 'HTML::ElementTable');
  }
  local *FH;
  open(FH, '<', $file) or die "Oops opening $file : $!\n";
  my $hstr = join('', <FH>);
  close(FH);
  $hstr =~ s/\n//gm;
  $te->_attribute_purge;
  my $estr = $te->elementify->as_HTML;
  $estr =~ s/\n//gm;
  $estr =~ s/\"//gm;
  cmp_ok($estr, 'eq', $hstr, 'mass html comp');

  # TREE() gets called during header extractions, make sure it does
  $label .= ' (header)';
  $te = HTML::TableExtract->new(
    headers => [qr|\(0,1\) \[2,4\]|],
  );
  ok($te->parse_file($file), "$label (parse_file)");
  $tree = $te->tree;
  ok($tree, 'treetop');
  isa_ok($tree, 'HTML::Element');
  my $table = $te->first_table_found;
  good_gnarly_data($table, "$label (data)");
  $tree = $table->tree;
  ok($tree, 'tabletop');
  isa_ok($tree, 'HTML::ElementTable');
}
