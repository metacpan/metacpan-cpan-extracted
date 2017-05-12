use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

local $TODO = 'CPAN::Meta::Prereqs does not yet support adding x_ keys to types or phases';

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ EnsurePrereqsInstalled => ],
                [ Prereqs => 'custom phase' => {
                        -relationship => 'requires',
                        -phase => 'x_ether',
                        'I::Am::Not::Installed' => 0,
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);

like(
    exception { $tzil->build },
    qr/^\Q[EnsurePrereqsInstalled] Unsatisfied\E/m,
    'build aborted',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[EnsurePrereqsInstalled] checking that all authordeps are satisfied...',
        '[EnsurePrereqsInstalled] checking that all prereqs are satisfied...',
        "[EnsurePrereqsInstalled] Unsatisfied prerequisites:
[EnsurePrereqsInstalled]     Module 'I::Am::Not::Installed' is not installed
[EnsurePrereqsInstalled] To remedy, do:  cpanm I::Am::Not::Installed",
    ),
    'build was aborted: custom x_* prereq phases are checked',
) or diag 'got log messages: ', explain $tzil->log_messages;

done_testing;
