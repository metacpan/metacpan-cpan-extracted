#!/usr/bin/perl -w
use strict;
use Liberty::Parser;

my $i;
my $p = new Liberty::Parser;

my $file = shift;
my $g = $p->read_file($file);
my @cell = $p->get_group_names($g);

foreach $i (@cell) {
  my $gc = $p->locate_group($g,$i);
  my $t = $p->get_group_type($gc);
  if ($t eq "cell") {
    my $k1 = $p->get_attr_with_value($gc,"cell_footprint");
    my $k2 = $p->get_attr_with_value($gc,"area");
    chomp($k1);
    chomp($k2);
    print "$i , $k1 , $k2\n";
  }
}

