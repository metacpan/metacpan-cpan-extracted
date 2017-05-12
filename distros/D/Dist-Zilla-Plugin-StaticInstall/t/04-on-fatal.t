use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ MakeMaker => ],
                # no MetaJSON!
                [ 'StaticInstall' => { mode => 'on' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr/\[StaticInstall\] mode = on but this distribution is ineligible: META.json is not being added to the distribution/,
    'build fails appropriately',
);

cmp_deeply(
    $tzil->log_messages,
    supersetof(map { '[StaticInstall] ' . $_ }
        'checking dynamic_config',
        'checking configure prereqs',
        'checking build prereqs',
        'checking sharedirs',
        'checking installer plugins',
        'checking for munging of Makefile.PL',
        'checking META.json',
        'mode = on but this distribution is ineligible: META.json is not being added to the distribution',
    ),
    'appropriate logging for static distribution',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
