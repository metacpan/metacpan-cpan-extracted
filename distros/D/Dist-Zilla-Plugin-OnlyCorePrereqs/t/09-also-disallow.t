use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ MetaConfig => ],
                [ Prereqs => RuntimeRequires => {
                        'perl' => '5.008',
                        'Scalar::Util' => 0,
                    }
                ],
                [ OnlyCorePrereqs => { also_disallow => [ 'Scalar::Util' ] } ],
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
                            also_disallow => [ 'Scalar::Util' ],
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

cmp_deeply(
    $tzil->log_messages,
    supersetof('[OnlyCorePrereqs] detected a runtime requires dependency that is explicitly disallowed: Scalar::Util'),
    'Scalar::Util is in core, but disallowed',
) or diag 'saw log messages: ', explain $tzil->log_messages;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
