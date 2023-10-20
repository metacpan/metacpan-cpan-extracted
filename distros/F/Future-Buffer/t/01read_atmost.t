#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::Buffer;

my $buf = Future::Buffer->new;

is( $buf->length, 0, 'length initially' );
ok( $buf->is_empty, 'empty initially' );

# read_atmost extracts data
{
   $buf->write( "ABCD" );

   is( $buf->length, 4, 'length after ->write' );
   ok( !$buf->is_empty, '!empty after ->write' );

   my $f = $buf->read_atmost( 4 );
   ok( $f->is_ready, '->read_atmost(4) is ready' );
   is( $f->get, "ABCD", '->read_atmost(4) extracted data' );

   ok( $buf->is_empty, '$buf empty after read_atmost' );
}

# read_atmost awaits until data
{
   my $f = $buf->read_atmost( 4 );
   ok( !$f->is_ready, '->read_atmost(4) while empty is not ready' );

   $buf->write( "EFGH" );

   ok( $f->is_ready, '->read_atmost(4) now ready' );
   is( $f->get, "EFGH", '->read_atmost(4) extracted data' );
}

# read_atmost can return short
{
   $buf->write( "IJKL" );
   my $f = $buf->read_atmost( 1024 );

   ok( $f->is_ready, '->read_atmost(1024) still yields something' );
   is( $f->get, "IJKL", '->read_atmost(1024) extracted data' );
}

# read_atmost doesn't pull too much
{
   $buf->write( "MNOP" );

   is( $buf->read_atmost( 1 )->get, "M",   '->read_atmost(1) yields no more than 1 byte' );
   is( $buf->read_atmost( 3 )->get, "NOP", '->read_atmost(3) yields the remainder' );
}

# Unread puts data back in
{
   $buf->unread( "QRS" );
   my $f = $buf->read_atmost( 3 );

   is( $f->get, "QRS", '->read_atmost after ->unread' );

   $f = $buf->read_atmost( 3 );
   $buf->unread( "TUV" );

   is( $f->get, "TUV", '->read_atmost completed by subsequent ->unread' );
}

# Read futures can be cancelled
{
   my $f1 = $buf->read_atmost( 5 );
   my $f2 = $buf->read_atmost( 5 );

   $f1->cancel;

   $buf->write( "WX" );
   is( $f2->get, "WX", 'Second ->read_atmost receives data when first is cancelled' );
}

done_testing;
