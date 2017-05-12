use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use Test::Deep;
use Term::ANSIColor 2.01 'colorstrip';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ BlockRelease => ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

like(
    colorstrip(exception { $tzil->release }),
    qr{\[BlockRelease\] halting release},
    'release halts',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof('[BlockRelease] releases will be prevented!'),
    'got a warning about releases being prevented',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
