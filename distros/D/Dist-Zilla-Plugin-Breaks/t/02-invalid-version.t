use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny;
use Test::Fatal;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 't/corpus/dist/DZT' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Breaks => { 'Foo::Bar' => 'abcd' }
                ],
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr/Invalid version format/,
    'bad version specifications are caught',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
