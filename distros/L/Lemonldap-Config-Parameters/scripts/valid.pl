#!/usr/bin/perl -w
use strict;
use XML::Simple;
my $file = shift;
my $test;
eval {
$test = XMLin( $file,
                              );		     

} ;

if ($@) { print "ERREUR SUR $file\n"; 
          } else {
		 print "$file:Correct\n"; 
	  }					      
