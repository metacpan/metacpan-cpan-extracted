#! /usr/bin/env perl

use 5.022;
use warnings;
use lib './demo/lib';
use Nested;
use Test::More;

say do{{{ ok 1, 'unnested' }}};
say do{{{ ok 2, do {{{ 'nested' }}} }}};

done_testing();
