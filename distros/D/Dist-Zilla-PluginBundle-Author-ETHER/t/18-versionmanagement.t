use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

my $tempdir = no_git_tempdir();

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        tempdir_root => $tempdir->stringify,
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                {
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                    version  => '0.006',
                },
                [ '@Author::ETHER' => {
                    # we do NOT need to remove the usual plugins here, because we do not do a build.
                    # but we do need to avoid our heuristic for "looks like a CPAN download" on older
                    # Dist::Zilla, where we don't change directories into the build during testing.
                    -remove => [ 'Git::GatherDir' ],
                    server => 'none',
                    'Test::MinimumVersion.max_target_perl' => '5.008',
                    # necessary, as there are no files added to the build to read a version from
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.005';\n1",
            path(qw(source lib DZT Sample2.pm)) => "package DZT::Sample2;\nour \$VERSION = '0.002';\n1",
            path(qw(source lib DZT Sample3.pm)) => "package DZT::Sample3;\n\n1",
            path(qw(source Changes)) => '',
        },
    },
);

is($tzil->version, '0.006', 'version is extracted from the main module');

cmp_deeply(
    $tzil->plugins,
    superbagof(
        methods(
            [ isa => 'Dist::Zilla::Plugin::RewriteVersion::Transitional' ] => bool(1),
            plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/RewriteVersion::Transitional$}),
            global => 1,
            fallback_version_provider => 'Git::NextVersion',
            _fallback_version_provider_args => { version_regexp => '^v([\d._]+)(-TRIAL)?$' },
        ),
        all(
            methods(
                [ isa => 'Dist::Zilla::Plugin::CopyFilesFromRelease' ] => bool(1),
                plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/CopyFilesFromRelease$}),
            ),
            noclass(superhashof({
                # in 0.006, the method started returning a list rather than a listref
                filename => [ 'Changes' ],
            })),
        ),
        methods(
            [ isa => 'Dist::Zilla::Plugin::Git::Commit' ] => bool(1),
            plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/release snapshot$}),
            add_files_in => [ str('.') ],
            allow_dirty => superbagof(str('Changes')),
            commit_msg => '%N-%v%t%n%n%c'
        ),
        methods(
            [ isa => 'Dist::Zilla::Plugin::Git::Tag' ] => bool(1),
            plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/Git::Tag$}),
            tag_format => 'v%v',
            tag_message => 'v%v%t',
        ),
        methods(
            [ isa => 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional' ] => bool(1),
            plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/BumpVersionAfterRelease::Transitional$}),
            global => 1,
        ),
        methods(
            [ isa => 'Dist::Zilla::Plugin::NextRelease' ] => bool(1),
            plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/NextRelease$}),
            time_zone => 'UTC',
            format => '%-8v  %{yyyy-MM-dd HH:mm:ss\'Z\'}d%{ (TRIAL RELEASE)}T',
        ),
        methods(
            [ isa => 'Dist::Zilla::Plugin::Git::Commit' ] => bool(1),
            plugin_name => re(qr{^\@Author::ETHER/\@Git::VersionManager/post-release commit$}),
            allow_dirty => superbagof(str('Changes')),
            allow_dirty_match => [ qr{^lib/.*\.pm$} ],
            commit_msg => 'increment $VERSION after %v release'
        ),
    ),
    'all expected plugins make it into the build, with the correct configurations',
)
or diag 'got plugin configurations: ', do {
    local $Data::Dumper::Maxdepth = 4;
    explain $tzil->plugins
};

done_testing;
