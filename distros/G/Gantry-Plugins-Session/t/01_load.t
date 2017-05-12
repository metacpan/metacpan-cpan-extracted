use strict;
use Test::More ;

my @modules = qw(Gantry::Plugins::Session);

plan(tests => scalar(@modules));

use_ok($_) for @modules;
