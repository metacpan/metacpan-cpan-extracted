#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Hash::Key::Quote qw(should_quote_hash_key);

ok(!should_quote_hash_key('123'));
ok(!should_quote_hash_key('-123'));
ok(!should_quote_hash_key('foo'));
ok(!should_quote_hash_key('foo_bar'));
ok(!should_quote_hash_key('_'));
ok(!should_quote_hash_key('-foo'));

ok( should_quote_hash_key(''));
ok( should_quote_hash_key('-'));
ok( should_quote_hash_key('+'));
ok( should_quote_hash_key('+100'));
ok( should_quote_hash_key('012'));
ok( should_quote_hash_key('-012'));
ok( should_quote_hash_key('12_300'));
ok( should_quote_hash_key('123.1'));
ok( should_quote_hash_key('-123.1'));
ok( should_quote_hash_key('--foo'));

done_testing;
