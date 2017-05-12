#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use Inline 'Lua';

use Test::More;

plan tests => 2;

my @results = call_me(sub {
    lua_rand(@_);
}, 'foo');

is scalar(@results), 1, 'there should only be one result';
is $results[0], 18, '...and its value should be equal to the return value of lua_rand';

__DATA__
__Lua__
function lua_rand()
  return 18
end

function call_me(fn, ...)
  return fn(...)
end
