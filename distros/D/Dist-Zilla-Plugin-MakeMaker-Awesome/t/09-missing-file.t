use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ 'PruneFiles' => { filename => 'Makefile.PL' } ],
                [ 'MakeMaker::Awesome' => { eumm_version => '6.01' } ],
            ),
            path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
        },
    },
);

$tzil->chrome->logger->set_debug(1);

like(
    exception { $tzil->build },
    qr/\Q[MakeMaker::Awesome] Makefile.PL has vanished from the distribution! Did you [PruneFiles] the file after it was gathered?\E/,
    'gave a helpful error when Makefile.PL was pruned',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
