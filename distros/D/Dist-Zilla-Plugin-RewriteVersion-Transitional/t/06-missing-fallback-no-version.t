use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

delete @ENV{qw(RELEASE_STATUS TRIAL V)};

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                { # configs as in simple_ini, but no version assignment
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'RewriteVersion::Transitional' ],
            ),
            path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: stuff

1;
FOO
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr/no version was ever set/,
    'build dies: no version provider returned a value',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        re(qr/\[RewriteVersion::Transitional\] tried to provide a version, but fallback_version_provider configuration is missing/),
    ),
    'build failure is combined with a helpful message when fallback_version_provider is not provided',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
