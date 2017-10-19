#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Defined::KV');

local $Defined::KV::VERSION = $Defined::KV::VERSION || 'from repo';
note("Defined::KV $Defined::KV::VERSION, Perl $], $^X");
