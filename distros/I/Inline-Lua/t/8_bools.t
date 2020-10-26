#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

use Inline 'Lua';

my $true = return_true();
my $false = return_false();

isa_ok($true, 'Inline::Lua::Boolean', 'Lua booleans are marshaled into Perl as Inline::Lua::Boolean');
isa_ok($false, 'Inline::Lua::Boolean', 'Lua booleans are marshaled into Perl as Inline::Lua::Boolean');

ok($true, 'Lua true is truthy');
ok(!$false, 'Lua false is falsey');

__DATA__
__Lua__

function return_true()
  return true
end

function return_false()
  return false
end
