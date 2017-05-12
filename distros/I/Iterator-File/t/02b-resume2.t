#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
require 't/util.pl';

use Iterator::File;

my $file = 't/data/ten_lines.txt'; 

## resume, part 2
{
  my $expected = join("", (slurp( $file ))[3 .. 9] );

  my $i = iterator_file( $file,
                         'chomp' => 0,
                         'resume' => 1);
  
  my $actual = "";
  do { $actual .= $i->value(); } while $i->next();

  is( $actual, $expected, "resume, part 2");
}

## make sure our temp file is cleanup
{
  my $i = iterator_file( $file,
                         'chomp' => 0,
                         'resume' => 1);
  $i->finish();
  
  my $state_object = $i->state_object();
  ok( ! -f $state_object->marker_file(), "cleanup" );

}
