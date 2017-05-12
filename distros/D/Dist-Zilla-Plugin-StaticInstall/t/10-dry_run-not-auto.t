use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

foreach my $mode (qw(off on))
{
    my $tzil;
    like(
        exception {
            $tzil = Builder->from_config(
                { dist_root => 'does-not-exist' },
                {
                    add_files => {
                        path(qw(source dist.ini)) => simple_ini(
                            [ GatherDir => ],
                            [ MetaConfig => ],
                            [ MakeMaker => ],
                            [ MetaJSON => ],
                            [ 'StaticInstall' => { mode => $mode, dry_run => 1 } ],
                        ),
                        path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                    },
                },
            );

            $tzil->chrome->logger->set_debug(1);
            $tzil->build;
        },
        qr/\Q[StaticInstall] dry_run cannot be true if mode is "off" or "on"\E/,
        "plugin dies appropriately with bad config combination (dry_run = 1, mode = $mode)",
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if $tzil and not Test::Builder->new->is_passing;

    diag 'got log messages: ', explain Builder->most_recent_log_events
        if not $tzil and not Test::Builder->new->is_passing and Builder->can('most_recent_log_events');
}

done_testing;
