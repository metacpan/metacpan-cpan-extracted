use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Module::CoreList;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => { Switch => 0 } ],
                    [ OnlyCorePrereqs => { starting_version => '5.012' } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\Q[OnlyCorePrereqs] aborting\E/,
        'build aborted'
    );

    $TODO = 'Module::CoreList does not have information about this perl version of ' . $]
        if not exists $Module::CoreList::version{$]};

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[OnlyCorePrereqs] detected a runtime requires dependency that was deprecated from core in 5.011: Switch'),
        'Switch has been deprecated',
    )
    or diag 'saw log messages: ', explain $tzil->log_messages;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.012',
                                deprecated_ok => 0,
                                check_dual_life_versions => 1,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => { Switch => 0 } ],
                    [ OnlyCorePrereqs => { starting_version => '5.012', deprecated_ok => 1 } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build is not aborted',
    );

    ok(
        (!grep { /\[OnlyCorePrereqs\]/ } grep { !/\[OnlyCorePrereqs\] checking / } @{$tzil->log_messages}),
        'Switch has been deprecated, but that\'s ok!',
    )
    or diag 'saw log messages: ', explain $tzil->log_messages;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::OnlyCorePrereqs',
                        config => {
                            'Dist::Zilla::Plugin::OnlyCorePrereqs' => {
                                skips => [],
                                also_disallow => [],
                                phases => bag('configure', 'build', 'runtime', 'test'),
                                starting_version => '5.012',
                                deprecated_ok => 1,
                                check_dual_life_versions => 1,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => ignore,
                    },
                ),
            })
        }),
        'config is properly included in metadata',
    ) or diag 'got dist metadata: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
