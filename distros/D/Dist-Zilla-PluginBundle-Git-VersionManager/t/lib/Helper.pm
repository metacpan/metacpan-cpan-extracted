package # hide from PAUSE
    Helper;

use parent 'Exporter';
our @EXPORT = qw(
    all_plugins_in_prereqs
    no_git_tempdir
    git_in_path
);

use Test::More 0.96;
use Test::Deep;
use List::Util 1.45 'uniq';
use Path::Tiny;
use JSON::MaybeXS;
use Moose::Util 'find_meta';
use namespace::clean;

# checks that all plugins in use are in the plugin bundle dist's runtime
# requires list
# - some plugins can be marked 'additional' - must be in recommended prereqs
#   AND the built dist's develop requires list
# - some plugins can be explicitly exempted (added manually to faciliate
#   testing)
# TODO: move into its own distribution
sub all_plugins_in_prereqs
{ SKIP: {
    skip('this test requires a built dist', 1) if not -f 'META.json';

    my ($tzil, %options) = @_;

    my $bundle_name = $options{bundle_name} // '@Git::VersionManager';    # TODO: default to dist we are in
    my %additional = map { $_ => undef } @{ $options{additional} // [] };
    my %exempt = map { $_ => undef } @{ $options{exempt} // [] };

    my $pluginbundle_meta = decode_json(path('META.json')->slurp_raw);
    my $dist_meta = $tzil->distmeta;

    # these are develop-requires prereqs
    my $plugin_name = "$bundle_name/prereqs for $bundle_name";
    my $bundle_plugin_prereqs = $tzil->plugin_named($plugin_name);
    cmp_deeply(
        $bundle_plugin_prereqs,
        methods(
            prereq_phase => 'develop',
            prereq_type => 'requires',
        ),
        "found '$plugin_name' develop-requires prereqs",
    );
    $bundle_plugin_prereqs = $bundle_plugin_prereqs->_prereq;

    subtest 'all plugins in use are specified as *required* runtime prerequisites by the plugin bundle, or develop prerequisites by the distribution' => sub {
        foreach my $plugin (uniq map { find_meta($_)->name }
            grep { $_->plugin_name =~ /^$bundle_name\/[^@]/ } @{$tzil->plugins})
        {
            note($plugin . ' is explicitly exempted; skipping'), next
                if exists $exempt{$plugin};

            # cannot be a (non-develop) prereq if the module lives in this distribution
            next if exists $pluginbundle_meta->{provides}{$plugin};

            # plugins with a specific :version requirement are added to
            # prereqs via an extra injected [Prereqs] plugin
            my $required_version = $bundle_plugin_prereqs->{find_meta($plugin)->name} // 0;

            if (exists $additional{$plugin})
            {
                # plugin was added in via an extra option, therefore the
                # plugin should have been added to develop prereqs, and not be a runtime prereq
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

1;
