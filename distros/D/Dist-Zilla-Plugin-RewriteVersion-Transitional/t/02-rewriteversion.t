use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

delete $ENV{RELEASE_STATUS};
delete $ENV{TRIAL};
delete $ENV{V};

# version 0.010 adds "from Foo-Bar-0.001.tar.gz" comments unconditionally;
# version 0.011 disables that behaviour by default
use Dist::Zilla::Plugin::RewriteVersion;
plan skip_all => 'These tests break with Dist::Zilla::Plugin::RewriteVersion 0.010'
    if eval { Dist::Zilla::Plugin::RewriteVersion->VERSION('0.010'); 1 }
        and not eval { Dist::Zilla::Plugin::RewriteVersion->VERSION('0.011'); 1 };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                { # configs as in simple_ini, but no version assignment
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'RewriteVersion::Transitional' => {
                        fallback_version_provider => 'not used',
                    },
                ],
                [ FakeRelease => ],
                [ 'BumpVersionAfterRelease::Transitional' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n\nour \$VERSION = '0.002';\n\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'build and release proceeds normally',
);

is(
    $tzil->version,
    '0.002',
    'version was properly extracted from .pm file',
);

is(
    path($tzil->tempdir, qw(build lib Foo.pm))->slurp_utf8,
    "package Foo;\n\nour \$VERSION = '0.002';\n\n1;\n",
    '.pm contents in build are left unchanged',
);

is(
    path($tzil->tempdir, qw(source lib Foo.pm))->slurp_utf8,
    "package Foo;\n\nour \$VERSION = '0.003';\n\n1;\n",
    '.pm contents in source saw the version incremented',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::RewriteVersion::Transitional',
                    config => superhashof({
                        'Dist::Zilla::Plugin::RewriteVersion::Transitional' => {
                        },
                        #'Dist::Zilla::Plugin::RewriteVersion' => {
                        #    global => bool(0),
                        #    skip_version_provider => bool(0),
                        #},
                    }),
                    name => 'RewriteVersion::Transitional',
                    version => Dist::Zilla::Plugin::RewriteVersion::Transitional->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional',
                    config => superhashof({
                        'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional' => {
                        },
                        #'Dist::Zilla::Plugin::BumpVersionAfterRelease' => {
                        #    global => bool(0),
                        #    munge_makefile_pl => bool(0),
                        #},
                    }),
                    name => 'BumpVersionAfterRelease::Transitional',
                    version => Dist::Zilla::Plugin::RewriteVersion::Transitional->VERSION,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
