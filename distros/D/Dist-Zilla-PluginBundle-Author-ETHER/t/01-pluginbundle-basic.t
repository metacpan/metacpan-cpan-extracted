use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use List::Util 'first';
use Module::Runtime 'module_notional_filename';
use Moose::Util 'find_meta';

# these are used by our default 'installer' setting
use Test::Needs qw(
    Dist::Zilla::Plugin::MakeMaker::Fallback
    Dist::Zilla::Plugin::ModuleBuildTiny
);

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

SKIP: {
    skip('we only insist that the author have bash installed', 1)
        unless $ENV{AUTHOR_TESTING};

    require Devel::CheckBin;
    ok(Devel::CheckBin::can_run('bash'), 'the bash executable is available');
}

my $tempdir = no_git_tempdir();

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        tempdir_root => $tempdir->stringify,
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    version => '0.005',
                },
                'GatherDir',
                [ '@Author::ETHER' => {
                    -remove => \@REMOVED_PLUGINS,
                    server => 'none',
                    ':version' => '0.002',
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    'Git::NextVersion.version_regexp' => '^ohhai',
                    'Test::MinimumVersion.max_target_perl' => '5.008',
                } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\nour \$VERSION = '0.002';\n1",
            path(qw(source lib DZT Sample2.pm)) => "package DZT::Sample2;\n\n1",
            path(qw(source Changes)) => '',
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

# check that everything we loaded is in the pluginbundle's run-requires
all_plugins_in_prereqs($tzil,
    exempt => [ 'Dist::Zilla::Plugin::GatherDir' ],     # used by us here
    additional => [
        'Dist::Zilla::Plugin::MakeMaker::Fallback',     # via default installer option
        'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback', # ""
    ],
);

SKIP:
foreach my $plugin ('Dist::Zilla::Plugin::ModuleBuildTiny') {
    skip "need recent $plugin to test default_jobs option", 1 if not $plugin->can('default_jobs');
    my $obj = first { find_meta($_)->name eq $plugin } @{$tzil->plugins};
    is(
        $obj->default_jobs,
        9,
        'default_jobs was set for ' . find_meta($obj)->name . ' (via installer option and extra_args',
    )
}

my @plugin_classes = map find_meta($_)->name, @{$tzil->plugins};
is(
    scalar(grep $_ eq 'Dist::Zilla::Plugin::UploadToCPAN', @plugin_classes),
    1,
    'UploadToCPAN is in the plugin list',
);
is(
    scalar(grep $_ eq 'Dist::Zilla::Plugin::FakeRelease', @plugin_classes),
    0,
    'FakeRelease is not in the plugin list',
);

my $build_dir = path($tzil->tempdir)->child('build');

my @expected_files = qw(
    Build.PL
    dist.ini
    INSTALL
    lib/DZT/Sample.pm
    lib/DZT/Sample2.pm
    CONTRIBUTING
    LICENCE
    MANIFEST
    META.json
    META.yml
    README
    Changes
    t/00-report-prereqs.t
    xt/author/00-compile.t
    xt/author/eol.t
    xt/author/kwalitee.t
    xt/author/minimum-version.t
    xt/author/pod-spell.t
    xt/author/clean-namespaces.t
    xt/release/changes_has_content.t
    xt/release/cpan-changes.t
    xt/author/mojibake.t
    xt/author/pod-coverage.t
    xt/author/pod-syntax.t
    xt/author/portability.t
);

push @expected_files, eval { Dist::Zilla::Plugin::Test::NoTabs->VERSION('0.09'); 1 }
    ? 'xt/author/no-tabs.t'
    : 'xt/release/no-tabs.t';

push @expected_files, eval { Dist::Zilla::Plugin::MetaTests->VERSION('6.017'); 1 }
    ? 'xt/author/distmeta.t'
    : 'xt/release/distmeta.t';

push @expected_files, 't/00-report-prereqs.dd'
    if Dist::Zilla::Plugin::Test::ReportPrereqs->VERSION >= 0.014;

push @expected_files, 'xt/author/pod-no404s.t' if not $ENV{CONTINUOUS_INTEGRATION};

cmp_deeply(
    [ recursive_child_files($build_dir) ],
    bag(@expected_files),
    'the right files are created by the pluginbundle',
);

is(
    (grep /someone tried to munge .* after we read from it. Making modifications again.../, @{ $tzil->log_messages }),
    0,
    'no files were re-munged needlessly',
);

{
    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_static_install => 1,
            prereqs => superhashof({
                $PREREQ_PHASE_DEFAULT => superhashof({
                    $PREREQ_RELATIONSHIP_DEFAULT => superhashof({
                        'Dist::Zilla::Plugin::ModuleBuildTiny' => '0.012',
                        'Dist::Zilla::PluginBundle::Author::ETHER' => '0.002',
                    }),
                }),
            }),
            provides => {
                # version edited, added (respectively) by [RewriteVersion::Transitional]
                # see https://github.com/kentnl/Dist-Zilla-Plugin-MetaProvides/issues/8
                'DZT::Sample'   => { file => 'lib/DZT/Sample.pm', version => '0.005' },
                'DZT::Sample2'  => { file => 'lib/DZT/Sample2.pm', version => '0.005' },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    ( map
                        +{
                            class => 'Dist::Zilla::Plugin::' . $_,
                            # TestRunner added default_jobs and started adding to dump_config in 5.014
                            ("Dist::Zilla::Plugin::$_"->can('default_jobs')
                                ? (config => superhashof({
                                    'Dist::Zilla::Role::TestRunner' => superhashof({ default_jobs => 9 }),
                                  }))
                                : ()),
                            name => '@Author::ETHER/' . $_,
                            version => "Dist::Zilla::Plugin::$_"->VERSION,
                        },
                        qw(ModuleBuildTiny RunExtraTests) ),
                    subhashof({
                        class => 'Dist::Zilla::Plugin::Run::AfterRelease',
                        # this may or may not be included, depending on the plugin version
                        config => superhashof({
                            'Dist::Zilla::Plugin::Run::Role::Runner' => superhashof({
                                fatal_errors => 0,
                                run => [ 'REDACTED' ],  # password detected!
                            }),
                        }),
                        name => '@Author::ETHER/install release',
                        version => Dist::Zilla::Plugin::Run::AfterRelease->VERSION,
                    }),
                    {
                        class => 'Dist::Zilla::Plugin::CopyFilesFromRelease',
                        config => superhashof({
                            'Dist::Zilla::Plugin::CopyFilesFromRelease' => superhashof({
                                filename => superbagof(qw(LICENCE LICENSE CONTRIBUTING ppport.h INSTALL)),
                            }),
                        }),
                        name => '@Author::ETHER/copy generated files',
                        version => Dist::Zilla::Plugin::CopyFilesFromRelease->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::CopyFilesFromRelease',
                        config => superhashof({
                            'Dist::Zilla::Plugin::CopyFilesFromRelease' => superhashof({
                                filename => [ 'Changes' ],
                            }),
                        }),
                        name => '@Author::ETHER/@Git::VersionManager/CopyFilesFromRelease',
                        version => Dist::Zilla::Plugin::CopyFilesFromRelease->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::RewriteVersion::Transitional',
                        config => superhashof({
                            'Dist::Zilla::Plugin::RewriteVersion::Transitional' => all(
                                superhashof({}),
                                # no fallback used here - we provided a version in root config
                                notexists(qw(fallback_version_provider _fallback_version_provider_args)),
                            ),
                            'Dist::Zilla::Plugin::RewriteVersion' => superhashof({
                                global => 1,
                                add_tarball_name => 0,
                                skip_version_provider => 1,
                            }),
                        }),
                        name => '@Author::ETHER/@Git::VersionManager/RewriteVersion::Transitional',
                        version => Dist::Zilla::Plugin::RewriteVersion::Transitional->VERSION,
                    },
                ),
            }),
        }),
        'config is properly included in metadata',
    )
    or diag 'got distmeta: ', explain $tzil->distmeta;
}

