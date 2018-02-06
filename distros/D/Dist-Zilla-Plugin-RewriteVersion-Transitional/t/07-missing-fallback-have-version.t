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
            path(qw(source dist.ini)) => simple_ini(
                # this configuration hardcodes the version for the distribution
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
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally: exactly one version provider returned a value',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        re(qr/\[RewriteVersion::Transitional\] tried to provide a version, but fallback_version_provider configuration is missing/),
    ),
    'build includes a message noting that this plugin didn\'t actually do anything',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
