#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
require 't/util.pl';

use Iterator::File;

## Is IO::Scalar present?  If not, skip tests that need it.
my $io_scalar_found = 0;
if(eval "use IO::Scalar; 1") {
  $io_scalar_found = 1;
}


{
  my $file = 't/data/three_lines.txt'; 
  my $expected = slurp( $file );
  
  my $i = iterator_file( $file,
                         'chomp' => 0 );

  my $actual = "";
  while ($i++) {
      $actual .= $i->value();
  }
  
  is( $actual, $expected, "overload_add");
}


SKIP: {
  skip "IO::Scalar not installed.", 1 unless $io_scalar_found;
  my $data = '';
  my $fh = new IO::Scalar \$data;
  my $file = 't/data/three_lines.txt';

  my $i = iterator_file( $file );
  $i->next();
  print $fh "Test: $i :tseT";

 is($fh, "Test: this is the first line :tseT", "as_string overload");
}



