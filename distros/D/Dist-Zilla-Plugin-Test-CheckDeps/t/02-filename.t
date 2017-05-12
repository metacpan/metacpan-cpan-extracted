use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'Test::CheckDeps' => { filename => 't/foo.t' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo; 1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
ok(!-e $build_dir->child('t', '00-check-deps.t'), 'default test not created');
ok(-e $build_dir->child('t', 'foo.t'), 'test created using new name');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
