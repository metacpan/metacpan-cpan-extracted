use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Test::Kwalitee' => { filename => 'xt/author/kwalitee.t' } ],
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
use strict;
1;,
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
        prereqs => superhashof({
            develop => {
                requires => {
                    'Test::Kwalitee' => '1.21',
                },
            },
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::Kwalitee',
                    config => {
                        'Dist::Zilla::Plugin::Test::Kwalitee' => {
                            skiptest => [],
                            filename => 'xt/author/kwalitee.t',
                        },
                    },
                    name => 'Test::Kwalitee',
                    version => Dist::Zilla::Plugin::Test::Kwalitee->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the develop phase; dumped configs are good',
) or diag 'got distmeta: ', explain $tzil->distmeta;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt author kwalitee.t));

ok(-e $file, 'test created, using the custom filename');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
