#!/usr/bin/perl -w
use strict;
use Liberty::Parser;
use liberty;
my $parser = new Liberty::Parser;
my $file = shift;
my $cell = shift;
my $g = $parser->read_file("$file");

my $cell_group = $parser->locate_cell($g, $cell);
my $arc = $parser->locate_cell_arc($cell_group, "cell_rise");
my @index_1 = $parser->get_lookup_table_index_1($arc);
my @index_2 = $parser->get_lookup_table_index_2($arc);
my $value_1 = print_index(\@index_1);
my $center_1 = get_center(\@index_1);
my $value_2 = print_index(\@index_2);
my $center_2 = get_center(\@index_2);
print "$cell\n";
print "index_1: $value_1, center: $center_1\n";
print "index_2: $value_2, center: $center_2\n";

sub print_index {
  my $a = shift;
  my $s;
  foreach $_ (@$a) {
    chomp;
    $s .= "$_ ";
  }
  return $s;
}

sub get_center {
  my $a = shift;
  my $center_index = $#$a/2;
  return $$a[$center_index];
}
