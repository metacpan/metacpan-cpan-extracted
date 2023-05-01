use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use Path::Tiny;
use Test::Deep;
use Test::Fatal;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Run::BeforeBuild' => { run => [ qq{"$^X" -le"exit 42"} ] } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/command exited with status 42 \(10752\)/,
        'build failed, reporting the error from the run command',
    );

    cmp_deeply(
        [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
        [
            qq{[Run::BeforeBuild] executing: "$^X" -le"exit 42"},
            '[Run::BeforeBuild] command exited with status 42 (10752)',
        ],
        'log messages list what happened',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ qq{"$^X" -le"exit 42"} ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeBuild',
                        version => Dist::Zilla::Plugin::Run::BeforeBuild->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs include fatal_errors default',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ FakeRelease => ],
                    [ 'Run::BeforeBuild' => { eval => [ 'die "oh noes"' ] } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/evaluation died: oh noes/,
        'build failed, reporting the error from the eval command',
    );

    cmp_deeply(
        $tzil->log_messages,
        [
            '[Run::BeforeBuild] evaluating: die "oh noes"',
            re(qr/^\[Run::BeforeBuild\] evaluation died: oh noes/),
        ],
        'log messages list what happened',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                eval => [ 'die "oh noes"' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeBuild',
                        version => Dist::Zilla::Plugin::Run::BeforeBuild->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs include fatal_errors default',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Run::BeforeBuild' => { run => [ qq{"$^X" -le"exit 42"} ], fatal_errors => 0, } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build succeeded, despite the run command failing',
    );

    cmp_deeply(
        [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
        [
            qq{[Run::BeforeBuild] executing: "$^X" -le"exit 42"},
            '[Run::BeforeBuild] command exited with status 42 (10752)',
        ],
        'log messages list what happened',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ qq{"$^X" -le"exit 42"} ],
                                fatal_errors => 0,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeBuild',
                        version => Dist::Zilla::Plugin::Run::BeforeBuild->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs include fatal_errors override',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ FakeRelease => ],
                    [ 'Run::BeforeBuild' => { eval => [ 'die "oh noes"' ], fatal_errors => 0, } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build succeeded, despite the eval command failing',
    );

    cmp_deeply(
        [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
        [
            '[Run::BeforeBuild] evaluating: die "oh noes"',
            re(qr/^\[Run::BeforeBuild\] evaluation died: oh noes/),
        ],
        'log messages list what happened',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                eval => [ 'die "oh noes"' ],
                                fatal_errors => 0,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeBuild',
                        version => Dist::Zilla::Plugin::Run::BeforeBuild->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs include fatal_errors override',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
