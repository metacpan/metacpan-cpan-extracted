#!perl -T

use Test::More;
use Math::Prime::TiedArray;

eval "use DB_File";
plan skip_all => "DB_File required for cache operations" if $@;
plan tests => 6;

my $cache = "cache.dbm";
unlink $cache;

ok((tie my @a, "Math::Prime::TiedArray", cache => $cache), "tied with cache");

ok(-f $cache, "Cache file was created");
is($a[99], 541, "100th prime is correct");
untie @a;

tie @a, "Math::Prime::TiedArray", cache => $cache, extend_ceiling => 10;
is($a[99], 541, "100th prime is correct (from cache)");
untie @a;

tie @a, "Math::Prime::TiedArray", cache => $cache;
is($a[199], 1223, "200th prime is correct (not cache)");
untie @a;

tie @a, "Math::Prime::TiedArray", cache => $cache, extend_ceiling => 10;
is($a[199], 1223, "200th prime is correct (from extended cache)");
untie @a;

unlink $cache;
