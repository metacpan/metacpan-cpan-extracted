#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 1;

require_ok('HTTP::Tiny::SPDY');

local $HTTP::Tiny::SPDY::VERSION = $HTTP::Tiny::SPDY::VERSION || 'from repo';
note("HTTP::Tiny::SPDY $HTTP::Tiny::SPDY::VERSION, Perl $], $^X");

