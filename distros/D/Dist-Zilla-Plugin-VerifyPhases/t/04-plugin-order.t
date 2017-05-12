use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ VerifyPhases => ],
                    [ MetaConfig => ],
                    [ Prereqs => ],
                ),
            },
        },
    );

    cmp_deeply(
        [ grep { !/^:/ } map { $_->plugin_name } @{ $tzil->plugins } ],
        [ qw(GatherDir VerifyPhases MetaConfig Prereqs) ],
        'plugin order is as loaded, before the build is executed',
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        [ grep { !/^:/ } map { $_->plugin_name } @{ $tzil->plugins } ],
        [ qw(GatherDir MetaConfig Prereqs VerifyPhases)  ],
        'after the build, [VerifyPhases] is last',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
