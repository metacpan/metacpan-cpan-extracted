use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ MakeMaker => ],
                [ MetaJSON => ],
                [ 'StaticInstall' => { mode => 'off' } ],
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
    $tzil->distmeta,
    superhashof({
        x_static_install => 0,
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::StaticInstall',
                    config => {
                        'Dist::Zilla::Plugin::StaticInstall' => {
                            mode => 'off',
                            dry_run => 0,
                        },
                    },
                    name => 'StaticInstall',
                    version => Dist::Zilla::Plugin::StaticInstall->VERSION,
                },
            ),
        }),
    }),
    'x_static_install is still 0 even though the distribution is eligible for static install',
) or diag 'got distmeta: ', explain $tzil->distmeta;

cmp_deeply(
    [ map { colorstrip($_) } @{ $tzil->log_messages } ],
    supersetof(map { '[StaticInstall] ' . $_ }
        'checking dynamic_config',
        'checking configure prereqs',
        'checking build prereqs',
        'checking sharedirs',
        'checking installer plugins',
        'checking for munging of Makefile.PL',
        'checking META.json',
        'checking META.json',
        'checking for .xs files',
        'checking .pm, .pod, .pl files',
        'setting x_static_install to 0',
        'would set x_static_install to 1',
    ),
    'appropriate logging for distribution that is eligible for static installation but the author is opting out',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
