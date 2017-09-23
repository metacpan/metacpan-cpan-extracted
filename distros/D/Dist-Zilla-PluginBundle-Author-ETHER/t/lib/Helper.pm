package # hide from PAUSE
    Helper;

use parent 'Exporter';
our @EXPORT = qw(
    @REMOVED_PLUGINS
    assert_no_git
    all_plugins_in_prereqs
    no_git_tempdir
    git_in_path
    notexists
    recursive_child_files
);

use Test::More 0.96;
use Test::Deep;
use List::Util 1.45 'uniq';
use Path::Tiny 0.062;
use JSON::MaybeXS;
use Moose::Util 'find_meta';
use namespace::clean;

$ENV{USER} = 'notether';
delete $ENV{DZIL_AIRPLANE};
delete $ENV{FAKE_RELEASE};

$ENV{HOME} = Path::Tiny->tempdir->stringify;

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
#   AND the built dist's develop suggests list
# - some plugins can be explicitly exempted (added manually to facilitate
#   testing)
# TODO: move into its own distribution
sub all_plugins_in_prereqs
{ SKIP: {
    my ($tzil, %options) = @_;

    my $bundle_name = $options{bundle_name} // '@Author::ETHER';    # TODO: default to dist we are in
    my %additional = map { $_ => undef } @{ $options{additional} // [] };
    my %exempt = map { $_ => undef } @{ $options{exempt} // [] };

    my $pluginbundle_meta = -f 'META.json' ? decode_json(path('META.json')->slurp_raw) : undef;
    my $dist_meta = $tzil->distmeta;

    # these are develop-suggests prereqs
    my $plugin_name = "$bundle_name/prereqs for $bundle_name";
    my $bundle_plugin_prereqs = $tzil->plugin_named($plugin_name);
    cmp_deeply(
        $bundle_plugin_prereqs,
        methods(
            prereq_phase => 'develop',
            prereq_type => 'suggests',
        ),
        "found '$plugin_name' develop-suggests prereqs",
    );
    $bundle_plugin_prereqs = $bundle_plugin_prereqs->_prereq;

    subtest 'all plugins in use are specified as *required* runtime prerequisites by the plugin bundle, or develop-suggests prerequisites by the distribution' => sub {
        foreach my $plugin (uniq map { find_meta($_)->name }
            grep { $_->plugin_name =~ /^$bundle_name\/[^@]/ } @{$tzil->plugins})
        {
            note($plugin . ' is explicitly exempted; skipping'), next
                if exists $exempt{$plugin};

            # cannot be a (non-develop) prereq if the module lives in this distribution
            next if (
                $pluginbundle_meta ? exists $pluginbundle_meta->{provides}{$plugin}
               : do {
                   (my $file = $plugin) =~ s{::}{/}g; $file .= '.pm';
                   path('lib', $file)->exists;
               });

            # plugins with a specific :version requirement are added to
            # prereqs via an extra injected [Prereqs] plugin
            my $required_version = $bundle_plugin_prereqs->{find_meta($plugin)->name} // 0;

            if (exists $additional{$plugin})
            {
                # plugin was added in via an extra option, therefore the
                # plugin should have been added to develop prereqs, and not be a runtime prereq
                ok(
                    exists $dist_meta->{prereqs}{develop}{suggests}{$plugin},
                    $plugin . ' is a develop prereq of the distribution',
                );

                cmp_deeply(
                    $pluginbundle_meta->{prereqs}{runtime}{recommends},
                    superhashof({ $plugin => $required_version }),
                    $plugin . ' is a runtime recommendation of the plugin bundle',
                ) if $pluginbundle_meta;
            }
            else
            {
                # plugin is a core requirement of the bundle
                cmp_deeply(
                    $pluginbundle_meta->{prereqs}{runtime}{requires},
                    superhashof({ $plugin => $required_version }),
                    $plugin . ' is a runtime prereq of the plugin bundle',
                ) if $pluginbundle_meta;
            }
        }

        pass 'this is a token test to keep things humming' if not $pluginbundle_meta;

        if (not Test::Builder->new->is_passing)
        {
            diag 'got dist metadata: ', explain $dist_meta;
            diag 'got plugin bundle metadata: ', explain $pluginbundle_meta;
        }
    }
} }

# provides a temp directory that is guaranteed to not be inside a git repository
# directory is cleaned up when $tempdir goes out of scope
sub no_git_tempdir
{
    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    mkdir $tempdir if not -d $tempdir;    # FIXME: File::Temp::newdir doesn't make the directory?!

    my $in_git = git_in_path($tempdir);
    ok(!$in_git, 'tempdir is not in a real git repository');

    return $tempdir;
}

# checks if a .git directory is in the current or any parent directory
sub git_in_path
{
    my $in_git;
    my $dir = path($_[0]);
    my $count = 0;
    while (not $dir->is_rootdir) {
        # this should never happen.
        do { diag "failed to detect that $dir is at the root?!"; last } if $dir eq $dir->parent;

        my $checkdir = path($dir, '.git');
        if (-d $checkdir) {
            note "found $checkdir in $_[0]";
            $in_git = 1;
            last;
        }
        $dir = $dir->parent;
    }
    continue {
        die "too many iterations when traversing $tempdir!"
            if $count++ > 100;
    }
    return $in_git;
}

# TODO: replace with Test::Deep::notexists($key)
sub notexists
{
    my @keys = @_;
    Test::Deep::code(sub {
        # TODO return 0 unless $self->test_reftype($_[0], 'HASH');
        return (0, 'not a HASH') if ref $_[0] ne 'HASH';
        foreach my $key (@keys) {
            return (0, "'$key' key exists") if exists $_[0]->{$key};
        }
        return 1;
    });
}

# simple Path::Tiny helper: like `find $dir -type f`
sub recursive_child_files
{
    my $dir = shift;
    my @found_files;
    $dir->visit(
        sub { push @found_files, $_->relative($dir)->stringify if -f },
        { recurse => 1 },
    );
    @found_files;
}

1;
