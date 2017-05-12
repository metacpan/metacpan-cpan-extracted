#!/usr/bin/perl

use File::Basename;
use File::Find;
use File::Spec;
use Test::More;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) . '/../lib' );

my @files;
find( \&wanted,$dir );

plan tests => scalar @files;

for my $file ( @files ){
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

}

sub wanted{
   push @files, $File::Find::name if $File::Find::name =~ /\.pm/;
}