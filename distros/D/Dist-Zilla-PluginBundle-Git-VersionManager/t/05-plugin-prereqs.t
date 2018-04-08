use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 1.45 'uniq';
use Moose::Util 'find_meta';

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
                        plugin_prereq_phase => 'develop',
                        plugin_prereq_relationship => 'suggests',
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

is($tzil->version, '0.002', 'version properly extracted from main module');

cmp_deeply(
    $tzil->plugins,
    superbagof(
        methods([ isa => 'Dist::Zilla::Plugin::Prereqs' ] => bool(1)),
    ),
    'Prereqs plugin is added to the build',
);

my $bundle_name = '@Git::VersionManager';
my $bundle_plugin = $tzil->plugin_named("$bundle_name/prereqs for $bundle_name");
cmp_deeply(
    $bundle_plugin,
    methods(
        prereq_phase => 'develop',
        prereq_type => 'suggests',
    ),
    'found [Prereqs] plugin for develop-suggests',
);

my $bundle_plugin_prereqs = $bundle_plugin->_prereq;

my @bundle_plugins = grep {
    # prereqs hash is already fetched before adding this plugin, but it is in core anyway
    $_ ne 'Dist::Zilla::Plugin::Prereqs'
    # cannot be a (non-develop) prereq if the module lives in this distribution
    and do {
        (my $file = $_) =~ s{::}{/}g; $file .= '.pm';
        !path('lib', $file)->exists;
    };
}
uniq
map { find_meta($_)->name }
grep { $_->plugin_name =~ /^$bundle_name\/[^@]/ } @{$tzil->plugins};

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            develop => superhashof({
                suggests => superhashof({
                    map {
                        $_ => $bundle_plugin_prereqs->{find_meta($_)->name} // 0,
                    } @bundle_plugins
                }),
            }),
        }),
    }),
    'bundle plugins are injected as develop prereqs into the distribution',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
