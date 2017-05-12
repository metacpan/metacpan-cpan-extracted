use strict;
use warnings;

use Test::More;
use Linux::CPUAffinity;

eval 'use Test::LeakTrace 0.08';
plan skip_all => "Test::LeakTrace 0.08 required for testing leak trace" if $@;

plan tests => 1;

no_leaks_ok(sub {
    Linux::CPUAffinity->get(0);
    Linux::CPUAffinity->set(0, [0]);
    Linux::CPUAffinity->num_processors();
});
