use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
require Dist::Zilla::Plugin::MakeMaker;

plan skip_all => 'This test requires an older [MakeMaker]'
    if eval { Dist::Zilla::Plugin::MakeMaker->VERSION('5.022'); 1 };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ DualLife  => { entered_core => '5.010001' } ],
                [ MakeMaker => ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr/^\Q[DualLife] No Makefile.PL found! Is [MakeMaker] at least version 5.022?\E/,
    'build fails - Makefile.PL content not present yet',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
