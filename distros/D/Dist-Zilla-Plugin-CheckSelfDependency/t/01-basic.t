use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                'MetaConfig',
                'CheckSelfDependency',
                [ 'Prereqs / RuntimeRequires' => { 'Foo::Bar' => '1.23' } ],
            ),
            path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr{Foo::Bar is listed as a prereq, but is also provided by this dist \(lib/Foo/Bar.pm\)!},
    'build is aborted',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::CheckSelfDependency',
                    config => superhashof({
                        'Dist::Zilla::Plugin::CheckSelfDependency' => {
                            finder => [ ':InstallModules' ],
                        },
                    }),
                    name => 'CheckSelfDependency',
                    version => ignore,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

ok(!exists $tzil->distmeta->{provides}, 'provides field was not autovivified in distmeta');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
