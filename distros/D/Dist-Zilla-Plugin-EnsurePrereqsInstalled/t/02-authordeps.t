use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

foreach my $build_phase (qw(build release))
{
    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ EnsurePrereqsInstalled => { build_phase => $build_phase } ],
                    [ FakeRelease => ],
                ) . "\n\n; authordep I::Am::Not::Installed\n",
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->$build_phase },
        qr/^\Q[EnsurePrereqsInstalled] Unsatisfied\E/m,
        $build_phase . ' aborted due to missing authordeps',
    );

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            '[EnsurePrereqsInstalled] checking that all authordeps are satisfied...',
            '[EnsurePrereqsInstalled] Unsatisfied authordeps:
[EnsurePrereqsInstalled] I::Am::Not::Installed
[EnsurePrereqsInstalled] To remedy, do:  cpanm I::Am::Not::Installed',
        ),
        $build_phase . ' was aborted: authordeps and all prerequisites were checked',
    ) or diag 'got log messages: ', explain $tzil->log_messages;
}

done_testing;
