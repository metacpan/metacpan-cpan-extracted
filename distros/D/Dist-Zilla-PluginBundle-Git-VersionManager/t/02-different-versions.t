use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 'first';

use lib 't/lib';
use Helper;

delete $ENV{V};

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
                        # modify some configs
                        bump_only_matching_versions => 1,
                    } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.002';\n1",
            path(qw(source lib DZT Sample2.pm)) => "package DZT::Sample;\nour \$VERSION = '0.001';\n1",
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

is($tzil->version, '0.002', 'version properly extracted from main module');

# it is too complicated to test a release here, what with all the git plugins,
# so we will trust that BumpVersionAfterRelease properly tested its
# all_matching option, and just test that we set the option properly.

is(
    (first { $_->isa('Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional') } @{ $tzil->plugins }),
    undef,
    '[BumpVersionAfterRelease::Transitional] is not used with bump_only_matching_versions',
);

is(
    (first { $_->isa('Dist::Zilla::Plugin::RewriteVersion::Transitional') } @{ $tzil->plugins }),
    undef,
    '[RewriteVersion::Transitional] is not used with bump_only_matching_versions',
);

my $bump_version_plugin = first { $_->isa('Dist::Zilla::Plugin::BumpVersionAfterRelease') } @{ $tzil->plugins };
is($bump_version_plugin->all_matching, 1, 'BumpVersionAfterRelease plugin config gets set correctly');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
