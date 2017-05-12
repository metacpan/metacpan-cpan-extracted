#!/usr/bin/perl
print "1..2\n";
use EMC::WideSky::symmaskdb;

$db=new EMC::WideSky::symmaskdb();
$db->parse_symmaskdb("input"=>"sample.xml");

unless ($db) { print "not "; }
print "ok 1\n";


for $dev (sort keys %{$db}) {
  $devs++;
#  print "$dev:";
  for $fa (keys %{$db->{$dev}}) {
    $fas++;
    for $host (keys %{$db->{$dev}->{$fa}}) {
      $hosts++;
      for $hba (keys %{$db->{$dev}->{$fa}->{$host}}) {
        $hbas++;
#        print " $fa/$host/$hba";
      }
    }
  }
#  print "\n";
}

if ($devs >= 1 && $fas >=1 && $hosts >= 1 && $hbas >= 1) {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}
