#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
   use_ok "MCE::Shared";
   use_ok "MCE::Shared::Cache";
}

##
# Borrowed and adapted from Tie-Cache-LRU-20150301/t/LRU.t
#
# MCE::Shared::Cache is a hybrid cache, a LRU and plain implementation.
# A key retrieved from the bottom half follows LRU logic, thus key promotion.
# A key retrieved from the upper half has lesser-overhead, no promotion.
##

{
   # testing non-shared cache
   my $cache = MCE::Shared::Cache->new( max_keys => 5 );
   ok(defined $cache, "new");

   $cache->set("foo", "bar");
   is($cache->get("foo"), "bar", "basic store & fetch");
   ok($cache->exists("foo"), "basic exists");

   $cache->set("bar", "yar");
   $cache->set("car", "jar");
   # should be foo, bar, car

   my @test_order = qw(car bar foo);
   my @keys = $cache->keys;
   is_deeply(\@test_order, \@keys, "basic keys");

   # try a key reordering
   my $foo = $cache->get("foo");
   # should be bar, car, foo

   @test_order = qw(foo car bar);
   @keys = $cache->keys;
   is_deeply(\@test_order, \@keys, "basic promote");

   # try the culling
   $cache->set("har", "mar");
   $cache->set("bing", "bong");
   $cache->set("zip", "zap");
   # should be zip, bing, har, bar, car

   @test_order = qw(zip bing har foo car);
   @keys = $cache->keys;
   is_deeply(\@test_order, \@keys, "basic cull");

   # try deleting from the end
   $cache->del("car");
   is_deeply([ qw(zip bing har foo) ], [ $cache->keys ], "end delete");

   # try from the front
   $cache->del("zip");
   is_deeply([ qw(bing har foo) ], [ $cache->keys ], "front delete");

   # try in the middle
   $cache->del("har");
   is_deeply([ qw(bing foo) ], [ $cache->keys ], "middle delete");

   # add a bunch of stuff and make sure the index doesn't grow
   $cache->mset( qw(1 11 2 12 3 13 4 14 5 15 6 16 7 17 8 18 9 19 10 20) );
   is( keys %{ $cache->[2] }, 5, "index doesn't grow" );

   # test accessing the sizes
   is( $cache->len, 5, "len()" );
   is( $cache->max_keys,  5, "max_keys()"  );

   # test lowering the max_keys
   $cache->max_keys(2);
   is( $cache->len, 2, "len() after lowering max size" );
   is( $cache->keys,      2, "keys()      after lowering max size" );
   is_deeply( [ qw(10 9) ], [ $cache->keys ] );

   # test raising max_keys
   $cache->max_keys(10);
   is( $cache->len, 2, "len() after raising max size" );

   for my $num (21..28) { $cache->set($num, "somewhere over the rainbow: $num") }
   is( $cache->len, 10, "len() after adding stuff" );
   is_deeply( [ qw(28 27 26 25 24 23 22 21 10 9) ], [ $cache->keys ] );

   $cache->clear;
   is( $cache->len,  0, "len() after clear" );
   is( $cache->keys,       0, "keys()      after clear" );
   is( $cache->vals,       0, "vals()      after clear" );
   is( $cache->max_keys,  10, "max_keys()  after clear" );

   # make sure an empty cache will work
   my $null_cache = MCE::Shared::Cache->new( max_keys => 0 );
   ok(defined $null_cache, "new() null cache");

   $null_cache->set("foo", "bar");
   ok(!$null_cache->exists("foo"), "basic null cache exists()" );
   is( $null_cache->len, 0,  "len() null cache" );
   is( $null_cache->keys,      0,  "keys()      null cache" );
   is( $null_cache->vals,      0,  "values()    null cache" );
   is( $null_cache->max_keys,  0,  "max_keys()  null cache" );
}

{
   # testing shared cache
   my $cache = MCE::Shared->cache( max_keys => 5, max_age => 2 );
   ok(defined $cache, "new");

   $cache->set("foo", "bar");
   $cache->set("car", "baz");
   $cache->set("cnt", 0);

   is($cache->peek("foo"), "bar", "peek foo");
   is($cache->peek("car"), "baz", "peek car");
   is_deeply( [ qw(cnt 0 car baz foo bar) ], [ $cache->pairs ] );

   is($cache->get("foo"), "bar", "fetch foo");
   is($cache->get("car"), "baz", "fetch car");
   is_deeply( [ qw(car baz foo bar cnt 0) ], [ $cache->pairs ] );

   $cache->incr("cnt") for 1 .. 4;
   $cache->incrby("cnt", 5);
   is($cache->get("cnt"), 9, "fetch cnt");

   sleep 3;
   ok(!$cache->exists("foo"), "expired foo");
   ok(!$cache->get("car"),    "expired car");

   # test raising max_age
   $cache->max_age(10);

   $cache->incr("cnt");
   is($cache->get("cnt"), 1, "cnt inserted & incremented");

   sleep 3;
   is($cache->len, 1, "len() after raising max age");
}

done_testing;

