use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/JSON/RPC/LWP.pm',
    't/agent.t',
    't/agent_subclass.t',
    't/init.t',
    't/lazy.t',
    't/lib/Util.pm',
    't/load.t'
);

notabs_ok($_) foreach @files;
done_testing;
