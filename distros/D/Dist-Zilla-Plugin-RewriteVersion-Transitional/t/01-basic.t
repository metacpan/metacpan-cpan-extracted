use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

delete $ENV{RELEASE_STATUS};
delete $ENV{TRIAL};
delete $ENV{V};

my $captured_args;
{
    package inc::SimpleVersionProvider;
    use Moose;
    with 'Dist::Zilla::Role::VersionProvider';
    sub provide_version { '0.005' }
    sub BUILD { $captured_args = $_[1] }
    $INC{'inc/SimpleVersionProvider.pm'} = __FILE__;
}

for my $trial (0, 1)
{
    note "TRIAL=$trial";
    local $ENV{TRIAL} = $trial;

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
                            fallback_version_provider => '=inc::SimpleVersionProvider',
                            some_other_arg => 'oh hai',
                        },
                    ],
                    [ FakeRelease => ],
                    [ 'BumpVersionAfterRelease::Transitional' ],
                ),
                path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: stuff

1;
FOO
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
        '0.005',
        'fallback version provider was employed to get the version',
    );

    cmp_deeply(
        $captured_args,
        {
            zilla => shallow($tzil),
            plugin_name => 'fallback version provider, via [RewriteVersion::Transitional]',
            some_other_arg => 'oh hai',
        },
        'extra plugin arguments were passed along to the fallback version provider',
    );

    my $trial_str = $trial ? ' # TRIAL' : '';

    is(
        path($tzil->tempdir, qw(build lib Foo.pm))->slurp_utf8,
        "package Foo;\n# ABSTRACT: stuff\nour \$VERSION = '0.005';$trial_str\n1;\n",
        '$VERSION assignment was added to the build module, where [PkgVersion] would normally insert it',
    );

    my $source_file = path($tzil->tempdir, qw(source lib Foo.pm));
    is(
        $source_file->slurp_utf8,
        "package Foo;\n# ABSTRACT: stuff\nour \$VERSION = '0.006';\n1;\n",
        '.pm contents in source module saw the incremented version inserted',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            release_status => ($trial ? 'testing' : 'stable'),
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::RewriteVersion::Transitional',
                        config => superhashof({
                            'Dist::Zilla::Plugin::RewriteVersion::Transitional' => {
                                fallback_version_provider => '=inc::SimpleVersionProvider',
                                _fallback_version_provider_args => { some_other_arg => 'oh hai' },
                            },
                            # TODO, in [RewriteVersion]
                            #'Dist::Zilla::Plugin::RewriteVersion' => {
                            #    global => bool(0),
                            #    skip_version_provider => bool(0),
                            #},
                            '=inc::SimpleVersionProvider' => { },
                            'Dist::Zilla::Plugin::PkgVersion' => superhashof({}),
                        }),
                        name => 'RewriteVersion::Transitional',
                        version => Dist::Zilla::Plugin::RewriteVersion::Transitional->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional',
                        config => superhashof({
                            'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional' => {
                            },
                            # TODO, in [BumpVersionAfterRelease]
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

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            '[RewriteVersion::Transitional] inserted $VERSION statement into lib/Foo.pm',
            '[BumpVersionAfterRelease::Transitional] inserted $VERSION statement into ' . $source_file,
        ),
        'got appropriate log messages about inserting new $VERSION statements',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
