#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

use Carp;
use Data::Dump qw( dump );
use File::Temp 'tempfile';

use_ok('Dezi::Bot::Cache');

ok( my $cache = Dezi::Bot::Cache->new(), "new cache" );
ok( $cache->add( foo => 'bar' ), "add()" );
ok( $cache->has('foo'), "has()" );
is( $cache->get('foo'),    'bar', "get()" );
is( $cache->delete('foo'), 1,     "delete()" );
ok( !$cache->has('foo'), "!has() after delete()" );
