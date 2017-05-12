use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Module::Metadata;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ EnsurePrereqsInstalled => ],
                [ Prereqs => 'RuntimeConflicts' => { 'Test::More' => '<= 200.0' },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);

like(
    exception { $tzil->build },
    qr/^\Q[EnsurePrereqsInstalled] Conflicts found\E/m,
    'build aborted',
);

# allow for dev releases - Module::Metadata includes _, but $VERSION does not.
my $TM_VERSION = Module::Metadata->new_from_module('Test::More')->version;

my $re;
cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[EnsurePrereqsInstalled] checking that all authordeps are satisfied...',
        '[EnsurePrereqsInstalled] checking that all prereqs are satisfied...',
        re(do { $re = qr/^\Q[EnsurePrereqsInstalled] Conflicts found:
[EnsurePrereqsInstalled]     Installed version (\E$TM_VERSION\Q) of Test::More is in range '<= 200.0'
[EnsurePrereqsInstalled] To remedy, do:  pm-uninstall Test::More\E$/ms }),
    ),
    'build was aborted: conflict prereqs were checked',
) or diag 'got log messages: ', explain $tzil->log_messages,
    'expected: ', $re;

done_testing;
