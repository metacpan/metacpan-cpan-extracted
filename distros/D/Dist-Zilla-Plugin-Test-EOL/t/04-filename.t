use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Test::EOL' => { filename => 'xt/release/foo.t' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt release foo.t));
ok( -e $file, 'test created, using the custom filename');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');
unlike($content, qr/\t/m, 'no tabs in generated test');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            develop => {
                requires => {
                    'Test::More' => '0.88',
                    'Test::EOL' => '0',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::EOL',
                    config => {
                        'Dist::Zilla::Plugin::Test::EOL' => {
                            finder => [ ':ExecFiles', ':InstallModules', ':TestFiles' ],
                            filename => 'xt/release/foo.t',
                            trailing_whitespace => 1,
                        },
                    },
                    name => 'Test::EOL',
                    version => Dist::Zilla::Plugin::Test::EOL->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the develop phase; dumped configs are good',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
