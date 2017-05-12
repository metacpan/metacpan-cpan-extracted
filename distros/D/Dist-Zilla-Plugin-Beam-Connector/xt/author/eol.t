use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'examples/neo-makemaker/beam.yml',
    'examples/neo-makemaker/dist.ini',
    'examples/neo-makemaker/inc/My/NeoDynDeps.pm',
    'examples/neo-makemaker/inc/My/NeoDynDepsLite.pm',
    'examples/neo-makemaker/inc/My/NeoMakeMaker.pm',
    'examples/neo-makemaker/lib/Example/NeoMaker.pm',
    'lib/Dist/Zilla/Plugin/Beam/Connector.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_Beam_Connector_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/example/neomake.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
