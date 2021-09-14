#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Term::Status;
use String::Tagged;
use Convert::Color;
use Time::HiRes 'sleep';

my $term = IO::Term::Status->new_for_stdout;

my $count = 10;

while( $count ) {
   $term->set_status(
      String::Tagged->new_tagged( sprintf( "%d remaining", $count ),
         bg => Convert::Color->new( "vga:blue" ),
      )
   );

   $term->more_partial( "sleeping" );

   for ( 1 .. 5 ) {
      sleep 0.2;
      $term->more_partial( "." );
   }

   $term->replace_partial( "sleep $count OK" );
   $term->finish_partial( "" );

   $count--;
}

$term->set_status( "" );
