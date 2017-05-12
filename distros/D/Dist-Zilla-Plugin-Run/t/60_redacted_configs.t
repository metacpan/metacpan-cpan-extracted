use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Run::AfterRelease' => { run => 'echo hello world', censor_commands => 1 } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::AfterRelease',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ 'REDACTED' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::AfterRelease',
                        version => Dist::Zilla::Plugin::Run::AfterRelease->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs censor all commands on request',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $username = 'ETHER';
    my $password = 'sekritpassword';

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Run::AfterRelease' => 'install release' => {
                            run => [
                                'cpanm http://' . $username . ':' . $password . '@pause.perl.org/pub/PAUSE/authors/id/E/ET/ETHER/%a',
                                'echo hello world',
                            ],
                      } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::AfterRelease',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [
                                    'REDACTED',
                                    'echo hello world',
                                ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'install release',
                        version => Dist::Zilla::Plugin::Run::AfterRelease->VERSION,
                    },
                ),
            }),
        }),
        'censored the config that contains my password; other commands shown as normal',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
