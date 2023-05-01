use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Test::Deep;
use Module::CoreList;

# diag uses todo_output if in_todo :/
no warnings 'redefine';
*::diag = sub {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tb = Test::Builder->new;
    $tb->_print_comment($tb->failure_output, @_);
};

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { Moose => 0 } ],
                    [ OnlyCorePrereqs => ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\Q[OnlyCorePrereqs] aborting build due to invalid dependencies\E/,
        'build aborted',
    );

    $TODO = 'Module::CoreList does not have information about this perl version of ' . $]
        if not exists $Module::CoreList::version{$]};

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[OnlyCorePrereqs] detected a runtime requires dependency that is not in core: Moose'),
        'Moose is not in core - check fails',
    ) or diag 'saw log messages: ', explain $tzil->log_messages;

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
                                starting_version => 'to be determined from perl prereq',
                                deprecated_ok => 0,
                                check_dual_life_versions => 1,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => Dist::Zilla::Plugin::OnlyCorePrereqs->VERSION,
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
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { parent => 0 } ],
                    [ OnlyCorePrereqs => { starting_version => '5.010' } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\Q[OnlyCorePrereqs] aborting build due to invalid dependencies\E/,
        'build aborted'
    );

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[OnlyCorePrereqs] detected a runtime requires dependency that was not added to core until 5.010001: parent'),
        'parent was not in core in 5.10 - check fails',
    ) or diag 'saw log messages: ', explain $tzil->log_messages;

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
                                starting_version => '5.010',
                                deprecated_ok => 0,
                                check_dual_life_versions => 1,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => Dist::Zilla::Plugin::OnlyCorePrereqs->VERSION,
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
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => { perl => '5.010' } ],
                    [ Prereqs => TestRequires => { parent => 0 } ],
                    [ OnlyCorePrereqs => { starting_version => '5.010', phase => [ 'runtime' ] } ],
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
        (!grep /\[OnlyCorePrereqs\]/, @{$tzil->log_messages}),
        'non-core modules are permitted in the test phase',
    ) or diag 'saw log messages: ', explain $tzil->log_messages;

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
                                phases => [ 'runtime' ],
                                starting_version => '5.010',
                                deprecated_ok => 0,
                                check_dual_life_versions => 1,
                            },
                        },
                        name => 'OnlyCorePrereqs',
                        version => Dist::Zilla::Plugin::OnlyCorePrereqs->VERSION,
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
