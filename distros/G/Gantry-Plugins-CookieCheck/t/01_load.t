use strict;
use Test::More ;

my @modules = qw(Gantry::Plugins::CookieCheck);

plan(tests => scalar(@modules));

use_ok($_) for @modules;
