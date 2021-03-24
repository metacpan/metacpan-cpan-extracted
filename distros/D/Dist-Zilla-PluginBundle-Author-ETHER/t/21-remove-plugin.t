use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::Deep qw(!any !none);
use Test::DZil;
use Path::Tiny;
use List::Util 1.33 qw(any none);
use Term::ANSIColor 2.01 'colorstrip';
use Moose::Util 'find_meta';

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

# used by the 'airplane' config
use Test::Needs 'Dist::Zilla::Plugin::BlockRelease';

$ENV{FAKE_RELEASE} = 1;

my $tempdir = no_git_tempdir();

my @network_plugins = Dist::Zilla::PluginBundle::Author::ETHER->_network_plugins;
my %network_plugins;
@network_plugins{ map Dist::Zilla::Util->expand_config_package_name($_), @network_plugins } = () x @network_plugins;

my @tests = (
    {
        test_name => 'no removals',
        remove_plugins => [],
        unwanted_plugins => \@network_plugins,
    },
    {
        test_name => 'remove things referenced by short form, full name, moniker',
        remove_plugins => [ '=Dist::Zilla::Plugin::Keywords', 'generate CONTRIBUTING' ],
        unwanted_plugins => [
            @network_plugins,
            qw(Keywords GenerateFile::FromShareDir),
        ],
    },
);

subtest $_->{test_name} => sub
{
    my $remove = $_->{remove_plugins};
    my $expected_removals = $_->{unwanted_plugins};

    my $tzil;
    my @warnings = warnings {
        $tzil = Builder->from_config(
            { dist_root => 'does-not-exist' },
            {
                tempdir_root => $tempdir->stringify,
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        [ '@Author::ETHER' => {
                            server => 'none',
                            'Test::MinimumVersion.max_target_perl' => '5.008',
                            # necessary, as there are no files added to the build to read a version from
                            'RewriteVersion::Transitional.skip_version_provider' => 1,
                            airplane => 1,  # removes network plugins
                            @$remove ? ('-remove' => $remove) : (),
                            # since we don't do a build, not removing the git- and network-based plugins is okay.
                        } ],
                    ),
                    path(qw(source lib DZT Sample.pm)) => '',
                    path(qw(source Changes)) => '',
                },
            },
        );
    };

    my @plugin_classes = map find_meta($_)->name, @{$tzil->plugins};

    cmp_deeply(
        [ grep exists $network_plugins{$_}, @plugin_classes ],
        [],
        'no network-using plugins were actually added',
    );

    ok(
        do { my $add = $_; any { $_ eq 'Dist::Zilla::Plugin::' . $add } @plugin_classes },
        $_ . ' found in plugin list',
    ) foreach qw(FakeRelease BlockRelease);

    ok(
        do { my $rem = $_; none { $_ eq 'Dist::Zilla::Plugin::' . $rem } @plugin_classes },
        $_ . ' not found in plugin list',
    ) foreach @$expected_removals; #qw(Keywords GenerateFile::FromShareDir);

    my @expected_log_messages = (
        'building in airplane mode - plugins requiring the network are skipped, and releases are not permitted',
        'FAKE_RELEASE set - not uploading to CPAN',
    );

    my $ok = cmp_deeply(
        [ map colorstrip($_), @warnings ],
        superbagof(map re(qr/^\[\@Author::ETHER\] $_/), @expected_log_messages),
        'we warn when in airplane mode, and performing a fake release',
    ) or diag explain @warnings;

    # only occurs on Dist::Zilla < 6.000
    push @expected_log_messages,
        '.git is missing and META.json is present -- this looks like a CPAN download rather than a git repository. You should probably run perl Build.PL; ./Build instead of using dzil commands!';

    @warnings = grep { my $warning = $_; not grep $warning =~ /$_/, @expected_log_messages } @warnings;
    warn @warnings if @warnings and $ok;
}
foreach @tests;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
