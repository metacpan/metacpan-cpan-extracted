use strict;
use warnings;

use Test::More 0.88;
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
                [ ExtraTests => ],
                [ 'Test::Compile' => { bail_out_on_fail => 1, xt_mode => 1, } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source bin foobar)) => "#!/usr/bin/perl\nprint \"foo\n\";\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(t author-00-compile.t));
ok(-e $file, 'test created under xt/ and moved to t/author- by [ExtraTests]');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    $tzil->plugin_named('MakeMaker')->build;

    local $ENV{AUTHOR_TESTING} = 1;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
