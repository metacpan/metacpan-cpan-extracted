#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Future::XS;

BEGIN {
   plan skip_all => "Test::MemoryGrowth is not available" unless
      defined eval { require Test::MemoryGrowth };

   Test::MemoryGrowth->import;
}

no_growth {
   my $f = Future::XS->new;
   $f->done( 123 );
   $f->result;
} 'Future::XS->new->done does not leak';

no_growth {
   my $f = Future::XS->new;
   $f->fail( "Oopsie\n" );
   $f->failure;
} 'Future::XS->new->fail does not leak';

no_growth {
   my $f = Future::XS->new;
   $f->cancel;
} 'Future::XS->new->cancel does not leak';

no_growth {
   my $fret = ( my $f1 = Future::XS->new )
      ->then( sub { Future::XS->done } );

   $f1->done;
   $fret->result;
} 'Future::XS->then does not leak';

no_growth {
   my $fret = ( my $f1 = Future::XS->new )
      ->else( sub { Future::XS->done } );

   $f1->done;
   $fret->result;
} 'Future::XS->else does not leak';

no_growth {
   Future::XS->wait_all(
      Future::XS->new, Future::XS->new, Future::XS->new,
   )->cancel;
} 'Future::XS->wait_all on three subfutures does not leak';

no_growth {
   Future::XS->wait_any(
      Future::XS->new, Future::XS->new, Future::XS->new,
   )->cancel;
} 'Future::XS->wait_any on three subfutures does not leak';

no_growth {
   Future::XS->needs_all(
      Future::XS->new, Future::XS->new, Future::XS->new,
   )->cancel;
} 'Future::XS->needs_all on three subfutures does not leak';

no_growth {
   Future::XS->needs_any(
      Future::XS->new, Future::XS->new, Future::XS->new,
   )->cancel;
} 'Future::XS->needs_any on three subfutures does not leak';

no_growth {
   my $f = Future::XS->new;
   $f->set_label( "A string label here" );
} 'Future::XS->set_label does not leak';

no_growth {
   my $f = Future::XS->new;
   $f->set_udata( datum => [] );
} 'Future::XS->set_label does not leak';

done_testing;
