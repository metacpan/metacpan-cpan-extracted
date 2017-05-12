use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

use Test::Requires 'Dist::Zilla::Plugin::Encoding';

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'Test::NoTabs' => ],
                [ 'Encoding' => { filename => 't/bar.t', encoding => 'bytes' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source t foo.t)) => "this is a test\n",
            path(qw(source t bar.t)) => "whargarbl\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt author no-tabs.t));
ok( -e $file, 'test created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');
unlike($content, qr/\t/m, 'no tabs in generated test');

my @files = (
    path(qw(lib Foo.pm)),
    path(qw(t foo.t)),
);

like($content, qr/'\Q$_\E'/m, "test checks $_") foreach @files;
unlike($content, qr/bar/m, 'test does not check for files with encoding = bytes');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
