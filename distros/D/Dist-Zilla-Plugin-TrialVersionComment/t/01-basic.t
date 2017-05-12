use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;

local $ENV{TRIAL} = 1;
local $ENV{RELEASE_STATUS} = 'testing';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                { is_trial => 1 },  # merge into root section
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'TrialVersionComment' ],
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
our $VERSION = '0.001';
# TRIAL comment will be added above
1;
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

ok($tzil->is_trial, 'trial flag is set on the distribution');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::TrialVersionComment',
                    config => {
                        'Dist::Zilla::Plugin::TrialVersionComment' => {
                            finder => [':InstallModules', ':ExecFiles'],
                        },
                    },
                    name => 'TrialVersionComment',
                    version => Dist::Zilla::Plugin::TrialVersionComment->VERSION,
                },
            ),
        }),
    }),
    'metadata is correct',
) or diag 'got distmeta: ', explain $tzil->distmeta;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
    $content,
    qr/^our \$VERSION = '0\.001'; # TRIAL$/m,
    'TRIAL comment added to $VERSION assignment',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
