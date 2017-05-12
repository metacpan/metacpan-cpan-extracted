#!/usr/bin/perl

use Test::More;

plan tests => 1;

my $file = './lib/EBook/MOBI.pm';

if( open my $fh, '<', $file ){
  my $bool = 0;
  while( my $line = <$fh> ){
     if( $line =~ /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/ ){
         $bool = 1;
     }
  }
  $bool ? pass( $file ) : fail( $file );
}
else{
  fail( $file );
}

