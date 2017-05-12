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
                [ 'Test::Compile' => { fail_on_warning => 'none', file => [ 'Bar.pm' ] } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = path($tzil->tempdir)->child(qw(build t 00-compile.t))->slurp_utf8;

like($content, qr'
my @module_files = \(
    \'Bar\.pm\',
    \'Foo\.pm\'
\);
', 'test checks explicitly added file',);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
