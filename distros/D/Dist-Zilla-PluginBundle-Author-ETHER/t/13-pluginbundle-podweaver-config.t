use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use File::pushd 'pushd';
use JSON::MaybeXS;
use List::Util 'max';
use Pod::Weaver::PluginBundle::Default;

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

# the bundle changes behaviour when it sees weaver.ini... ensure it is nowhere
# to be found, either in the initial directory or in the directory
# Dist::Zilla::Tester changes into during the build
ok(!-e 'weaver.ini', 'a weaver.ini does not exist in the initial directory');

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
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    'Test::MinimumVersion.max_target_perl' => '5.008',
                } ],
            ),
            path(qw(source lib Foo.pm)) => <<FOO,
package Foo;
# ABSTRACT: Hello, this is foo

1;
=pod

=cut
FOO
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

my $build_dir = path($tzil->tempdir)->child('build');

# the bundle changes behaviour when it sees weaver.ini... ensure it is nowhere
# to be found, either in the initial directory or in the directory
# Dist::Zilla::Tester changes into during the build
ok(!-e $build_dir->child('weaver.ini'), 'a weaver.ini does not exist in the build directory');

cmp_deeply(
    $tzil->plugin_named('@Author::ETHER/PodWeaver'),
    noclass(superhashof({
        replacer => 'replace_with_comment',
        post_code_replacer => 'replace_with_nothing',
    })),
    'other [PodWeaver] configs survived',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::PodWeaver',
                    config => superhashof({
                        'Dist::Zilla::Plugin::PodWeaver' => superhashof({
                            config_plugins => [ '@Author::ETHER' ],
                            # check that all plugins came from '@Author::ETHER'
                            plugins => array_each(
                                # TODO: we can use our bundle name in these
                                # sections too, by adjusting how we set up the configs
                                code(sub {
                                    ref $_[0] eq 'HASH' or return (0, 'not a HASH');
                                    $_[0]->{name} =~ m{^\@(CorePrep|Author::ETHER)/}
                                        or $_[0]->{class} =~ /^Pod::Weaver::Section::(Generic|Collect)$/
                                        or return (0, 'weaver plugin has bad name');
                                    return 1;
                                }),
                            ),
                            # TODO: Pod::Elemental::PerlMunger does not add these
                            # replacer => 'replace_with_comment',
                            # post_code_replacer => 'replace_with_nothing',
                        }),
                    }),
                    name => '@Author::ETHER/PodWeaver',
                    version => Dist::Zilla::Plugin::PodWeaver->VERSION,
                },
            ),
        }),
    }),
    'weaver plugin config is properly included in metadata - weaver.ini does not exist, so bundle is used',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

my $module = $tzil->slurp_file('build/lib/Foo.pm');
like(
    $module,
    qr/=head1 COPYRIGHT AND LICENCE/,
    'the Legal heading is adjusted appropriately',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;


# TODO: if my weaver bundle ever becomes customizable (e.g. via Moose
# attributes), move these subsequent tests into t/lib and test it for all
# possible configurations.

# If we specified a :version in weaver configs,
# - we want to see a runtime prereq in our own dist
# - TODO: we want to see an injected plugin_prereq on the target dist ([PodWeaver] should do this)
# Many things come in via [@Default], so look in there as well.

subtest 'all plugins in use are specified as required runtime prerequisites by the plugin bundle' => sub {
SKIP: {
    skip('this test requires a built dist', 1) if not -f 'META.json';

    my $pluginbundle_meta = decode_json(path('META.json')->slurp_raw);

    my %default_bundle_requirements = map {
       $_->[1] => $_->[2]{':version'}   # package => payload :version
    } Pod::Weaver::PluginBundle::Default->mvp_bundle_config;

    foreach my $bundle_plugin_config (Pod::Weaver::PluginBundle::Author::ETHER->mvp_bundle_config)
    {
        my $package = $bundle_plugin_config->[1];
        my $payload_version = $bundle_plugin_config->[2]{':version'};

        # package is part of @Default
        if (exists $default_bundle_requirements{$package}
            and not exists $pluginbundle_meta->{prereqs}{runtime}{requires}{$package})
        {
            cmp_deeply(
                $pluginbundle_meta->{prereqs}{runtime}{requires},
                superhashof({ 'Pod::Weaver::PluginBundle::Default' =>
                        (defined $payload_version || defined $default_bundle_requirements{$package}
                            ? _atleast(max($payload_version // 0, $default_bundle_requirements{$package} // 0))
                            : ignore())
                    }),
                $package . ' is part of [@Default], and Pod::Weaver::PluginBundle::Default is a runtime prereq of the plugin bundle' . ($payload_version ? ' at at least ' . $payload_version : ''),
            );
        }
        else
        {
            cmp_deeply(
                $pluginbundle_meta->{prereqs}{runtime}{requires},
                superhashof({ $package => (defined $payload_version ? _atleast($payload_version) : ignore()) }),
                $package . ' is a runtime prereq of the plugin bundle' . ($payload_version ? ' at at least ' . $payload_version : ''),
            );
        }
    }

    diag 'got plugin bundle metadata: ', explain $pluginbundle_meta
        if not Test::Builder->new->is_passing;
} };

sub _atleast {
    my $val = shift;
    code(sub {
        return 1 if $_[0] >= $val;
        return 0, "$_[0] is not at least $val";
    })
}

done_testing;
