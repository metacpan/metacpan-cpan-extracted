#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 2;
require 't/util.pl';

use Iterator::File;


## resume, part 1 -- churn through 5 lines.  2nd process should get the next 5
{
  my $file = 't/data/ten_lines.txt'; 
  my $expected = join("", (slurp( $file ))[0..2] );

  my $i = iterator_file( $file,
                         'chomp'  => 0,
                         'resume' => 1);
  ## This seems odd, but ensures cleanup from a prior test took place &
  ## makes results consistent from run-to-run
  $i->finish();
  $i = iterator_file( $file,
                      'chomp'  => 0,
                      'resume' => 1);
  
  my $state_object = $i->state_object();
  is( $state_object->marker(), 0, "starting at 0");
  
  my $actual = "";
  $actual .= $i->next() for (1 .. 3);

  is( $actual, $expected, "resume, part 1");
}
