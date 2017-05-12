use strict;
use warnings FATAL => qw(all);

use Test::More tests => 1;

my $class = qw(Devel::Profiler::Plugins::Template::Context);

use_ok($class);
