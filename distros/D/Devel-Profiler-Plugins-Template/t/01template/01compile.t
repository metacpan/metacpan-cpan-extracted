use strict;
use warnings FATAL => qw(all);

use Test::More tests => 1;

my $class = qw(Devel::Profiler::Plugins::Template);

use_ok($class);
