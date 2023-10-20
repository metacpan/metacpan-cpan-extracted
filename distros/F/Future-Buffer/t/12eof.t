#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::Buffer;

use Future;

# close during ->read_atmost
{
   my $buf = Future::Buffer->new;

   my $read_f = $buf->read_atmost( 128 );
   $buf->close;

   is( [ $read_f->get ], [], '->read_atmost yields empty after close' );
}

# fill EOF during ->read_atmost
{
   my @next_fill_f;

   my $buf = Future::Buffer->new(
      fill => sub { push @next_fill_f, my $f = Future->new; return $f },
   );

   my $read_f = $buf->read_atmost( 128 );
   ( shift @next_fill_f )->done();

   is( [ $read_f->get ], [], '->read_atmost yields empty at EOF' );
}

# fill EOF with queued buffer still yields some data
{
   my @next_fill_f;

   my $buf = Future::Buffer->new(
      fill => sub { push @next_fill_f, my $f = Future->new; return $f },
   );

   my $f1 = $buf->read_atmost( 10 );
   my $f2 = $buf->read_atmost( 10 );
   my $f3 = $buf->read_atmost( 10 );

   ( shift @next_fill_f )->done( "Some content here" );
   is( $f1->get, "Some conte", '->read_atmost (1) yields some data' );

   is( $f2->get, "nt here",    '->read_atmost (2) yields some data' );

   ( shift @next_fill_f )->done();
   is( [ $f3->get ], [], '->read_atmost (3) yields empty at EOF' );
}

done_testing;
