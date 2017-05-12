use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

local $ENV{TRIAL} = 1;
local $ENV{RELEASE_STATUS} = 'testing';

local $TODO = 'sadly, the case we are testing for here doesn\'t work at all yet!';

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                { is_trial => 1 },  # merge into root section
                [ GatherDir => ],
                [ 'TrialVersionComment' ],
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
$Foo::VERSION = '0.001';
# TRIAL comment will be added above
1;
FOO
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
    $content,
    qr/^\$Foo::VERSION = '0\.001'; # TRIAL$/m,
    'TRIAL comment added to fully-qualified $VERSION assignment',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
