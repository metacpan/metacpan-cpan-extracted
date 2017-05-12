use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::DZil;
use Test::Deep '!any';
use Test::Fatal;
use Path::Tiny;
use List::Util 1.33 'any';
use PadWalker 'closed_over';
use Term::ANSIColor 2.01 'colorstrip';
use Moose::Util 'find_meta';

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

# used by the 'airplane' config
use Test::Needs 'Dist::Zilla::Plugin::BlockRelease';

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

$ENV{FAKE_RELEASE} = 1;

my $tzil;
my @warnings = warnings {
    $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    [ '@Author::ETHER' => {
                        '-remove' => [
                            @REMOVED_PLUGINS,
                            'UploadToCPAN', # removed just in case!
                            'RunExtraTests', 'TestRelease', # why waste the time?
                        ],
                        airplane => 1,
                        'RewriteVersion::Transitional.skip_version_provider' => 1,
                        'Test::MinimumVersion.max_target_perl' => '5.008',
                    } ],
                ),
                path(qw(source lib Foo Bar.pm)) => <<MODULE,
use strict;
use warnings;
package Foo::Bar;

1;
MODULE
                path(qw(source Changes)) => <<'CHANGES',
Revision history for {{$dist->name}}

{{$NEXT}}
        - some changelog entry
CHANGES
            },
        },
    );
};

my @plugin_classes = map { find_meta($_)->name } @{$tzil->plugins};
die 'UploadToCPAN found in plugin list' if any { $_ eq 'Dist::Zilla::Plugin::UploadToCPAN' } @plugin_classes;
die 'FakeRelease not found in plugin list' if not any { $_ eq 'Dist::Zilla::Plugin::FakeRelease' } @plugin_classes;

my @expected_log_messages = (
    'building in airplane mode - plugins requiring the network are skipped, and releases are not permitted',
    'FAKE_RELEASE set - not uploading to CPAN',
);

my $ok = cmp_deeply(
    [ map { colorstrip($_) } @warnings ],
    superbagof(map { re(qr/^\[\@Author::ETHER\] $_/) } @expected_log_messages),
    'we warn when in airplane mode, and performing a fake release',
) or diag explain @warnings;

@warnings = grep { my $warning = $_; not grep { $warning =~ /$_/ } @expected_log_messages } @warnings;
warn @warnings if @warnings and $ok;

assert_no_git($tzil);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

# check that everything we loaded is in the pluginbundle's run-requires, etc
all_plugins_in_prereqs($tzil,
    exempt => [
        'Dist::Zilla::Plugin::GatherDir',       # used by us here
        'Dist::Zilla::Plugin::FakeRelease',     # ""
    ],
    additional => [
        'Dist::Zilla::Plugin::BlockRelease',    # via airplane option
    ],
);

my %network_plugins = %{
    closed_over(\&Dist::Zilla::PluginBundle::Author::ETHER::configure)->{'%network_plugins'}
};

cmp_deeply(
    [ grep { exists $network_plugins{$_} } $tzil->plugins ],
    [],
    'no network-using plugins were actually loaded',
);

like(
    colorstrip(exception { $tzil->release }),
    qr{\[\@Author::ETHER/BlockRelease\] halting release},
    'release halts',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
