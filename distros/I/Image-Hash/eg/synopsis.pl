#!/usr/bin/perl
use strict;
use warnings;

use lib "lib";


  use Image::Hash;
  use File::Slurp;

  my $image = read_file( shift @ARGV, binmode => ':raw' ) ;
  
  my $ihash = Image::Hash->new($image);
  
  # Calculate the average hash
  my $a = $ihash->ahash();
  
  # Calculate the difference hash
  my $b = $ihash->dhash();
  
  # Calculate the perception hash
  my $p = $ihash->phash();
  
  print "$a\n$b\n$p\n";
