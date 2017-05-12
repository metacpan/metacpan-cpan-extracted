use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'Changes',
    'GPLv3',
    'VERSION',
    'eg/AdaptiveTestVersion/README.pod',
    'eg/AdaptiveTestVersion/dist.ini',
    'eg/Description/README.pod',
    'eg/Description/dist.ini',
    'eg/TemplateVariables/BUGS.pod',
    'eg/TemplateVariables/README.pod',
    'eg/TemplateVariables/dist.ini',
    'eg/UnwantedDependencies/README.pod',
    'eg/UnwantedDependencies/dist.ini',
    'eg/VersionHandling/README.pod',
    'eg/VersionHandling/VERSION',
    'eg/VersionHandling/dist.ini',
    'lib/Dist/Zilla/Plugin/Hook.pm',
    'lib/Dist/Zilla/Plugin/Hook/Manual.pod',
    'lib/Dist/Zilla/Role/Hooker.pm',
    't/hook.t',
    't/lib/HookTester.pm',
    'xt/aspell-en.pws',
    'xt/examples.t',
    'xt/perlcritic.ini'
);

notabs_ok($_) foreach @files;
done_testing;
