use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ ExtraTests => ],
                [ 'Test::CleanNamespaces' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(t author-clean-namespaces.t));
ok(-e $file, 'test created under xt/ and moved to t/author- by [ExtraTests]');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    local $ENV{AUTHOR_TESTING} = 1;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
