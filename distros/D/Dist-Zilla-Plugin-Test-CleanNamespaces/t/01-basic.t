use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Test::CleanNamespaces' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt author clean-namespaces.t));
ok(-e $file, 'test created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            develop => {
                requires => {
                    'Test::CleanNamespaces' => Dist::Zilla::Plugin::Test::CleanNamespaces->_tcn_prereq,
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::CleanNamespaces',
                    config => {
                        'Dist::Zilla::Plugin::Test::CleanNamespaces' => {
                            filename => 'xt/author/clean-namespaces.t',
                            skips => [],
                        },
                    },
                    name => 'Test::CleanNamespaces',
                    version => ignore,
                },
            ),
        }),
    }),
    'prerequisites are properly injected',
) or diag 'got distmeta: ', explain $tzil->distmeta;

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
