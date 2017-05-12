use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

local $ENV{TRIAL} = 1;
local $ENV{RELEASE_STATUS} = 'testing';

my $original_content = <<'FOO';
package Foo;
our $VERSION = '0.001';    # TRIAL
# a TRIAL comment is already present; another one will not be added
1;
FOO

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                { is_trial => 1 },  # merge into root section
                [ GatherDir => ],
                [ 'TrialVersionComment' => ],
            ),
            path(qw(source lib Foo.pm)) => $original_content,
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

ok($tzil->is_trial, 'trial flag is set on the distribution');

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

is(
    $content,
    $original_content,
    'an extra TRIAL comment was not added to $VERSION assignment',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
