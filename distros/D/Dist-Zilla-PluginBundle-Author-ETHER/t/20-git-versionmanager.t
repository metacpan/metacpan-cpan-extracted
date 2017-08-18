use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 'first';

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

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
                        'Git::Tag.tag_message' => 'my tag is v%v',
                        'RewriteVersion::Transitional.fallback_version_provider' => 'Foo::Bar',
                        'Foo::Bar.version_regexp' => '^ohhai',
                    } ],
            )
            # we want to test how the .ini config string makes itself into the plugin bundle attribute
            . "\ncommit_files_after_release = extra_file\n",
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.002';\n1",
            path(qw(source extra_file)) => "this is a random data file\n",
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

# check that everything we loaded is in the pluginbundle's run-requires
all_plugins_in_prereqs($tzil,
    exempt => [ 'Dist::Zilla::Plugin::GatherDir' ],     # used by us here
    bundle_name => '@Git::VersionManager',
);

# would like to move the CPAN::Meta::Requirements stuff to its own role -- and all_plugins_in_prereqs
# should move to its own module as well.
# I guess it would be Dist::Zilla::Tester::BundlePrereqs ?

cmp_deeply(
    $tzil->plugins,
    superbagof(
        methods([ isa => 'Dist::Zilla::Plugin::GatherDir' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::RewriteVersion::Transitional' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::CopyFilesFromRelease' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::Git::Commit' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::Git::Tag' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::NextRelease' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::Git::Commit' ] => bool(1)),
        methods([ isa => 'Dist::Zilla::Plugin::Prereqs' ] => bool(1)),
    ),
    'all expected plugins make it into the build',
);

my $rewrite_version_plugin = first { $_->isa('Dist::Zilla::Plugin::RewriteVersion::Transitional') } @{ $tzil->plugins };
is($rewrite_version_plugin->fallback_version_provider, 'Foo::Bar', 'override passed for fallback_version_provider');
cmp_deeply(
    $rewrite_version_plugin->_fallback_version_provider_args,
    { version_regexp => '^ohhai' },
    '..and it was used to extract the arguments for that plugin',
);

my $git_tag_plugin = first { $_->isa('Dist::Zilla::Plugin::Git::Tag') } @{ $tzil->plugins };
is($git_tag_plugin->tag_message, 'my tag is v%v', 'a plugin config gets modified correctly');

cmp_deeply(
    $tzil->plugin_named('@Git::VersionManager/release snapshot')->allow_dirty,
    bag(str('extra_file'), str('Changes')),
    'additional commit_files_after_release file does not overshadow the defaults',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
