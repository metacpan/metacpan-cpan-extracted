use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                'Readme',
                'License',
                'FakeRelease',
                [ CopyFilesFromRelease => {
                        filename => 'LICENSE',
                        match => '^READ',
                    }
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\nour \$VERSION = '0.001';\n1",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'release proceeds normally',
);

my $build_license = path($tzil->tempdir)->child(qw(source LICENSE));
ok(-f $build_license, 'LICENSE now exists in the source directory');

is(
    $build_license->slurp_utf8,
    path($tzil->tempdir)->child(qw(build LICENSE))->slurp_utf8,
    'LICENSE content is identical to the build directory',
);

my $build_readme = path($tzil->tempdir)->child(qw(source README));
ok(-f $build_readme, 'README now exists in the source directory');

is(
    $build_readme->slurp_utf8,
    path($tzil->tempdir)->child(qw(build README))->slurp_utf8,
    'README content is identical to the build directory',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
