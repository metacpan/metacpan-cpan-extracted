use strict;
use warnings;

use Test::More;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep '!none';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 1.33 'none';

use lib 't/lib';
use Helper;

delete $ENV{V};

my @tests = (
    {
        testname => 'no extra configs',
        configs => [],
        expected_installers_in_git_commit => 1,
    },
    {
        testname => 'munge_* set to true',
        configs => [
            'BumpVersionAfterRelease::Transitional.munge_makefile_pl' => 1,
            'BumpVersionAfterRelease::Transitional.munge_build_pl' => 1,
        ],
        expected_installers_in_git_commit => 1,

    },
    {
        testname => 'munge_* set to false',
        configs => [
            'BumpVersionAfterRelease::Transitional.munge_makefile_pl' => 0,
            'BumpVersionAfterRelease::Transitional.munge_build_pl' => 0,
        ],
        expected_installers_in_git_commit => 0,
    },
);

subtest $_->{testname} => sub {
    my $test = $_;

    my $tempdir = no_git_tempdir();

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            tempdir_root => $tempdir->stringify,
            add_files => {
                path(qw(source dist.ini)) => dist_ini(
                    { # configs as in simple_ini, but no version assignment
                        name     => 'DZT-Sample',
                        abstract => 'Sample DZ Dist',
                        author   => 'E. Xavier Ample <example@example.org>',
                        license  => 'Perl_5',
                        copyright_holder => 'E. Xavier Ample',
                    },
                    'GatherDir',
                    [ '@Git::VersionManager' => {
                            @{ $test->{configs} },
                        } ],
                ),
                path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.002';\n1",
                path(qw(source Changes)) => '',
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    my $post_release_commit_plugin = $tzil->plugin_named('@Git::VersionManager/post-release commit');

    if ($test->{expected_installers_in_git_commit}) {
        cmp_deeply(
            $post_release_commit_plugin->allow_dirty,
            superbagof(str('Makefile.PL'), str('Build.PL')),
            'post-release commit will include changes to Build.PL, Makefile.PL',
        );
    }
    else {
        ok(
            (none { $_ eq 'Build.PL' } @{ $post_release_commit_plugin->allow_dirty }),
            'post-release commit will not include changes to Build.PL',
        );
        ok(
            (none { $_ eq 'Makefile.PL' } @{ $post_release_commit_plugin->allow_dirty }),
            'post-release commit will not include changes to Makefile.PL',
        );
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
