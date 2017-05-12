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
    my $k2 = $p->get_attr_with_value($gc,"dont_use");
    chomp($k2);
    if ($k2 =~ /true/) {
      print "$i\n";
    }
  }
}

