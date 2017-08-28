use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ ExecDir => ],
                [ 'Test::Compile' => { fail_on_warning => 'none', filename => 'xt/author/foo.t' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
ok(!-e $build_dir->child(qw(t 00-compile.t)), 'default test not created');
my $file = $build_dir->child(qw(xt author foo.t));
ok(-e $file, 'test created using new name');

my $num_tests;
subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    $tzil->plugin_named('MakeMaker')->build;

    # ensure the variable is *not* set
    local $ENV{AUTHOR_TESTING};

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;

    $num_tests = Test::Builder->new->current_test;
};

is($num_tests, 1, 'correct number of files were tested');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
