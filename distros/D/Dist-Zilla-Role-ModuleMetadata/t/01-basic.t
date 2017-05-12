use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

use lib 't/lib';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                '=SimpleProvides',
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
our $VERSION = '0.001';
FOO
            path(qw(source lib Bar.pm)) => <<'BAR',
package Bar;
our $VERSION = '0.002';

package Bar::Baz;
our $VERSION = '0.003';
BAR
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
            'Bar' => {
                file => 'lib/Bar.pm',
                version => '0.002',
            },
            'Bar::Baz' => {
                file => 'lib/Bar.pm',
                version => '0.003',
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'SimpleProvides',
                    config => {
                        # 'SimpleProvides' => { }, # if it implemented dump_config
                        'Dist::Zilla::Role::ModuleMetadata' => {
                            'Module::Metadata' => Module::Metadata->VERSION,
                            version => Dist::Zilla::Role::ModuleMetadata->VERSION,
                        },
                    },
                    name => '=SimpleProvides',
                    version => undef,
                },
            ),
        }),
    }),
    'plugin metadata contains data from Module::Metadata object, and dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
