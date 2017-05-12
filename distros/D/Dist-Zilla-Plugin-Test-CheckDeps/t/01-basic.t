use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

# build fake dist
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ Prereqs => RuntimeRequires => { strict => 0 } ],
                [ MetaConfig => ],
                [ MetaJSON => ],
                [ 'Test::CheckDeps' => { level => 'suggests' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo; 1;",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('t', '00-check-deps.t');
ok( -e $file, 'test created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

like($content, qr/^use Test::CheckDeps [\d.]+;$/m, 'use line is correct');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            test => {
                requires => {
                    'Test::More' => '0.94',
                    'Test::CheckDeps' => '0.010',
                },
            },
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof({
                class   => 'Dist::Zilla::Plugin::Test::CheckDeps',
                config => {
                    'Dist::Zilla::Plugin::Test::CheckDeps' => {
                        todo_when => '0',
                        level => 'suggests',
                        filename => 't/00-check-deps.t',
                        fatal => 0,
                    },
                },
                name    => 'Test::CheckDeps',
                version => Dist::Zilla::Plugin::Test::CheckDeps->VERSION,
            }),
        }),
    }),
    'test prereqs are properly injected',
);

my $prereqs_tested;
subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    do $file;
    warn $@ if $@;

    $prereqs_tested = Test::Builder->new->current_test;
};

# Test::More, Test::CheckDeps, strict
is($prereqs_tested, 3, 'correct number of prereqs were tested');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
