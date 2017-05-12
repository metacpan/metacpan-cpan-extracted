use Test::More tests => 2;
BEGIN { use_ok('Devel::GC::Helper') };
use strict;
use warnings;

Devel::GC::Helper::sweep;

ok(1);

