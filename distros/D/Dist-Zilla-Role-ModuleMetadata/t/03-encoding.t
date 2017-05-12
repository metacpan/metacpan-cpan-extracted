use strict;
use warnings;

use utf8;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

use Test::Needs { 'Dist::Zilla' => '5.000' };

use lib 't/lib';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                '=SimpleProvides',
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
use utf8;
our $VERSION = '0.001';
package Foo::ಠ_ಠ;
our $VERSION = '0.002';
FOO
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
        provides => {
            'Foo' => {
                file => 'lib/Foo.pm',
                version => '0.001',
            },
            "Foo::\x{ca0}_\x{ca0}" => {
                file => 'lib/Foo.pm',
                version => '0.002',
            },
        },
    }),
    'plugin metadata contains data from Module::Metadata object, using the correct encoding',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
