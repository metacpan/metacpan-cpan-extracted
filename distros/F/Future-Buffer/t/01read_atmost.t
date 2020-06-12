#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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

done_testing;
