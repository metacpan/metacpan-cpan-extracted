use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

# protect from external environment
local $ENV{TRIAL};
local $ENV{RELEASE_STATUS};

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'Run::BeforeBuild' => {
                    fatal_errors => 0,
                    eval => [ "\$self" ],
                  },
                ],
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

cmp_deeply(
    [ grep /^\[Run::[^]]+\]/, @{ $tzil->log_messages } ],
    [
        '[Run::BeforeBuild] evaluating: $self',
        re(qr/^\[Run::BeforeBuild\] evaluation died: Global symbol "\$self" requires explicit package name/),
    ],
    '$self is inaccessable to eval code',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