cmp_deeply(
    (first { $_->isa('Dist::Zilla::Plugin::RewriteVersion::Transitional') } @{ $tzil->plugins }),
    methods(
        fallback_version_provider => 'Git::NextVersion',
        _fallback_version_provider_args => superhashof({ version_regexp => '^ohhai' }),
    ),
    'payload for [Git::NextVersion] is passed along to the replacement used by [RewriteVersion::Transitional]',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            $PREREQ_PHASE_DEFAULT => superhashof({
                $PREREQ_RELATIONSHIP_DEFAULT => notexists('Dist::Zilla::Plugin::Git::Commit'),
            }),
        }),
    }),
    "a -remove'd plugin does not have a prereq injected into the distribution",
);

subtest "a -remove'd plugin should not be loaded" => sub {
    foreach my $plugin (map Dist::Zilla::Util->expand_config_package_name($_), @REMOVED_PLUGINS) {
        is(
            $INC{ module_notional_filename($plugin) },
            undef,
            "$plugin was -remove'd and has not been loaded",
        );
    }
};

cmp_deeply(
  (first { $_->plugin_name eq '@Author::ETHER/install release' } @{$tzil->plugins}),
  methods(
    run => [ 'cpanm http://URMOM:my%%20sekrit%%20password@pause.perl.org/pub/PAUSE/authors/id/U/UR/URMOM/%a' ],
  ),
  'correctly generated the URL for installing the newly-uploaded distribution',
);

my $contributing = $tzil->slurp_file('build/CONTRIBUTING');
unlike($contributing, qr/[^\S\n]\n/, 'no trailing whitespace in generated CONTRIBUTING');
like(
    $contributing,
    qr/^  \$ cpanm --reinstall --installdeps --with-recommends DZT::Sample\n.*^  \$ cpanm --reinstall --installdeps --with-develop --with-recommends DZT::Sample$/ms,
    'name of main module properly inserted into CONTRIBUTING',
);

my $version = Dist::Zilla::PluginBundle::Author::ETHER->VERSION;
like(
    $contributing,
    qr/^from a template file originating in Dist-Zilla-PluginBundle-Author-ETHER-$version\.$/m,
    'name of this bundle distribution and its version properly inserted into CONTRIBUTING',
);

like(
    $contributing,
    qr{
^If you have found a bug, but do not have an accompanying patch to fix it, you
can submit an issue report here:
\Qhttps://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample\E
or via email: bug-DZT-Sample\@\Qrt.cpan.org\E
This is a good place to send your questions about the usage of this distribution.
}m,
    'correctly inserted bugtracker mailto',
);

ok(
    !$tzil->plugin_named('@Author::ETHER/ExecDir'),
    'no script dir: no ExecDir plugin added',
);

my $main_module = $tzil->slurp_file('build/lib/DZT/Sample.pm');
isnt(index($main_module, q{our $VERSION = '0.005';}), -1, '$VERSION was rewritten in module');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
