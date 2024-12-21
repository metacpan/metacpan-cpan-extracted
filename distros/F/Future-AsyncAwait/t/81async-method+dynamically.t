#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Test2::Require::Module 'Future' => '0.49';
use Test2::Require::Module 'Future::AsyncAwait' => '0.40';
use Test2::Require::Module 'Object::Pad' => '0.800';
use Test2::Require::Module 'Syntax::Keyword::Dynamically';

use Future::AsyncAwait;
use Object::Pad;
use Syntax::Keyword::Dynamically;

# dynamically inside an async method
{
   my $after_level;

   class Logger {
      field $_level = 1;

      method level { $_level }

      async method verbosely {
         my ( $code ) = @_;
         dynamically $_level = $_level + 1;
         await $code->();
         $after_level = $_level;
      }
   }

   my $logger = Logger->new;

   is( $logger->level, 1, '$logger->level initially' );

   my $during_level;
   my $f1 = Future->new;
   my $fret = $logger->verbosely(async sub {
      $during_level = $logger->level;
      await $f1;
   });

   is( $logger->level, 1, '$logger->level while verbosely suspended' );
   is( $during_level, 2, '$during_level' );

   $f1->done;

   is( $after_level, 2, '$after_level' );
   is( $logger->level, 1, '$logger->level finally' );
}

done_testing;
