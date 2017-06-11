use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

my $tzil;
like(
    exception {
        $tzil = Builder->from_config(
            { dist_root => 'does-not-exist' },
            {
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        'Chrome::ExtraPrompt',
                    ),
                    path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                },
            },
        );

        $tzil->chrome->logger->set_debug(1);
        $tzil->build;
    },
    qr{must be used in ~/.dzil/config.ini -- NOT dist.ini!},
    'plugin cannot be used within dist.ini',
);

diag 'got log messages: ', explain $tzil->log_messages
    if $tzil and not Test::Builder->new->is_passing;

diag 'got log messages: ', explain Builder->most_recent_log_events
    if not $tzil and not Test::Builder->new->is_passing and Builder->can('most_recent_log_events');

done_testing;
