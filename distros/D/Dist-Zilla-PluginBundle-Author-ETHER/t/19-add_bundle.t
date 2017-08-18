use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Moose::Util 'find_meta';

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

use Dist::Zilla::PluginBundle::Basic;
my $basic_payload;
{
    my $meta = find_meta('Dist::Zilla::PluginBundle::Basic');
    $meta->make_mutable;
    $meta->add_before_method_modifier(configure => sub
    {
        # capture the full payload, for testing
        $basic_payload = shift->payload;
    });
}

use Dist::Zilla::PluginBundle::Author::ETHER;
{
    my $meta = find_meta('Dist::Zilla::PluginBundle::Author::ETHER');
    $meta->make_mutable;
    $meta->add_before_method_modifier(configure => sub
    {
        shift->add_bundle(
            '@Filter' => {
                ':version' => '4.000',              # required minimum for @Filter
                -bundle => '@Basic',
                # remove the plugins that clash with my author bundle
                -remove => [ qw(
                    MetaYAML
                    License
                    Readme
                    ExecDir
                    ShareDir
                    Manifest
                    TestRelease
                    ConfirmRelease
                    UploadToCPAN
                ) ],
                # we'll assume for this test that @Basic passes this value on...
                'GatherDir.include_dotfiles' => 0,  # a default config
            },
        );
    });
}

my $tempdir = no_git_tempdir();

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        tempdir_root => $tempdir->stringify,
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ '@Author::ETHER' => {
                    # these plugins will be supplied by @Basic instead.
                    -remove => \@REMOVED_PLUGINS,
                    installer => 'none',
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    'GatherDir.include_dotfiles' => 1,  # an override config to pass to @Basic
                } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n1",
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

# everything in @Basic that does not clash with our author bundle
my @bundle_plugins = qw(
    GatherDir
    PruneCruft
    ManifestSkip
    ExtraTests
    MakeMaker
);

# individual member plugins of bundle should not have been added to run-requires
all_plugins_in_prereqs($tzil,
    exempt => [ map { Dist::Zilla::Util->expand_config_package_name($_) } @bundle_plugins ],
    additional => [ 'Dist::Zilla::PluginBundle::Filter' ],
);

cmp_deeply(
    $tzil->plugins,
    superbagof(
        map {
            methods(
                [ isa => Dist::Zilla::Util->expand_config_package_name($_) ] => bool(1),
                plugin_name => '@Author::ETHER/@Filter/' . $_,
            )
        } @bundle_plugins,
    ),
    'plugins from @Basic were added to the distribution, with the proper moniker',
);

cmp_deeply(
    $basic_payload,
    superhashof({
        'GatherDir.include_dotfiles' => 1,
    }),
    '@Basic received the correct payload, with default values overlaid with overrides from the user',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            develop => superhashof({
                requires => all(
                    superhashof({ 'Dist::Zilla::PluginBundle::Filter' => '4.000' }),
                    notexists(map { Dist::Zilla::Util->expand_config_package_name($_) } @bundle_plugins),
                ),
            }),
        }),
    }),
    'the bundle is added to prereqs, but the individual plugins are not',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
