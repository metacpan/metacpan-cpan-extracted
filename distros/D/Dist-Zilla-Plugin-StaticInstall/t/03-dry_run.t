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
                [ 'StaticInstall' => { mode => 'auto', dry_run => 1 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

# intentionally not setting logging to verbose mode

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    all(
        # TODO: replace with Test::Deep::notexists($key)
        code(sub {
            !exists $_[0]->{x_static_install} ? 1 : (0, 'x_static_install exists');
        }),
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::StaticInstall',
                        config => {
                            'Dist::Zilla::Plugin::StaticInstall' => {
                                mode => 'auto',
                                dry_run => 1,
                            },
                        },
                        name => 'StaticInstall',
                        version => Dist::Zilla::Plugin::StaticInstall->VERSION,
                    },
                ),
            }),
        }),
    ),
    'plugin metadata contains pre-selected value, including dumped configs',
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
        'checking for .xs files',
        'would set x_static_install to 1',
    ),
    'appropriate logging for static distribution, dry run',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
