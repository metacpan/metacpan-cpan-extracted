use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;

BEGIN {
  plan skip_all => '$cwd needs to be $zilla->root for these tests (requires Dist::Zilla 6.003)'
    if not eval { +require Dist::Zilla; Dist::Zilla->VERSION('6.003') };
}

use Test::Deep;
use Test::Fatal;
use Path::Tiny;
use List::Util 1.45 'uniq';
use Moose::Util 'find_meta';

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

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
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ '@Author::ETHER' => {
                    -remove => \@REMOVED_PLUGINS,
                    server => 'none',
                    ':version' => '0.002',
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    installer => '=inc::Foo',
                    plugin_prereq_phase => '',          # undef is not possible in dist.ini
                    plugin_prereq_relationship => '',   # ""
                } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.002';\n1",
            path(qw(source Changes)) => '',
            path(qw(source inc Foo.pm)) => "package inc::Foo;\nuse Moose;\nextends 'Dist::Zilla::Plugin::MakeMaker';\n1",
        },
    },
);

assert_no_git($tzil);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

all_plugins_in_prereqs($tzil,
    exempt => [
        'Dist::Zilla::Plugin::GatherDir',   # used by us here
        'inc::Foo',                         # local files are filtered out
    ],
    prereq_plugin_phase => '',
    prereq_plugin_type => '',
);

my @bundle_plugins = uniq map find_meta($_)->name,
    grep $_->plugin_name =~ /^\@Author::ETHER\/[^@]/, @{$tzil->plugins};
cmp_deeply(
    $tzil->distmeta->{prereqs}{$PREREQ_PHASE_DEFAULT}{$PREREQ_RELATIONSHIP_DEFAULT} // {},
    notexists(@bundle_plugins),
    'plugins provided by the bundle are not injected into prereqs',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
