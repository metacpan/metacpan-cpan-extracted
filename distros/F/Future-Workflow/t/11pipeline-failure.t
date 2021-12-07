#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';

use Test::More;

use Future::Workflow::Pipeline;

use Future::AsyncAwait 0.47;  # toplevel await
use Future;

{
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   # Stage crashes on even numbers
   $p->append_stage( async sub ( $item ) {
      die "No evens" if $item % 2 == 0;
      return "$item-A"
   } );

   await $p->push_input( $_ ) for 1 .. 3;

   is_deeply( \@finished, [qw( 1-A 3-A )],
      '@finished after failing stage still sees successful items'
   );
   like( $warnings, qr/^Pipeline stage failed: No evens /,
      'warnings thrown from failing stage'
   );
}

{
   my $p = Future::Workflow::Pipeline->new;

   my @finished;

   $p->set_output( async sub ( $item ) { push @finished, $item } );

   my $failed;
   $p->append_stage(
      async sub ( $item ) {
         die "Always fails\n";
      },
      on_failure => sub ( $f ) {
         $failed++;
         Test::More::isa_ok( $f, "Future", '$f' );
         Test::More::is( $f->failure, "Always fails\n", '$f->failure' );
      }
   );

   await $p->push_input( "anything" );

   is( $failed, 1, '$failed after on_failure test' );
}

done_testing;
