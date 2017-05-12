use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

# Instead of using [ModuleBuildTiny] to set x_static_install, we set the
# x_static_install flag directly using a simple plugin.

use lib 't/lib';

my @tests = (
    {
        x_static_install => 0,
        mode => 'off',
    },
    {
        x_static_install => 0,
        mode => 'auto',
    },
    {
        x_static_install => 1,
        mode => 'on',
    },
    {
        x_static_install => 1,
        mode => 'auto',
    },
);

subtest "preset x_static_install = input of $_->{x_static_install}, passed StaticInstall.mode = $_->{mode}" => sub
{
    my $config = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    # the lack of META.json will disqualify us in our plugin
                    $config->{x_static_install} ? [ MetaJSON => ] : (),
                    [ '=SimpleFlagSetter' => { value => $config->{x_static_install} } ],
                    [ 'MakeMaker' ],
                    [ 'StaticInstall' => { mode => $config->{mode} } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_static_install => $config->{x_static_install},
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::StaticInstall',
                        config => {
                            'Dist::Zilla::Plugin::StaticInstall' => {
                                mode => $config->{mode},
                                dry_run => 0,
                            },
                        },
                        name => 'StaticInstall',
                        version => Dist::Zilla::Plugin::StaticInstall->VERSION,
                    },
                ),
            }),
        }),
        'plugin metadata indicates ' . ($config->{x_static_install} ? '' : 'this is NOT '). 'a static install',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
