use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

use Test::Needs { 'Dist::Zilla::Plugin::MakeMaker' => '5.022' };

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ DualLife  => ],
                ),
                path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/^\[DualLife\] this module is not dual-life!/,
        'build fails if the module is not dual-life',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ DualLife  => { eumm_bundled => 1 } ],
                ),
                path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'eumm_bundled build proceeds normally, even though module is not in core',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
