#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use Inline 'Lua';

throws_ok(sub {
    throw_a_fit();
}, qr/a fit/, 'Lua errors should propagate to Perl land');

my @values = return_something();

is_deeply \@values, [1], q{Lua errors shouldn't mess up the Lua stack};

__DATA__
__Lua__

function throw_a_fit()
  error 'a fit!'
end

function return_something()
  return 1
end
