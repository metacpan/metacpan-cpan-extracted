#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 7;
#use Test::More 'no_plan';
require 't/util.pl';

BEGIN {
  use_ok( "Iterator::File" );
};


## Is IO::Scalar present?  If not, skip tests that need it.
my $io_scalar_found = 0;
if(eval "use IO::Scalar; 1") {
  $io_scalar_found = 1;
}

## default
{
  my $file = 't/data/three_lines.txt'; 
  my $expected = slurp( $file );
  $expected =~ s|\n||g;

  my $i = iterator_file( $file );
  my $actual = join("", $i->next(), $i->next(), $i->next()); 

  is( $actual, $expected, "default options");
  
}

## chomp disabled
{
  my $file = 't/data/three_lines.txt'; 
  my $expected = slurp( $file );
  
  my $i = iterator_file( $file,
                         'chomp' => 0 );
  my $actual = join("", $i->next(), $i->next(), $i->next());
  
  is( $actual, $expected, "chomp disabled");
}


## make sure we get all lines with a while loop
{
  my $file = 't/data/three_lines.txt'; 
  my $expected = slurp( $file );
  
  my $i = iterator_file( $file,
                         'chomp' => 0 );

  my $actual = "";
  while ($i->next()) {
      $actual .= $i->value();
  }
  
  is( $actual, $expected, "while loop, using value");
}



{
  my $file = 't/data/three_lines.txt'; 
  my $expected = slurp( $file );
  
  my $i = iterator_file( $file,
                         'chomp' => 0 );

  my $actual = "";
  while ($i->next()) {
      $actual .= $i; 
  }

  is( $actual, $expected, "scalar context");
}



{
  my $file = 't/data/ten_lines.txt'; 
  my $expected = slurp( $file );
  $expected = join("", ( split /\n/, $expected )[8 .. 9]);
  
  my $i = iterator_file( $file );
  $i->skip_next( 8 );
  
  my $actual = "";
  while ($i->next()) {
      $actual .= $i->value();
  }
  
  is( $actual, $expected, "skip_next");
}



SKIP: {
  skip "IO::Scalar not installed.", 1 unless $io_scalar_found;
  
  my $data = '';
  my $fh = new IO::Scalar \$data;

  my $file = 't/data/ten_lines.txt'; 
  my $expected = slurp( $file );
  
  my $i = iterator_file( $file,
                         'status_filehandle' => $fh,
                         'status'         => 1, 
                         'chomp'          => 0 );

  my $actual = "";
  while ($i++) {
      $actual .= $i; 
  }

  is( $actual, $expected, "scalar context");
}




