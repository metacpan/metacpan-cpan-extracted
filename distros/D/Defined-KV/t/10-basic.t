#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use Defined::KV;

is_deeply([defined_kv foo => undef], [],           "undef value yields nothing");
is_deeply([defined_kv bar => 1],     [ bar => 1 ], "defined value yields kv pair");
is_deeply([defined_kv baz => 0],     [ baz => 0 ], "false value yields kv pair");

done_testing;
