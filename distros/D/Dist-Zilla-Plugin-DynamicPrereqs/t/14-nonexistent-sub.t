use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use Test::File::ShareDir ();

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ DynamicPrereqs => {
                    -include_sub => [ qw(foo bar baz) ],
                    -raw => [ 'foo();' ],
                  },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source share include_subs foo)) => "sub foo {\n  bar();\n}\n",
        },
    },
);

Test::File::ShareDir->import(
    -root => path($tzil->tempdir)->child('source')->stringify,
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share' } },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr/no definitions available for subs 'bar', 'baz'!/,
    'build fails due to unrecognized subs',
) or diag 'got log messages: ', explain $tzil->log_messages;

cmp_deeply(
    $tzil->log_messages,
    superbagof(q{[DynamicPrereqs] no definitions available for subs 'bar', 'baz'!}),
    'fatal log message about unrecognized sub',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
