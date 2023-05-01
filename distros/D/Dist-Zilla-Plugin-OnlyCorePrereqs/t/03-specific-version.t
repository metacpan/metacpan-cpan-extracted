use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Module::CoreList;
use Path::Tiny;

$TODO = 'Module::CoreList does not have information about this perl version of ' . $]
    if not exists $Module::CoreList::version{$]};

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
                    [ Prereqs => RuntimeRequires => { 'HTTP::Tiny' => '0.025' } ],
                    [ OnlyCorePrereqs => { starting_version => '5.014' } ],
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

    cmp_deeply(
        $tzil->log_messages,
        supersetof('[OnlyCorePrereqs] detected a runtime requires dependency on HTTP::Tiny 0.025: perl 5.014 only has 0.012'),
        'HTTP::Tiny was in core in 5.014, but only at version 0.012 - check fails',
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
                                starting_version => '5.014',
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
                    [ Prereqs => RuntimeRequires => { 'feature' => '500.0' } ],
                    [ OnlyCorePrereqs => { starting_version => 'current' } ],
                ),
            },
        },
    );

    # version 500.0 does not exist in any known version of perl.
    # feature is not dual-lifed, so we know the user hasn't upgraded.

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\Q[OnlyCorePrereqs] aborting\E/,
        'build aborted'
    );

    # this dist requires 5.010, so we know feature is available at *some*
    # version (it first appeared in 5.9.3)

    cmp_deeply(
        $tzil->log_messages,
        supersetof(re(qr/\Q[OnlyCorePrereqs] detected a runtime requires dependency on feature 500.0: perl $] only has \E\d\.\d+/)),
        'version of perl is too old for feature 500.0 - check fails',
    ) or do {
        diag 'saw log messages: ', explain $tzil->log_messages;
        diag('corelist data for feature at version ' . $] . ': ',
            (exists $Module::CoreList::version{$]} ? $Module::CoreList::version{$]}{feature} : 0));
    };

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
                                starting_version => $],
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

SKIP:
{
    # Carp is dual-lifed, and was upgraded to 1.30 in 5.019000 -> 5.019001
    # The version of Module::CoreList that covers this change is 2.93
    skip 'this test requires a very recent Module::CoreList', 1
        unless Module::CoreList->VERSION ge '2.93';

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MetaConfig => ],
                    [ Prereqs => RuntimeRequires => { 'Carp' => '1.30' } ],
                    [ OnlyCorePrereqs => { starting_version => 'latest' } ],
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
        (!grep /\[OnlyCorePrereqs\]/, grep !/\[OnlyCorePrereqs\] checking /, @{$tzil->log_messages}),
        'Carp is new enough in 5.019001 - check succeeds',
    )
    or diag 'saw log messages: ', explain $tzil->log_messages;

    my ($latest_version) = reverse sort keys %Module::CoreList::released;

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
                                starting_version => $latest_version,
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
                    [ Prereqs => RuntimeRequires => { 'File::stat' => '0' } ],
                    [ OnlyCorePrereqs => ],
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

    ok(
        (!grep /\[OnlyCorePrereqs\]/, grep !/\[OnlyCorePrereqs\] checking /, @{$tzil->log_messages}),
        'File::stat is undef in 5.005, but good enough - check succeeds',
    )
    or diag 'saw log messages: ', explain $tzil->log_messages;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
