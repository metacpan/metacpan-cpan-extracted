#!/usr/bin/env perl

use warnings;
use strict;
use Test::More tests => 4;

use_ok('Devel::Module::Trace');


eval("use POSIX;");
ok($INC{'POSIX.pm'}, 'POSIX module loaded');

my $raw = Devel::Module::Trace::raw_result();

Devel::Module::Trace::_disable();
eval("use Benchmark;");
ok($INC{'Benchmark.pm'}, 'Benchmark module loaded');

# did we catch the POSIX module
my $found = 0;
for my $mod (@{$raw}) {
    if($mod->{'name'} eq 'POSIX.pm') { $found++ }
}
is($found, 1, 'result contains POSIX');

