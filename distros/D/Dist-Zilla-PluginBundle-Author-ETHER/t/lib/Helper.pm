package # hide from PAUSE
    Helper;

use parent 'Exporter';
our @EXPORT = qw(@REMOVED_PLUGINS assert_no_git all_plugins_in_prereqs notexists);

use Test::More 0.96;
use Test::Deep;
use List::Util 1.45 'uniq';
use Path::Tiny;
use JSON::MaybeXS;
use Moose::Util 'find_meta';
use namespace::clean;

$ENV{USER} = 'notether';
delete $ENV{DZIL_AIRPLANE};
delete $ENV{FAKE_RELEASE};

{
    use Dist::Zilla::PluginBundle::Author::ETHER;
    package Dist::Zilla::PluginBundle::Author::ETHER;
    sub _pause_config { 'URMOM', 'mysekritpassword' }
}

# load this in advance, as we change directories between configuration and building
# (TODO: no longer needed with Dist-Zilla PR#552)
use Pod::Weaver::PluginBundle::Author::ETHER;

# plugins to always remove from test dists, as they use git or the network
# Our files are copied into source, so Git::GatherDir doesn't see them and
# besides, we would like to run these tests at install time too!
our @REMOVED_PLUGINS = qw(
    Git::GatherDir
    Git::NextVersion
    Git::Describe
    Git::Contributors
    Git::Check
    Git::Commit
    Git::Tag
    Git::Push
    Git::CheckFor::MergeConflicts
    Git::CheckFor::CorrectBranch
    Git::Remote::Check
    PromptIfStale
    EnsurePrereqsInstalled
);

# confirms that no git-based plugins are running.
sub assert_no_git
{
    my $tzil = shift;
    my @git_plugins = grep { find_meta($_)->name =~ /Git(?!(?:hubMeta|Hub::Update))/ } @{$tzil->plugins};
    cmp_deeply(\@git_plugins, [], 'no git-based plugins are running here');
}

# checks that all plugins in use are in the plugin bundle dist's runtime
# requires list
# - some plugins can be marked 'additional' - must be in recommended prereqs
#   AND the built dist's develop requires list
# - some plugins can be explicitly exempted (added manually to faciliate
#   testing)
sub all_plugins_in_prereqs
{ SKIP: {
    skip('this test requires a built dist', 1) if not -f 'META.json';

    my ($tzil, %options) = @_;

    my %additional = map { $_ => undef } @{ $options{additional} // [] };
    my %exempt = map { $_ => undef } @{ $options{exempt} // [] };

    my $pluginbundle_meta = decode_json(path('META.json')->slurp_raw);
    my $dist_meta = $tzil->distmeta;

    my $bundle_plugin_prereqs = $tzil->plugin_named('@Author::ETHER/bundle_plugins')->_prereq;

    subtest 'all plugins in use are specified as *required* runtime prerequisites by the plugin bundle, or develop prerequisites by the distribution' => sub {
        foreach my $plugin (uniq map { find_meta($_)->name } @{$tzil->plugins})
        {
            note($plugin . ' is explicitly exempted; skipping'), next
                if exists $exempt{$plugin};
            next if $plugin eq 'Dist::Zilla::Plugin::FinderCode';  # added automatically by dist builder

            # plugins with a specific :version requirement are added to
            # prereqs via an extra injected [Prereqs] plugin
            my $required_version = $bundle_plugin_prereqs->{find_meta($plugin)->name} // 0;

            if (exists $additional{$plugin})
            {
                # plugin was added in via an extra option, therefore the
                # plugin should have been added to develop prereqs
                ok(
                    exists $dist_meta->{prereqs}{develop}{requires}{$plugin},
                    $plugin . ' is a develop prereq of the distribution',
                );

                cmp_deeply(
                    $pluginbundle_meta->{prereqs}{runtime}{recommends},
                    superhashof({ $plugin => $required_version }),
                    $plugin . ' is a runtime recommendation of the plugin bundle',
                );
            }
            else
            {
                # plugin is a core requirement of the bundle
                cmp_deeply(
                    $pluginbundle_meta->{prereqs}{runtime}{requires},
                    superhashof({ $plugin => $required_version }),
                    $plugin . ' is a runtime prereq of the plugin bundle',
                );
            }
        }

        if (not Test::Builder->new->is_passing)
        {
            diag 'got dist metadata: ', explain $dist_meta;
            diag 'got plugin bundle metadata: ', explain $pluginbundle_meta;
        }
    }
} }

# TODO: replace with Test::Deep::notexists($key)
sub notexists
{
    my $key = shift;
    Test::Deep::code(sub {
        !exists $_[0]->{$key} ? 1 : (0, "'$key' key exists");
    });
}

1;
