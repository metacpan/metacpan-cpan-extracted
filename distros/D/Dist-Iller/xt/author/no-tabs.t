use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Iller.pm',
    'lib/Dist/Iller/Config.pm',
    'lib/Dist/Iller/DocType.pm',
    'lib/Dist/Iller/DocType/Cpanfile.pm',
    'lib/Dist/Iller/DocType/Dist.pm',
    'lib/Dist/Iller/DocType/Gitignore.pm',
    'lib/Dist/Iller/DocType/Global.pm',
    'lib/Dist/Iller/DocType/Weaver.pm',
    'lib/Dist/Iller/Elk.pm',
    'lib/Dist/Iller/Plugin.pm',
    'lib/Dist/Iller/Prereq.pm',
    'lib/Dist/Iller/Role/HasPlugins.pm',
    'lib/Dist/Iller/Role/HasPrereqs.pm',
    'lib/Dist/Zilla/MintingProfile/DistIller/Basic.pm',
    'lib/Dist/Zilla/Plugin/DistIller/MetaGeneratedBy.pm',
    'script/iller',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02-builder.t',
    't/03-config.t',
    't/corpus/02-builder.yaml',
    't/corpus/03-config-config.yaml',
    't/corpus/03-config-iller.yaml',
    't/corpus/lib/Dist/Iller/Config/DistIllerTestConfig.pm'
);

notabs_ok($_) foreach @files;
done_testing;
