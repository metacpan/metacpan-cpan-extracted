use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny;
use Test::Fatal;
use Test::Deep;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                'ModuleBuildTiny',
            ) . <<END_INI,
[MakeMaker::Fallback]
WriteMakefile_arg = CCFLAGS => '-Wall'
END_INI
            path(qw(source lib Foo.pm)) => "package Foo;\n\n1",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $content = $tzil->slurp_file('build/Makefile.PL');

like(
    $content,
    qr/^%WriteMakefileArgs = \(\n^    %WriteMakefileArgs,\n^    CCFLAGS => '-Wall',\n^\);\n/m,
    'mvp_alias for WriteMakefile_arg works properly',
);

done_testing;
