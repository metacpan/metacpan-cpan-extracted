#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Feature::Compat::Class;

{
   my @called;
   my %params;

   class Test1 {
      ADJUST {
         push @called, "ADJUST-1";
      }

      ADJUST {
         my ( $href ) = @_;
         push @called, "ADJUST-2";
         %params = %$href;
         undef %$href;
      }

      ADJUST {
         push @called, "ADJUST-3";
      }
   }

   Test1->new( key => "val" );
   is_deeply( \@called, [qw( ADJUST-1 ADJUST-2 ADJUST-3 )], 'ADJUST blocks invoked in sequence' );
   is_deeply( \%params, { key => "val" }, 'ADJUST received params hashref' );
}

done_testing;
