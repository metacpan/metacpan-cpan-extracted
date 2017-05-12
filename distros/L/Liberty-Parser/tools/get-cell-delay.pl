#!/usr/bin/perl -w
use strict;
use Liberty::Parser;
use liberty;

my $parser = new Liberty::Parser;
my $file = shift;
my $cell = shift;
my $tran = shift;
my $load = shift;
my $arc;

my $g = $parser->read_file("$file");

my $cell_group = $parser->locate_cell($g, $cell);
$arc = $parser->locate_cell_arc($cell_group, "cell_rise");
my $delay_cell_rise = get_arc_delay($arc, $tran, $load);
$arc = $parser->locate_cell_arc($cell_group, "cell_fall");
my $delay_cell_fall = get_arc_delay($arc, $tran, $load);

print "($cell, $tran, $load) rise: $delay_cell_rise, fall: $delay_cell_fall\n";

sub get_arc_delay {
  my $arc = shift;
  my $tran = shift;
  my $load = shift;

  my @index_1 = $parser->get_lookup_table_index_1($arc);
  my @index_2 = $parser->get_lookup_table_index_2($arc);

  my @lookup_table = $parser->get_lookup_table($arc);

  my ($i,$j) = get_index(\@index_1, $tran);
  my ($m,$n) = get_index(\@index_2, $load);

  my @quad_table = ($lookup_table[$i][$m],$lookup_table[$i][$n],$lookup_table[$j][$m],$lookup_table[$j][$n]);

  my $p1 = $quad_table[0] + ($quad_table[1] - $quad_table[0])/($index_2[$n] - $index_2[$m])*($load - $index_2[$m]);
  my $p2 = $quad_table[2] + ($quad_table[3] - $quad_table[2])/($index_2[$n] - $index_2[$m])*($load - $index_2[$m]);

  my $p = $p1+($p2-$p1)/($index_1[$j] - $index_1[$i])*($tran - $index_1[$i]);
  $p = sprintf("%.4f", $p);
}


sub get_index {
  my $a = shift;
  my $value = shift;
  my $i;
  my $j;

  for($i=0;$i<$#$a;$i=$i+1){
    $j = $i + 1;
    return ($i,$j) if($value > $$a[$i] and $value < $$a[$j]);
  }
  die "Error: The input value $value is out of the max lookup table index value $$a[$#$a]\n";
}

