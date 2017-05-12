use strict;
use warnings;

use utf8;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

my $tempdir = no_git_tempdir();
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    author   => [ 'Anne O\'Thor <author@example.com>' ],
                },
                [ GatherDir => ],
                [ 'Git::Contributors' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        tempdir_root => $tempdir->stringify,
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

$tzil->chrome->logger->set_debug(1);

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    # TODO: replace with Test::Deep::notexists($key)
    code(sub {
        !exists $_[0]->{x_contributors} ? 1 : (0, 'x_contributors exists');
    }),
    'no metadata is added when there are no commits',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
