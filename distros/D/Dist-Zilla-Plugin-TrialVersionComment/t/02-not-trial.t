use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

# protect from external environment
local $ENV{TRIAL};
local $ENV{RELEASE_STATUS};

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                { is_trial => 0 },  # merge into root section
                [ GatherDir => ],
                [ 'TrialVersionComment' => ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\nour \$VERSION = '0.001';\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

ok(!$tzil->is_trial, 'trial flag is not set on the distribution');

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
    $content,
    qr/^our \$VERSION = '0\.001';$/m,
    'stable release: TRIAL comment not added',
);

cmp_deeply(
    $tzil->log_messages,
    supersetof('[TrialVersionComment] release_status is not trial; doing nothing'),
    'log message about doing nothing',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
