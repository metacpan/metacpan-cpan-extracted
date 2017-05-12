#!/usr/bin/perl

# a quick testcase to verify that the AutoProfiler
# handles wantarray properly.

use AutoProfiler;

use Data::Dumper;

my @results = &foo(45);

print "Results are ",Dumper(\@results),"\n"; 

sub foo 
  {   my @stuff = (1,2,3,4); 

      print "Wantarray is ",wantarray,"\n"; 
      return @stuff; 
  }
