#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::Buffer;

my $buf = Future::Buffer->new;

is( $buf->length, 0, 'length initially' );
ok( $buf->is_empty, 'empty initially' );

# read extracts data
{
   $buf->write( "ABCD" );

   is( $buf->length, 4, 'length after ->write' );
   ok( !$buf->is_empty, '!empty after ->write' );

   my $f = $buf->read( 4 );
   ok( $f->is_ready, '->read(4) is ready' );
   is( $f->get, "ABCD", '->read(4) extracted data' );

   ok( $buf->is_empty, '$buf empty after read' );
}

# read awaits until data
{
   my $f = $buf->read( 4 );
   ok( !$f->is_ready, '->read(4) while empty is not ready' );

   $buf->write( "EFGH" );

   ok( $f->is_ready, '->read(4) now ready' );
   is( $f->get, "EFGH", '->read(4) extracted data' );
}

# read can return short
{
   $buf->write( "IJKL" );
   my $f = $buf->read( 1024 );

   ok( $f->is_ready, '->read(1024) still yields something' );
   is( $f->get, "IJKL", '->read(1024) extracted data' );
}

# read doesn't pull too much
{
   $buf->write( "MNOP" );

   is( $buf->read( 1 )->get, "M",   '->read(1) yields no more than 1 byte' );
   is( $buf->read( 3 )->get, "NOP", '->read(3) yields the remainder' );
}

done_testing;
