use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/graph-meta.pl',
    'lib/Meta/Grapher/Moose.pm',
    'lib/Meta/Grapher/Moose/CommandLine.pm',
    'lib/Meta/Grapher/Moose/Constants.pm',
    'lib/Meta/Grapher/Moose/Renderer/Graphviz.pm',
    'lib/Meta/Grapher/Moose/Renderer/Plantuml.pm',
    'lib/Meta/Grapher/Moose/Renderer/Plantuml/Class.pm',
    'lib/Meta/Grapher/Moose/Renderer/Plantuml/Link.pm',
    'lib/Meta/Grapher/Moose/Role/HasOutput.pm',
    'lib/Meta/Grapher/Moose/Role/Renderer.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/example.t',
    't/lib/Meta/Grapher/Moose/Renderer/Test.pm',
    't/lib/My/Example/Baseclass.pm',
    't/lib/My/Example/Class.pm',
    't/lib/My/Example/Role/Buffy.pm',
    't/lib/My/Example/Role/Flintstones.pm',
    't/lib/My/Example/Role/JackBlack.pm',
    't/lib/My/Example/Role/Katniss.pm',
    't/lib/My/Example/Role/PickRandom.pm',
    't/lib/My/Example/Role/RandomValue.pm',
    't/lib/My/Example/Role/ShedColor.pm',
    't/lib/My/Example/Role/StarTrek.pm',
    't/lib/My/Example/Role/TVSeries.pm',
    't/lib/My/Example/Role/Tribute.pm',
    't/lib/My/Example/Superclass.pm',
    't/lib/Test/Meta/Grapher/Moose.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
