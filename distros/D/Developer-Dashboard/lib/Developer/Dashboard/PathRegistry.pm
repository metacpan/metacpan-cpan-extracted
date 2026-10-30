package Developer::Dashboard::PathRegistry;

use strict;
use warnings;

our $VERSION = '6.06';

use Digest::MD5 qw(md5_hex);
use Errno qw(ENOENT);
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Spec;
use Scalar::Util qw(blessed);
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathIdentity ();

# _resolved_home_from_env()
# Resolves the current user home directory from the available process
# environment in a Windows-safe order.
# Input: none.
# Output: home directory path string or undef when no supported home variables exist.
sub _resolved_home_from_env {
    my $home = $ENV{HOME};
    return $home if defined $home && $home ne '';

    my $userprofile = $ENV{USERPROFILE};
    return $userprofile if defined $userprofile && $userprofile ne '';

    my $homedrive = $ENV{HOMEDRIVE};
    my $homepath  = $ENV{HOMEPATH};
    if ( defined $homedrive && $homedrive ne '' && defined $homepath && $homepath ne '' ) {
        return File::Spec->catdir( $homedrive, $homepath );
    }

    return undef;
}

# new(%args)
# Constructs the logical path registry for the runtime.
# Input: home, app_name, workspace_roots, project_roots, and named_paths.
# Output: Developer::Dashboard::PathRegistry object.
sub new {
    my ( $class, %args ) = @_;

    my $home = $args{home} || _resolved_home_from_env() || die 'Missing home directory';

    my $self = bless {
        home            => $home,
        app_name        => $args{app_name} || 'developer-dashboard',
        cwd             => $args{cwd},
        memo            => {},
        workspace_roots => $args{workspace_roots} || [],
        project_roots   => $args{project_roots} || [],
        named_paths     => $args{named_paths} || {},
    }, $class;

    return $self;
}

# new_from_all_folders()
# Constructs a path registry from the public Folder compatibility inventory.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object.
sub new_from_all_folders {
    my ($class) = @_;
    require Developer::Dashboard::Folder;
    return $class->new( %{ Developer::Dashboard::Folder->all } );
}

# home()
# Returns the configured home directory.
# Input: none.
# Output: home directory path string.
sub home { $_[0]->{home} }

# app_name()
# Returns the runtime application name.
# Input: none.
# Output: application name string.
sub app_name { $_[0]->{app_name} }

# register_named_paths($paths)
# Registers additional logical path aliases.
# Input: hash reference of alias-to-path mappings.
# Output: registry object.
sub register_named_paths {
    my ( $self, $paths ) = @_;
    return $self if ref($paths) ne 'HASH';
    for my $name ( keys %$paths ) {
        next if $name eq '';
        $self->{named_paths}{$name} = $paths->{$name};
    }
    return $self;
}

# unregister_named_path($name)
# Removes a logical path alias from the in-memory registry when present.
# Input: alias name string.
# Output: registry object.
sub unregister_named_path {
    my ( $self, $name ) = @_;
    return $self if !defined $name || $name eq '';
    delete $self->{named_paths}{$name};
    return $self;
}

# named_paths()
# Returns the currently registered logical path aliases as plain path
# strings for display (e.g. "dashboard path list"). DD-1005: a lazy-create
# alias is stored internally as a metadata hash ({path=>,create=>1,mode=>});
# this accessor collapses it to its bare "path" field so callers that only
# ever expected a path string (aliases_table, prefix-matching completion)
# see one, matching every alias registered before this feature existed.
# resolve_dir reads the raw internal hash directly rather than through this
# accessor, so the create/mode metadata is never lost - only hidden from
# display consumers that have no use for it.
# Input: none.
# Output: hash reference of alias-to-path mappings.
sub named_paths {
    my ($self) = @_;
    my %plain;
    for my $name ( keys %{ $self->{named_paths} || {} } ) {
        my $entry = $self->{named_paths}{$name};
        $plain{$name} = ref($entry) eq 'HASH' ? $entry->{path} : $entry;
    }
    return \%plain;
}

# all_paths() and all_path_aliases()
# Return the public hash payloads for the same inventories printed by
# dashboard paths and dashboard path list.
# Input: none.
# Output: hash references describing resolved runtime roots and aliases.

# runtime_root()
# Returns the deepest runtime root, reusing the active operation snapshot when
# one exists; unscoped calls resolve a fresh layer inventory.
# Input: none.
# Output: deepest discovered runtime layer directory, falling back to the home runtime directory.
sub runtime_root {
    my ($self) = @_;
    my $scope = $self->{_runtime_layer_candidate_scope};
    return $scope->{runtime_root} if ref($scope) eq 'HASH' && exists $scope->{runtime_root};

    if ( ref($scope) eq 'HASH' && ref( $scope->{runtime_layers} ) eq 'ARRAY' ) {
        my $runtime_root = $scope->{runtime_layers}[-1];
        $scope->{runtime_root} = $runtime_root;
        return $runtime_root;
    }

    my @layers = $self->runtime_layers;
    my $runtime_root = $layers[-1];
    $scope->{runtime_root} = $runtime_root if ref($scope) eq 'HASH';
    return $runtime_root;
}

# home_runtime_root()
# Returns the home-backed runtime root directory.
# Input: none.
# Output: home runtime directory path string.
sub home_runtime_root {
    my ($self) = @_;
    return $self->_ensure_dir( $self->home_runtime_path );
}

# _layer_dir_for($parent)
# Resolves which directory name a runtime layer under $parent actually uses:
# .developer-dashboard if it exists, .d2 as a fallback when only .d2 exists
# (DD-809), or .developer-dashboard's path when NEITHER exists yet - a fresh
# layer is always created under the long name, never the alias, so this is
# the write-target name too, not only a read-time lookup.
# Within a runtime-layer operation scope, reuse the first name choice for a
# parent so all lookups in that operation see one consistent filesystem view.
# Input: required non-empty parent directory path string.
# Output: full layer directory path string (may not exist on disk).
sub _layer_dir_for {
    my ( $self, $parent ) = @_;
    die "Runtime layer parent path is required\n"
      if !defined $parent || ref($parent) || $parent eq '';

    my $scope = $self->{_runtime_layer_candidate_scope};
    my $cache;
    if ( ref($scope) eq 'HASH' ) {
        $cache = $scope->{layer_dir_for} ||= {};
        return $cache->{$parent} if exists $cache->{$parent};
    }

    my $primary = File::Spec->catdir( $parent, '.developer-dashboard' );
    my $selected = $primary;
    if ( !-d $primary ) {
        my $alias = File::Spec->catdir( $parent, '.d2' );
        $selected = $alias if -d $alias;
    }
    $cache->{$parent} = $selected if $cache;
    return $selected;
}

# _existing_layer_dirs_for($parent)
# Returns both existing runtime directory names at one filesystem level in
# canonical-first order; runtime_layers preserves alias-before-canonical
# lookup order so the canonical directory remains the effective write target.
# Within an explicit runtime-layer operation scope, reuses that parent's
# existence snapshot; unscoped calls always observe current filesystem state.
# Input: required non-empty parent directory path string.
# Output: existing .developer-dashboard and/or .d2 directory paths.
sub _existing_layer_dirs_for {
    my ( $self, $parent ) = @_;
    die "Runtime layer parent path is required\n"
      if !defined $parent || ref($parent) || $parent eq '';
    my $scope = $self->{_runtime_layer_candidate_scope};
    if ( ref($scope) eq 'HASH' ) {
        my $key = 'S' . $parent;
        my $snapshots = $scope->{existing_layer_dirs} ||= {};
        return @{ $snapshots->{$key} } if exists $snapshots->{$key};
    }

    my $primary = File::Spec->catdir( $parent, '.developer-dashboard' );
    my $alias   = File::Spec->catdir( $parent, '.d2' );
    my @existing = grep { -d $_ } ( $primary, $alias );
    if ( ref($scope) eq 'HASH' ) {
        my $key = 'S' . $parent;
        $scope->{existing_layer_dirs}{$key} = \@existing;
    }
    return @existing;
}

# home_runtime_path()
# Returns the selected home-backed runtime root path without creating it.
# Input: none.
# Output: home runtime directory path string.
sub home_runtime_path {
    my ($self) = @_;
    return $self->_layer_dir_for( $self->home );
}

# project_runtime_root()
# Returns the active project-local runtime root when the project already contains one.
# Input: none.
# Output: project-local runtime directory path string or undef when absent.
sub project_runtime_root {
    my ($self) = @_;
    my $repo = $self->current_project_root or return;
    my $home_runtime = $self->_layer_dir_for( $self->home );
    return if $repo eq $home_runtime;
    my $root = $self->_layer_dir_for($repo);
    return -d $root ? $root : undef;
}

# runtime_roots()
# Returns the effective runtime roots in lookup order.
# Input: none.
# Output: ordered list of runtime root directory path strings from deepest layer to home fallback.
sub runtime_roots {
    my ($self) = @_;
    return reverse $self->runtime_layers;
}

# alias_cache_key($paths)
# Builds the cache key that tells configured-alias consumers whether the runtime
# layout they cached against is still the current one. Shared by File.pm and
# Folder.pm, which each carried a byte-identical copy of this computation before
# DD-616; it lives here because the value is derived entirely from a paths object
# and both callers already load this module.
# Called as a plain function, not a method, because it must return an empty key
# for a missing or unblessed argument rather than dying on a method call.
# Input: a Developer::Dashboard::PathRegistry object, or any value at all.
# Output: newline-joined project root and runtime roots, or the empty string when
#         the argument is not a blessed object or its accessors fail.
sub alias_cache_key {
    my ($paths) = @_;
    return '' if !$paths || !blessed($paths);
    my $project_root  = eval { $paths->current_project_root } || '';
    my @runtime_roots = eval { $paths->runtime_roots };
    return join "\n", $project_root, @runtime_roots;
}

# runtime_layers()
# Returns the effective runtime roots in inheritance order from home to the
# current working directory, including both sibling names when both exist.
# Reuses a result only when the caller has established an operation-local
# _runtime_layer_candidate_scope; unscoped calls rescan so a retained registry
# sees runtime-layer creation/removal between requests.
# Input: none; reads the current environment and runtime-layer filesystem.
# Output: ordered list of runtime root directory path strings from home to deepest layer.
sub runtime_layers {
    my ($self) = @_;
    my $scope = $self->{_runtime_layer_candidate_scope};
    return @{ $scope->{runtime_layers} }
      if ref($scope) eq 'HASH' && exists $scope->{runtime_layers};

    my @roots;
    my %seen;
    my @home_layers = $self->_existing_layer_dirs_for( $self->home );
    @home_layers = reverse @home_layers;
    for my $root ( $self->_runtime_layers_from_env, @home_layers, $self->home_runtime_root, $self->_ancestor_runtime_layers_for_scope ) {
        next if $root eq '';
        my $identity = $self->_path_identity($root);
        next if $seen{$identity}++;
        push @roots, $root;
    }

    $scope->{runtime_layers} = \@roots if ref($scope) eq 'HASH';
    return @roots;
}

# state_root()
# Returns the state root directory.
# Input: none.
# Output: directory path string.
sub state_root {
    my ($self) = @_;
    my $dir = File::Spec->catdir( $self->state_base_root, $self->_state_root_key( $self->runtime_root ) );
    # _write_state_metadata creates and hardens this directory before touching
    # its metadata file; do not repeat that same permission check here.
    $self->_write_state_metadata( $dir, $self->runtime_root );
    return $dir;
}

# state_base_root()
# Returns the stable base directory for runtime state roots.
# Input: none.
# Output: directory path string.
sub state_base_root {
    my ($self) = @_;
    if ( my $root = $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} ) {
        return $self->_ensure_state_dir( $self->_expand_home($root) );
    }
    return $self->_ensure_state_dir(
        File::Spec->catdir( File::Spec->tmpdir, $self->_state_root_user, $self->app_name, 'state' )
    );
}

# cache_root()
# Returns the cache root directory.
# Input: none.
# Output: directory path string.
sub cache_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'cache' ) );
}

# home_cache_root()
# Returns the home-layer cache root directory, ignoring any deeper runtime
# layer. Per-user artifacts that a fixed external consumer reads from one
# well-known path - such as the generated shell-startup caches a login profile
# dot-sources - must not follow the working directory into a project layer,
# because the consumer would then read a cache no refresh ever rewrites.
# Input: none.
# Output: directory path string.
sub home_cache_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->home_runtime_root, 'cache' ) );
}

# logs_root()
# Returns the logs root directory.
# Input: none.
# Output: directory path string.
sub logs_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'logs' ) );
}

# dashboards_root()
# Returns the dashboards/bookmarks root directory.
# Input: none.
# Output: directory path string.
sub dashboards_root {
    my ($self) = @_;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} ) {
        return $self->_ensure_dir( $self->_expand_home($dir) );
    }
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'dashboards' ) );
}

# dashboards_roots()
# Returns the bookmark roots in effective lookup order.
# Input: none.
# Output: ordered list of bookmark root directory path strings.
sub dashboards_roots {
    my ($self) = @_;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} ) {
        return ( $self->_ensure_dir( $self->_expand_home($dir) ) );
    }
    return map { File::Spec->catdir( $_, 'dashboards' ) } $self->runtime_roots;
}

# dashboards_layers()
# Returns the bookmark roots in inheritance order from home to deepest layer.
# Input: none.
# Output: ordered list of bookmark root directory path strings.
sub dashboards_layers {
    my ($self) = @_;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} ) {
        return ( $self->_ensure_dir( $self->_expand_home($dir) ) );
    }
    return map { File::Spec->catdir( $_, 'dashboards' ) } $self->runtime_layers;
}

# bookmarks()
# Returns the older bookmark directory alias.
# Input: none.
# Output: directory path string.
sub bookmarks {
    my ($self) = @_;
    return $self->dashboards_root;
}

# bookmarks_root()
# Returns the older bookmark root alias.
# Input: none.
# Output: directory path string.
sub bookmarks_root {
    my ($self) = @_;
    return $self->dashboards_root;
}

# all_paths()
# Returns the full runtime path inventory used by C<dashboard paths>.
# Input: none.
# Output: hash reference describing the active runtime path set plus named aliases.
sub all_paths {
    my ($self) = @_;
    # The aggregate inventory performs several permission checks for paths
    # derived from the same runtime tree. Share only the candidate list during
    # this call; the registry does not retain it, so a later operation sees
    # runtime layers created or removed since this inventory was requested.
    # Reuse an enclosing request's candidate scope when present. A nested
    # aggregate read should share that request's ancestor scan, while a
    # standalone call still gets a fresh scope that expires on return.
    local $self->{_runtime_layer_candidate_scope} =
      ref( $self->{_runtime_layer_candidate_scope} ) eq 'HASH'
      ? $self->{_runtime_layer_candidate_scope}
      : {};
    # The same exact filesystem paths are normalized repeatedly while deriving
    # this one immutable payload. Keep those identities local to this call;
    # later lookups must re-read the filesystem and observe symlink changes.
    local $self->{_path_identity_scope} = {};
    my $state_root = $self->state_root;
    my $collectors_root = $self->_ensure_state_dir(
        File::Spec->catdir( $state_root, 'collectors' )
    );
    my $indicators_root = $self->_ensure_state_dir(
        File::Spec->catdir( $state_root, 'indicators' )
    );

    return {
        home                 => $self->home,
        home_runtime_root    => $self->home_runtime_root,
        project_runtime_root => scalar $self->project_runtime_root,
        runtime_root         => $self->runtime_root,
        state_root           => $state_root,
        cache_root           => $self->cache_root,
        logs_root            => $self->logs_root,
        dashboards_root      => $self->dashboards_root,
        bookmarks_root       => $self->bookmarks_root,
        cli_root             => $self->cli_root,
        collectors_root      => $collectors_root,
        indicators_root      => $indicators_root,
        config_root          => $self->config_root,
        current_project_root => scalar $self->current_project_root,
        %{ $self->named_paths },
    };
}

# all_path_aliases()
# Returns the runtime path inventory used by C<dashboard path list>.
# Input: none.
# Output: hash reference of standard runtime aliases plus named aliases.
sub all_path_aliases {
    my ($self) = @_;
    return {
        home            => $self->home,
        home_runtime    => $self->home_runtime_root,
        project_runtime => scalar $self->project_runtime_root,
        runtime         => $self->runtime_root,
        state           => $self->state_root,
        cache           => $self->cache_root,
        logs            => $self->logs_root,
        dashboards      => $self->dashboards_root,
        bookmarks       => $self->bookmarks_root,
        cli             => $self->cli_root,
        config          => $self->config_root,
        collectors      => $self->collectors_root,
        indicators      => $self->indicators_root,
        %{ $self->named_paths },
    };
}

# cli_root()
# Returns the user CLI extension directory.
# Input: none.
# Output: directory path string.
sub cli_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'cli' ) );
}

# cli_roots()
# Returns the CLI extension roots in effective lookup order.
# Input: none.
# Output: ordered list of CLI root directory path strings.
sub cli_roots {
    my ($self) = @_;
    return map { File::Spec->catdir( $_, 'cli' ) } $self->runtime_roots;
}

# cli_layers()
# Returns the CLI extension roots in inheritance order from home to deepest
# layer.
# Input: none.
# Output: ordered list of CLI root directory path strings.
sub cli_layers {
    my ($self) = @_;
    return map { File::Spec->catdir( $_, 'cli' ) } $self->runtime_layers;
}

# skills_root()
# Returns the writable skill root for the deepest participating DD-OOP-LAYER.
# Input: none.
# Output: directory path string.
sub skills_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'skills' ) );
}

# skills_roots( runtime_roots => $array_ref )
# Returns installed skill roots in effective lookup order, using a supplied
# runtime-root snapshot when an enclosing operation already computed one.
# Input: optional named runtime_roots array reference; omitted calls discover roots.
# Output: ordered list of skill root directory path strings.
sub skills_roots {
    my ( $self, %args ) = @_;
    my @runtime_roots = ref( $args{runtime_roots} ) eq 'ARRAY'
      ? @{ $args{runtime_roots} }
      : $self->runtime_roots;
    return map { File::Spec->catdir( $_, 'skills' ) } @runtime_roots;
}

# _skill_is_disabled($skill_root)
# Checks whether one installed skill has a disabled marker at its root.
# Input: installed skill directory path string.
# Output: boolean true when its .disabled marker is a regular file.
sub _skill_is_disabled {
    my ( $self, $skill_root ) = @_;
    return 0 if !defined $skill_root || $skill_root eq '';
    return -f File::Spec->catfile( $skill_root, '.disabled' ) ? 1 : 0;
}

# validated_path_segments($path)
# Splits one untrusted relative path into its separator-delimited segments and
# rejects every shape that could escape the directory the caller joins it onto,
# because File::Spec->catfile/catdir never collapse parent-directory components.
# Input: candidate relative path string sourced from browser or CLI input.
# Output: list of validated segments (segment count in scalar context), or an
# empty list (undef in scalar context) when the path is missing, contains a NUL
# or other control byte, a backslash separator, is absolute, carries a Windows
# drive prefix, or holds any empty, current-directory, or parent-directory
# segment.
sub validated_path_segments {
    my ($path) = @_;
    return if !defined $path || $path eq '';
    return if $path =~ /[\x00-\x1F\x7F]/;
    return if $path =~ /\\/;
    return if File::Spec->file_name_is_absolute($path);
    return if $path =~ /\A[A-Za-z]:/;
    my @segments = split m{/+}, $path, -1;
    return if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @segments;
    return @segments;
}

# skill_root($name)
# Returns the isolated root directory for one installed skill.
# Input: skill repository name string.
# Output: directory path string.
sub skill_root {
    my ( $self, $name ) = @_;
    die 'Missing skill name' if !defined $name || $name eq '';
    return $self->_ensure_dir( File::Spec->catdir( $self->skills_root, $name ) );
}

# skill_layers($name)
# Returns the installed roots for one skill in inheritance order from home to
# the deepest participating layer. A disabled deepest layer masks the whole
# skill from normal runtime lookup. The name is joined straight onto each
# skills root, so any name that is not exactly one validated path segment
# resolves to no layer at all instead of escaping the skills tree.
# An explicit installed-skill inventory scope reuses pure segment validation
# and directory-name membership, but still rechecks each directory and its
# disabled marker on every lookup. Calls outside that scope remain fresh.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from home to leaf.
sub skill_layers {
    my ( $self, $name, %args ) = @_;
    return () if !defined $name || $name eq '';
    my $inventory_scope = $self->{_installed_skill_inventory_scope};
    my $segment_cache = ref($inventory_scope) eq 'HASH'
      ? ( $inventory_scope->{skill_layer_segments} ||= {} )
      : undef;
    my @name_segments;
    if ( ref($segment_cache) eq 'HASH' && !ref($name) && exists $segment_cache->{$name} ) {
        @name_segments = @{ $segment_cache->{$name} };
    }
    else {
        @name_segments = validated_path_segments($name);
        $segment_cache->{$name} = [@name_segments]
          if ref($segment_cache) eq 'HASH' && !ref($name) && length($name) <= 4096
          && keys(%{$segment_cache}) < 512;
    }
    return () if @name_segments != 1;

    my @matches;
    my $saw_effective = 0;
    my @skill_roots;
    if ( ref($inventory_scope) eq 'HASH' ) {
        for my $directory ( $self->_installed_skill_directory_inventory ) {
            my $name_set = $directory->{name_set};
            $name_set = { map { $_ => 1 } @{ $directory->{names} || [] } }
              if ref($name_set) ne 'HASH';
            next if !$name_set->{$name};
            push @skill_roots, File::Spec->catdir( $directory->{skills_root}, $name );
        }
    }
    else {
        @skill_roots = map { File::Spec->catdir( $_, $name ) } $self->skills_roots;
    }

    for my $skill_root (@skill_roots) {
        next if !-d $skill_root;
        my $disabled = -f File::Spec->catfile( $skill_root, '.disabled' ) ? 1 : 0;
        if ( !$saw_effective++ ) {
            return () if !$args{include_disabled} && $disabled;
        }
        next if !$args{include_disabled} && $disabled;
        push @matches, $skill_root;
    }

    return reverse @matches;
}

# skill_roots_for($name)
# Returns the installed roots for one skill in lookup order from the deepest
# participating layer back to home.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from leaf to home.
sub skill_roots_for {
    my ( $self, $name, %args ) = @_;
    return reverse $self->skill_layers( $name, %args );
}

# _installed_skill_directory_inventory()
# Discovers the sorted top-level skill directory names for each runtime skills
# root. When a caller establishes an inventory scope, these directory listings
# are shared only for that caller's current operation; disabled markers remain
# checked by each higher-level consumer. Each record contains ordered names and
# a membership hash for repeated exact-name lookups.
# Input: none.
# Output: ordered list of hash references with skills_root, names, and name_set fields.
sub _installed_skill_directory_inventory {
    my ($self) = @_;
    my $scope = $self->{_installed_skill_inventory_scope};
    if ( ref($scope) eq 'HASH' && exists $scope->{directories} ) {
        return @{ $scope->{directories} };
    }

    my @directories;
    for my $skills_root ( $self->skills_roots ) {
        next if !-d $skills_root;
        opendir my $dh, $skills_root or die "Unable to read $skills_root: $!";
        my @names = sort grep {
               $_ ne '.'
            && $_ ne '..'
            && -d File::Spec->catdir( $skills_root, $_ )
        } readdir $dh;
        closedir $dh or die "Unable to close $skills_root: $!";
        push @directories, {
            skills_root => $skills_root,
            names       => \@names,
            name_set    => { map { $_ => 1 } @names },
        };
    }

    $scope->{directories} = \@directories if ref($scope) eq 'HASH';
    return @directories;
}

# installed_skill_roots()
# Returns every installed skill root in deterministic sorted order.
# Input: none.
# Output: ordered list of installed skill root directory path strings.
sub installed_skill_roots {
    my ( $self, %args ) = @_;
    my @roots;
    my %seen_names;
    for my $directory ( $self->_installed_skill_directory_inventory ) {
        my $skills_root = $directory->{skills_root};
        for my $entry ( @{ $directory->{names} } ) {
            next if $seen_names{$entry}++;
            my $skill_root = File::Spec->catdir( $skills_root, $entry );
            my $disabled = !$args{include_disabled}
              && -f File::Spec->catfile( $skill_root, '.disabled' ) ? 1 : 0;
            next if !$args{include_disabled} && $disabled;
            push @roots, $skill_root;
        }
    }
    return @roots;
}

# installed_skill_entries(%args)
# Enumerates each installed skill once together with all of its layer paths in
# the same precedence order used by skill_layers(), avoiding one roots
# traversal per skill when callers need layered metadata for the fleet.
# Input: optional include_disabled boolean matching installed_skill_roots().
# Output: ordered list of hash refs with skill_name, deepest skill_root, and
# layers ordered from home to the deepest runtime layer.
sub installed_skill_entries {
    my ( $self, %args ) = @_;
    my ( @entries, %by_name );

    for my $directory ( $self->_installed_skill_directory_inventory ) {
        my $skills_root = $directory->{skills_root};
        for my $name ( @{ $directory->{names} } ) {
            my $root = File::Spec->catdir( $skills_root, $name );
            my $disabled = -f File::Spec->catfile( $root, '.disabled' ) ? 1 : 0;
            my $entry = $by_name{$name};
            if ( !$entry ) {
                $entry = {
                    skill_name => $name,
                    skill_root => $root,
                    layers     => [],
                    masked     => $disabled && !$args{include_disabled} ? 1 : 0,
                };
                $by_name{$name} = $entry;
                push @entries, $entry;
            }

            next if $entry->{masked};
            next if !$args{include_disabled} && $disabled;
            push @{ $entry->{layers} }, $root;
        }
    }

    my @visible;
    for my $entry (@entries) {
        next if !@{ $entry->{layers} };
        $entry->{layers} = [ reverse @{ $entry->{layers} } ];
        delete $entry->{masked};
        push @visible, $entry;
    }
    return @visible;
}

# nested_skill_dir_chain(\@segments)
# Resolves a skill-depth path (DD-1004) - one or more dotted alias-name
# segments such as ["foo","bar"] from "foo.bar.something" - to the chain of
# on-disk skill directories it names, recursing into each skill's own nested
# skills/ subdirectory arbitrarily deep: skills/foo, then
# skills/foo/skills/bar, and so on. The first segment is resolved the normal
# layered way (skill_layers, deepest participating layer wins, same as every
# other flat skill lookup); every subsequent segment is a single directory
# lookup inside the previous segment's own "skills" subdirectory, because a
# nested skill-in-skill is not itself independently layered across DD-OOP
# roots - it lives wherever its parent skill's tree put it.
# Input: array reference of one or more skill-name segments.
# Output: ordered list of directory path strings, chain[0] the first
# segment's skill root through chain[-1] the deepest segment's directory, in
# the same order as the input segments; empty list when the array reference
# is missing/empty or any segment fails to resolve to an installed directory.
sub nested_skill_dir_chain {
    my ( $self, $segments ) = @_;
    return () if ref($segments) ne 'ARRAY' || !@{$segments};
    my @segs = @{$segments};

    my $first = shift @segs;
    my @first_layers = $self->skill_layers( $first, include_disabled => 1 );
    return () if !@first_layers;
    my $dir = $first_layers[-1];    # deepest participating layer for the first segment
    my @chain = ($dir);

    for my $seg (@segs) {
        my @seg_ok = validated_path_segments($seg);
        return () if @seg_ok != 1;
        my $candidate = File::Spec->catdir( $dir, 'skills', $seg );
        return () if !-d $candidate;
        $dir = $candidate;
        push @chain, $dir;
    }

    return @chain;
}

# nested_skill_entries(%args)
# Recursively discovers every installed skill directory reachable by walking
# into "skills/" subdirectories arbitrarily deep, starting from each
# top-level installed_skill_roots() entry (DD-1004 read-side counterpart to
# nested_skill_dir_chain, shared so discovery never drifts from resolution).
# Input: optional include_disabled flag and include_config_write_location flag.
# Output: ordered list of hash refs {segments => arrayref of skill-name
# segments from the top down, dir => that skill's directory path string;
# when requested, config_write_location contains the safe write target
# derived from this already-discovered chain; include_disabled entries also
# identify disabled skills and descendants}. Entries cover every depth,
# shallowest first.
sub nested_skill_entries {
    my ( $self, %args ) = @_;
    my @entries;
    my @queue = map {
        my $name = ( $_ =~ m{/([^/]+)\z} )[0];
        my @valid = $args{include_config_write_location} ? validated_path_segments($name) : ();
        {
            segments           => [$name],
            dir                => $_,
            config_chain_valid => !$args{include_config_write_location} || @valid == 1 ? 1 : 0,
            config_parent_dir  => undef,
            config_parent_depth => undef,
            disabled           => $args{include_disabled}
              && $self->_skill_is_disabled($_) ? 1 : 0,
        }
    } $self->installed_skill_roots(%args);
    for ( my $queue_index = 0; $queue_index < @queue; $queue_index++ ) {
        my $node = $queue[$queue_index];
        my %entry = ( segments => $node->{segments}, dir => $node->{dir} );
        $entry{disabled} = $node->{disabled} ? 1 : 0 if $args{include_disabled};
        if ( $args{include_config_write_location} ) {
            if ( $node->{config_chain_valid} ) {
                if ( @{ $node->{segments} } == 1 || !defined $node->{config_parent_dir} ) {
                    $entry{config_write_location} = {
                        kind      => 'global',
                        remaining => [ @{ $node->{segments} } ],
                    };
                }
                else {
                    my @remaining = @{ $node->{segments} }[ $node->{config_parent_depth} + 1 .. $#{ $node->{segments} } ];
                    $entry{config_write_location} = {
                        kind      => 'skill',
                        dir       => $node->{config_parent_dir},
                        remaining => \@remaining,
                    };
                }
            }
            else {
                $entry{config_write_location} = undef;
            }
        }
        push @entries, \%entry;
        my $nested_root = File::Spec->catdir( $node->{dir}, 'skills' );
        next if !-d $nested_root;
        opendir my $dh, $nested_root or next;
        my $has_git = $args{include_config_write_location}
          && $node->{config_chain_valid}
          ? ( -d File::Spec->catdir( $node->{dir}, '.git' ) ? 1 : 0 )
          : 0;
        my ( $child_parent_dir, $child_parent_depth ) = ( $node->{config_parent_dir}, $node->{config_parent_depth} );
        if ( $args{include_config_write_location} && $node->{config_chain_valid} && !$has_git ) {
            ( $child_parent_dir, $child_parent_depth ) = ( $node->{dir}, $#{ $node->{segments} } );
        }
        for my $child ( sort grep { $_ ne '.' && $_ ne '..' && -d File::Spec->catdir( $nested_root, $_ ) } readdir $dh ) {
            my $child_dir = File::Spec->catdir( $nested_root, $child );
            my $disabled = $node->{disabled} || -f File::Spec->catfile( $child_dir, '.disabled' ) ? 1 : 0;
            next if !$args{include_disabled} && $disabled;
            my @valid = $args{include_config_write_location} ? validated_path_segments($child) : ();
            push @queue, {
                segments            => [ @{ $node->{segments} }, $child ],
                dir                 => $child_dir,
                config_chain_valid  => !$args{include_config_write_location}
                  || ( $node->{config_chain_valid} && @valid == 1 ) ? 1 : 0,
                config_parent_dir   => $child_parent_dir,
                config_parent_depth => $child_parent_depth,
                disabled            => $disabled,
            };
        }
        closedir $dh;
    }
    return @entries;
}

# skill_config_write_location(\@segments)
# Resolves WHERE the config for a skill-depth path may safely be written
# (DD-1004). Owner's rule, given unconditionally (Q-182, generalising the
# original .git-only framing): a skill's OWN config.json is NEVER the write
# target, at any depth, regardless of whether that skill itself carries a
# .git - "if the alias already exists in the skill's own config.json, do not
# change it; save to the non-.git PARENT instead, and that overrides the
# skill's own value at read time, while the skill's file stays untouched."
# So the walk always starts one level ABOVE the deepest resolved segment
# (the target's parent), looking for the nearest ancestor with no .git of
# its own, continuing past any ancestor that itself carries a .git exactly
# as the original git-preservation rule described; a depth-1 target has no
# parent skill at all, so it falls straight through to the global config
# fallback unconditionally. Falls all the way through to the global config
# root when every ancestor (or there simply are none, for depth-1) carries a
# .git or does not exist.
# Input: array reference of one or more skill-name segments.
# Output: hash reference - either {kind => 'skill', dir => stopping skill
# directory (always a PARENT of the target, never the target itself),
# remaining => arrayref of the segments BELOW that directory (the nesting
# still owed inside its config.json)}, or {kind => 'global', remaining =>
# arrayref of the FULL segment list} when no git-free parent ancestor exists
# (including the depth-1 case, which has none by construction); undef when
# the segments do not resolve to an installed skill chain at all.
sub skill_config_write_location {
    my ( $self, $segments ) = @_;
    return if ref($segments) ne 'ARRAY' || !@{$segments};
    my @chain = $self->nested_skill_dir_chain($segments);
    return $self->_skill_config_write_location_from_chain( $segments, \@chain );
}

# _skill_config_write_location_from_chain($segments, $chain)
# Finds the safe config write ancestor from an already-resolved skill chain.
# Input: skill path segments and corresponding existing skill directories.
# Output: skill/global write-location hash reference, or undef for an invalid chain.
sub _skill_config_write_location_from_chain {
    my ( $self, $segments, $chain ) = @_;
    return if ref($segments) ne 'ARRAY' || !@{$segments};
    return if ref($chain) ne 'ARRAY' || @{$chain} != @{$segments};

    for my $index ( 0 .. $#{$segments} ) {
        my @valid = validated_path_segments( $segments->[$index] );
        return if @valid != 1;
        return if !defined $chain->[$index] || !-d $chain->[$index];
        if ( $index == 0 ) {
            return if basename( $chain->[$index] ) ne $segments->[$index];
        }
        else {
            my $expected = File::Spec->catdir( $chain->[ $index - 1 ], 'skills', $segments->[$index] );
            return if $chain->[$index] ne $expected;
        }
    }

    for ( my $i = $#{$chain} - 1; $i >= 0; $i-- ) {
        my $dir = $chain->[$i];
        next if -d File::Spec->catdir( $dir, '.git' );
        my @remaining = @{$segments}[ $i + 1 .. $#{$segments} ];
        return { kind => 'skill', dir => $dir, remaining => \@remaining };
    }

    return { kind => 'global', remaining => [ @{$segments} ] };
}

# installed_skill_docker_roots()
# Returns the config/docker roots contributed by installed skills in deterministic sorted order.
# Input: none.
# Output: ordered list of skill docker configuration root directory path strings.
sub installed_skill_docker_roots {
    my ( $self, %args ) = @_;
    return map { File::Spec->catdir( $_, 'config', 'docker' ) } $self->installed_skill_roots(%args);
}

# installed_skill_docker_roots_for_runtime($runtime_root)
# Returns the effective installed skill docker roots that belong to one runtime layer.
# Input: runtime root directory path and optional include_disabled flag.
# Output: ordered list of skill docker configuration root directory path strings for that layer.
sub installed_skill_docker_roots_for_runtime {
    my ( $self, $runtime_root, %args ) = @_;
    return () if !defined $runtime_root || $runtime_root eq '';
    my $skills_root = File::Spec->catdir( $runtime_root, 'skills' );
    my $prefix = $skills_root . '/';
    return map { File::Spec->catdir( $_, 'config', 'docker' ) }
      grep { index( $_, $prefix ) == 0 } $self->installed_skill_roots(%args);
}

# collectors_root()
# Returns the collectors state root directory.
# Input: none.
# Output: directory path string.
sub collectors_root {
    my ($self) = @_;
    return $self->_ensure_state_dir( File::Spec->catdir( $self->state_root, 'collectors' ) );
}

# collectors_roots()
# Returns the collector state roots in lookup order from deepest layer to home.
# Input: none.
# Output: ordered list of collector state root directory path strings.
sub collectors_roots {
    my ($self) = @_;
    return map {
        $self->_ensure_state_dir( File::Spec->catdir( $self->_state_root_for_layer($_), 'collectors' ) )
    } $self->runtime_roots;
}

# indicators_root()
# Returns the indicators state root directory.
# Input: none.
# Output: directory path string.
sub indicators_root {
    my ($self) = @_;
    return $self->_ensure_state_dir( File::Spec->catdir( $self->state_root, 'indicators' ) );
}

# indicators_roots()
# Returns the indicator state roots in lookup order from deepest layer to home.
# Input: none.
# Output: ordered list of indicator state root directory path strings.
sub indicators_roots {
    my ($self) = @_;
    return map {
        $self->_ensure_state_dir( File::Spec->catdir( $self->_state_root_for_layer($_), 'indicators' ) )
    } $self->runtime_roots;
}

# sessions_root()
# Returns the sessions state root directory.
# Input: none.
# Output: directory path string.
sub sessions_root {
    my ($self) = @_;
    return $self->_ensure_state_dir( File::Spec->catdir( $self->state_root, 'sessions' ) );
}

# sessions_roots()
# Returns the session storage roots in effective lookup order.
# Input: none.
# Output: ordered list of session root directory path strings.
sub sessions_roots {
    my ($self) = @_;
    return map {
        $self->_ensure_state_dir( File::Spec->catdir( $self->_state_root_for_layer($_), 'sessions' ) )
    } $self->runtime_roots;
}

# _state_root_key($runtime_root)
# Returns the key for a runtime layer-specific state directory.
# Input: runtime layer path string.
# Output: directory name string.
sub _state_root_key {
    my ( $self, $runtime_root ) = @_;
    my $identity = $self->_path_identity($runtime_root);
    return md5_hex($identity);
}

# _state_root_user()
# Returns a sanitized username used to namespace runtime state roots in the shared temp area.
# The chain reads the interactive Unix variables, then the Windows USERNAME
# variable a non-interactive Windows session still carries, then the guarded
# passwd lookup, so no runtime can abort here. The resolved value is cached per
# instance for the exact four environment values, avoiding repeated passwd
# database calls while still observing environment changes.
# Input: none.
# Output: username string.
sub _state_root_user {
    my ($self) = @_;
    my @environment = @ENV{qw(DD_STATE_ROOT_USER USER LOGNAME USERNAME)};
    my $cached = $self->{_state_root_user_cache};
    if ( ref($cached) eq 'HASH' && ref( $cached->{environment} ) eq 'ARRAY' ) {
        my $same_environment = 1;
        for my $index ( 0 .. $#environment ) {
            my $current = $environment[$index];
            my $previous = $cached->{environment}[$index];
            next if !defined $current && !defined $previous;
            if ( !defined $current || !defined $previous || $current ne $previous ) {
                $same_environment = 0;
                last;
            }
        }
        return $cached->{user} if $same_environment;
    }

    my $raw =
         $ENV{DD_STATE_ROOT_USER}
      || $ENV{USER}
      || $ENV{LOGNAME}
      || $ENV{USERNAME}
      || _passwd_user_name();
    $raw = 'user' if !$raw;
    $raw =~ s{[^A-Za-z0-9._-]}{_}g;
    $self->{_state_root_user_cache} = {
        environment => \@environment,
        user        => $raw,
    };
    return $raw;
}

# _passwd_user_name()
# Reads the effective account name from the system passwd database without
# loading the larger platform helper module on lightweight path commands.
# Input: none; the effective numeric user id is read from Perl's $< variable.
# Output: passwd account name, or undef when the platform lookup is unavailable.
sub _passwd_user_name {
    my @entry = eval { _passwd_entry($<) };
    return @entry ? $entry[0] : undef;
}

# _passwd_entry($uid)
# Reads one passwd record while leaving platform-specific exceptions visible to
# the guarded caller, which converts an unavailable lookup to undef.
# Input: numeric user id.
# Output: passwd record fields, or an exception for unsupported lookups.
sub _passwd_entry {
    my ($uid) = @_;
    return getpwuid($uid);
}

# _state_root_for_layer($runtime_root)
# Returns the full state root for a runtime layer.
# Input: runtime layer path string.
# Output: directory path string.
sub _state_root_for_layer {
    my ( $self, $runtime_root ) = @_;
    my $dir = File::Spec->catdir( $self->state_base_root, $self->_state_root_key($runtime_root) );
    # _write_state_metadata owns creation and hardening for this directory.
    $self->_write_state_metadata( $dir, $runtime_root );
    return $dir;
}

# _write_state_metadata($dir, $runtime_root)
# Records the runtime identity for one hashed temp-state root, recreating the
# hashed directory first if temp cleanup removed it. It skips unchanged metadata
# only after verifying file type, owner, mode, and content; missing or stale
# files are repaired and symlinks are rejected. The encoded JSON scalar is
# reused for the most recent exact runtime-root/application-name pair.
# Input: state root directory path and originating runtime root path.
# Output: metadata file path string.
sub _write_state_metadata {
    my ( $self, $dir, $runtime_root ) = @_;
    return '' if !defined $dir || $dir eq '';
    return '' if !defined $runtime_root || $runtime_root eq '';
    $self->_ensure_state_dir($dir);
    my $file = File::Spec->catfile( $dir, 'runtime.json' );
    my $app_name = $self->app_name;
    my $content_cache = $self->{_state_metadata_json_cache};
    my $content;
    if (
        ref($content_cache) eq 'HASH'
        && defined $content_cache->{runtime_root}
        && defined $content_cache->{content}
        && $content_cache->{runtime_root} eq $runtime_root
        && (
            !defined $app_name
            ? !defined $content_cache->{app_name}
            : defined $content_cache->{app_name} && $content_cache->{app_name} eq $app_name
        )
      ) {
        $content = $content_cache->{content};
    }
    else {
        $content = json_encode(
            {
                runtime_root => $runtime_root,
                app_name     => $app_name,
            }
        );
        $self->{_state_metadata_json_cache} = {
            runtime_root => $runtime_root,
            app_name     => $app_name,
            content      => $content,
        };
    }

    $! = 0;
    my @metadata_stat = _state_metadata_lstat($file);
    die "Unable to inspect runtime metadata $file: $!" if !@metadata_stat && $! != ENOENT;
    if (@metadata_stat) {
        # The preceding lstat populated Perl's cached stat record; these file
        # tests inspect it without importing Fcntl's mode constants.
        die "Refusing symbolic link for runtime metadata $file" if -l _;
        die "Runtime metadata is not a regular file: $file" if !-f _;
        die "Runtime metadata is not owned by the current user: $file" if $metadata_stat[4] != $>;

        if ( ( $metadata_stat[2] & 0777 ) == 0600 ) {
            my $existing_fh = _open_state_metadata_file( $file, '<:raw' );
            die "Unable to read $file: $!" if !$existing_fh;
            local $/;
            my $existing = <$existing_fh>;
            die "Unable to close $file: $!" if !_close_state_metadata_file($existing_fh);
            return $file if defined $existing && $existing eq $content;
        }
    }

    my $fh = _open_state_metadata_file( $file, '>:raw' );
    die "Unable to write $file: $!" if !$fh;
    die "Unable to write runtime metadata $file: $!" if !_print_state_metadata( $fh, $content );
    die "Unable to close $file: $!" if !_close_state_metadata_file($fh);
    $self->secure_file_permissions($file);
    return $file;
}

# _state_metadata_lstat($file)
# Reads non-following metadata for the state identity file so links can be
# rejected before any content is opened.
# Input: runtime metadata file path string.
# Output: lstat result list, empty on failure with the operating-system error in $!.
sub _state_metadata_lstat {
    my ($file) = @_;
    return lstat $file;
}

# _open_state_metadata_file($file, $mode)
# Opens the runtime metadata file using the requested raw mode and preserves
# the system error when the open fails.
# Input: metadata file path string and Perl open mode string.
# Output: filehandle reference on success, undef on failure.
sub _open_state_metadata_file {
    my ( $file, $mode ) = @_;
    open my $fh, $mode, $file or return;
    return $fh;
}

# _print_state_metadata($fh, $content)
# Writes the complete encoded runtime identity to an already-open metadata file.
# Input: output filehandle reference and JSON content string.
# Output: print's boolean success value.
sub _print_state_metadata {
    my ( $fh, $content ) = @_;
    return print {$fh} $content;
}

# _close_state_metadata_file($fh)
# Closes an opened metadata file and exposes a flush or close error to the caller.
# Input: open metadata filehandle reference.
# Output: close's boolean success value.
sub _close_state_metadata_file {
    my ($fh) = @_;
    return close $fh;
}

# temp_root()
# Returns the runtime temporary directory.
# Input: none.
# Output: directory path string.
sub temp_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'tmp' ) );
}

# config_root()
# Returns the writable configuration root, preferring the optional private
# overlay before the ordinary active runtime config directory.
# Input: none.
# Output: directory path string.
sub config_root {
    my ($self) = @_;
    my $overlay = $self->_config_overlay_root;
    return $overlay if defined $overlay;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIGS} ) {
        return $self->_ensure_dir( $self->_expand_home($dir) );
    }
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'config' ) );
}

# config_roots( runtime_roots => $array_ref )
# Returns configuration roots in effective lookup order, deriving them from a
# supplied runtime-root snapshot unless the explicit replacement config setting
# is active.
# Input: optional named runtime_roots array reference; omitted calls discover roots.
# Output: ordered list of configuration root directory path strings.
sub config_roots {
    my ( $self, %args ) = @_;
    my @roots;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIGS} ) {
        @roots = ( $self->_ensure_dir( $self->_expand_home($dir) ) );
    }
    else {
        my @runtime_roots = ref( $args{runtime_roots} ) eq 'ARRAY'
          ? @{ $args{runtime_roots} }
          : $self->runtime_roots;
        @roots = map { File::Spec->catdir( $_, 'config' ) } @runtime_roots;
    }
    my $overlay = $self->_config_overlay_root;
    unshift @roots, $overlay if defined $overlay;
    return @roots;
}

# config_layers()
# Returns the configuration roots in inheritance order from home to deepest
# layer.
# Input: none.
# Output: ordered list of configuration root directory path strings.
sub config_layers {
    my ($self) = @_;
    my @layers;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIGS} ) {
        @layers = ( $self->_ensure_dir( $self->_expand_home($dir) ) );
    }
    else {
        @layers = map { File::Spec->catdir( $_, 'config' ) } $self->runtime_layers;
    }
    my $overlay = $self->_config_overlay_root;
    push @layers, $overlay if defined $overlay;
    return @layers;
}

# _config_overlay_root()
# Resolves and creates the optional extra config root used for container-local
# overrides without replacing the normal home/project config lookup chain.
# Input: none; reads DEVELOPER_DASHBOARD_CONFIG_OVERLAY when set.
# Output: expanded overlay directory path, or undef when no overlay is set.
sub _config_overlay_root {
    my ($self) = @_;
    my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIG_OVERLAY};
    return if !defined $dir || $dir eq '';
    $dir = $self->_expand_home($dir);
    die "Config overlay must not be a symbolic link: $dir" if -l $dir;
    $self->_ensure_state_dir($dir);
    my @stat = $self->_config_overlay_stat($dir);
    die "Unable to inspect config overlay directory $dir: $!" if !@stat;
    die "Config overlay directory is not owned by the current user: $dir"
      if $stat[4] != $>;
    return $dir;
}

# _config_overlay_stat($dir)
# Reads the filesystem metadata used to validate a private config overlay.
# Input: expanded overlay directory path.
# Output: stat fields for the directory, or an empty list when it cannot be read.
sub _config_overlay_stat {
    my ( $self, $dir ) = @_;
    return stat $dir;
}

# auth_root()
# Returns the auth configuration directory.
# Input: none.
# Output: directory path string.
sub auth_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->config_root, 'auth' ) );
}

# auth_roots()
# Returns the auth configuration roots in effective lookup order.
# Input: none.
# Output: ordered list of auth root directory path strings.
sub auth_roots {
    my ($self) = @_;
    return map { File::Spec->catdir( $_, 'auth' ) } $self->config_roots;
}

# repo_dashboard_root()
# Returns the repo-local dashboard root for the active project.
# Input: none.
# Output: directory path string or undef.
sub repo_dashboard_root {
    my ($self) = @_;
    return $self->project_runtime_root;
}

# users_root()
# Returns the helper user storage directory.
# Input: none.
# Output: directory path string.
sub users_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->auth_root, 'users' ) );
}

# users_roots()
# Returns the helper-user roots in effective lookup order.
# Input: none.
# Output: ordered list of user storage directory path strings.
sub users_roots {
    my ($self) = @_;
    return map { File::Spec->catdir( $_, 'users' ) } $self->auth_roots;
}

# runtime_local_lib_roots()
# Returns the runtime-local Perl library roots in lookup order from deepest
# layer to home.
# Input: none.
# Output: ordered list of runtime-local perl5 directory paths.
sub runtime_local_lib_roots {
    my ($self) = @_;
    return map { File::Spec->catdir( $_, 'local', 'lib', 'perl5' ) } $self->runtime_roots;
}

# current_project_root()
# Resolves the current git project root from the current working directory.
# Input: none.
# Output: directory path string or undef.
sub current_project_root {
    my ($self) = @_;
    my $cwd = $self->current_working_directory;
    my $cache_key = 'current_project_root:' . $self->_path_identity($cwd);
    return $self->_memoize( $cache_key => sub { $self->project_root_for($cwd) } );
}

# current_working_directory()
# Returns the invocation-scoped current working directory used for path and
# runtime-layer derivation.
# Input: none.
# Output: directory path string or undef when cwd is unavailable.
sub current_working_directory {
    my ($self) = @_;
    return $self->{cwd} if defined $self->{cwd} && $self->{cwd} ne '';
    return eval { getcwd() };
}

# getcwd()
# Preserves the package-level function name formerly provided by Cwd's
# imported getcwd while routing normal calls through the verified fast lookup.
# Input: none.
# Output: logical absolute working-directory path or undef when unavailable.
sub getcwd {
    return Developer::Dashboard::PathIdentity::current_working_directory();
}

# cwd()
# Preserves the public path-registry working-directory accessor as a
# compatibility alias for the current-directory lookup.
# Input: none.
# Output: the same directory path or undef as current_working_directory().
sub cwd {
    my ($self) = @_;
    return $self->current_working_directory;
}

# project_root_for($start_dir)
# Resolves the nearest git project root for a starting directory.
# Input: starting directory path.
# Output: directory path string or undef.
sub project_root_for {
    my ( $self, $start_dir ) = @_;

    my $dir = defined $start_dir && $start_dir ne '' ? $start_dir : $self->current_working_directory;
    return if !defined $dir || $dir eq '';

    while ($dir) {
        return $dir if -d File::Spec->catdir( $dir, '.git' );

        my $parent = dirname($dir);
        last if $parent eq $dir;
        $dir = $parent;
    }

    return;
}

# workspace_roots()
# Returns the configured workspace search roots.
# Input: none.
# Output: list of directory path strings.
sub workspace_roots {
    my ($self) = @_;
    return @{ $self->{workspace_roots} };
}

# project_roots()
# Returns the configured project search roots.
# Input: none.
# Output: list of directory path strings.
sub project_roots {
    my ($self) = @_;
    return @{ $self->{project_roots} };
}

# DD-870: the method-name fallback below must dispatch ONLY to these no-arg
# path getters - never to the class's other public methods (the constructor,
# mutators like register_named_paths/unregister_named_path, or the
# plural/hash-returning inventory methods like all_paths/all_path_aliases),
# or a name typed straight from the CLI (dashboard path resolve/add) becomes
# an arbitrary method call on this object. Same fix shape as DD-868
# (FileRegistry::resolve_file).
my %RESOLVABLE_ACCESSOR = map { $_ => 1 } qw(
  home runtime_root home_runtime_root home_runtime_path project_runtime_root
  state_root state_base_root cache_root home_cache_root logs_root
  dashboards_root bookmarks bookmarks_root cli_root skills_root
  collectors_root indicators_root sessions_root temp_root config_root
  auth_root repo_dashboard_root users_root current_project_root
  current_working_directory cwd
);

# resolve_dir($name)
# Resolves a logical directory name or absolute path. DD-1005: when the
# registered alias carries lazy-create metadata (a hash, not a bare path
# string - see Config::save_global_path_alias) and the resolved target does
# not exist on disk, it is created here (with parents, mkdir -p semantics)
# and chmod'd to the stored mode if one was given, before being returned.
# This is the ONE place that logic lives, so cdr, workspace routes, and
# every direct Perl caller of resolve_dir all get it for free with no
# per-call-site duplication. A non-create-marked alias (a bare string, or a
# hash with no "create" key) behaves exactly as before this feature existed
# - resolve_dir has never itself checked existence, only returned the path.
# Input: logical directory name or absolute path.
# Output: resolved directory path string.
sub resolve_dir {
    my ( $self, $name ) = @_;

    die 'Missing path name' if !defined $name || $name eq '';

    return $name if File::Spec->file_name_is_absolute($name);

    return $self->$name() if $RESOLVABLE_ACCESSOR{$name};

    if ( exists $self->{named_paths}{$name} ) {
        my $entry = $self->{named_paths}{$name};
        my ( $path, $create, $mode ) =
          ref($entry) eq 'HASH' ? ( $entry->{path}, $entry->{create}, $entry->{mode} ) : ( $entry, undef, undef );
        $path = $self->_expand_home($path);
        if ( $create && !-d $path ) {
            make_path($path);
            chmod( oct($mode), $path ) if defined $mode && $mode ne '';
        }
        return $path;
    }

    die "Unknown directory name '$name'";
}

# resolve_any(@names)
# Resolves the first existing directory among several logical names.
# Input: list of logical directory names.
# Output: directory path string or undef.
sub resolve_any {
    my ( $self, @names ) = @_;
    for my $name (@names) {
        my $path = eval { $self->resolve_dir($name) };
        next if !$path || !-d $path;
        return $path;
    }
    return;
}

# ls($name)
# Lists child paths under a resolved directory.
# Input: logical directory name.
# Output: sorted list of child path strings.
sub ls {
    my ( $self, $name ) = @_;
    my $dir = $self->resolve_dir($name);
    return if !-d $dir;

    opendir my $dh, $dir or die "Unable to open $dir: $!";
    my @items;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        push @items, File::Spec->catfile( $dir, $entry );
    }
    closedir $dh;

    return sort @items;
}

# with_dir($name, $code)
# Temporarily changes into a resolved directory while executing a callback.
# Input: logical directory name and code reference.
# Output: callback return value.
sub with_dir {
    my ( $self, $name, $code ) = @_;
    my $dir = $self->resolve_dir($name);
    my $old = getcwd();
    chdir $dir or die "Unable to chdir to $dir: $!";
    my @result = eval { $code->($dir) };
    my $error = $@;
    chdir $old or die "Unable to restore cwd to $old: $!";
    die $error if $error;
    return wantarray ? @result : $result[0];
}

# locate_projects(@terms)
# Fuzzy-matches projects under configured roots.
# Input: list of search term strings.
# Output: list of matched project directory paths.
sub locate_projects {
    my ( $self, @terms ) = @_;

    my @roots = grep { defined && -d } ( $self->workspace_roots, $self->project_roots );
    my @found;
    my %seen;

    for my $root (@roots) {
        opendir my $dh, $root or next;
        while ( my $entry = readdir $dh ) {
            next if $entry =~ /^\./;
            my $path = File::Spec->catdir( $root, $entry );
            next if !-d $path;

            my $ok = 1;
            for my $term (@terms) {
                next if !defined $term || $term eq '';
                if ( $entry !~ /\Q$term\E/i ) {
                    $ok = 0;
                    last;
                }
            }

            if ( $ok && !$seen{$path}++ ) {
                push @found, $path;
            }
        }
        closedir $dh;
    }

    return @found;
}

# locate_dirs_under($root, @terms)
# Recursively finds directories beneath one root whose relative path matches
# every supplied keyword.
# Input: search root directory path string plus zero or more keyword strings.
# Output: sorted list of matched directory path strings.
sub locate_dirs_under {
    my ( $self, $root, @terms ) = @_;
    return () if !defined $root || $root eq '' || !-d $root;

    my @wanted = map { $self->_compile_search_regex($_) } grep { defined && $_ ne '' } @terms;
    my $root_id = $self->_path_identity($root);
    my %seen;
    my @found;
    my @pending = ($root);

    while (@pending) {
        my $path = shift @pending;
        my $path_id = $self->_path_identity($path);
        next if $seen{$path_id}++;

        my $relative = $path_id eq $root_id ? '.' : File::Spec->abs2rel( $path_id, $root_id );
        $relative =~ s{\\}{/}g;
        $relative = $relative eq '.' ? '.' : './' . $relative;

        my $matches = 1;
        for my $term (@wanted) {
            if ( $relative !~ $term ) {
                $matches = 0;
                last;
            }
        }

        push @found, $path_id if $matches;

        opendir( my $dh, $path ) or next;
        while ( my $entry = readdir($dh) ) {
            next if $entry eq '.' || $entry eq '..';
            my $child = File::Spec->catdir( $path, $entry );
            next if !-d $child;
            push @pending, $child;
        }
        closedir($dh);
    }

    return sort @found;
}

# _compile_search_regex($pattern)
# Compiles one path-search token into the regex object used by recursive directory lookups.
# Input: one search token string.
# Output: compiled regex object, or dies when the token is not a valid regex.
sub _compile_search_regex {
    my ( $self, $pattern ) = @_;
    return if !defined $pattern || $pattern eq '';
    my $regex = eval { qr/$pattern/i };
    die "Invalid regex '$pattern': $@\n" if !$regex;
    return $regex;
}

# collector_dir($name)
# Returns the runtime directory for a named collector.
# Input: collector name string.
# Output: directory path string.
sub collector_dir {
    my ( $self, $name ) = @_;
    die 'Missing collector name' if !$name;
    return $self->_ensure_dir( File::Spec->catdir( $self->collectors_root, $name ) );
}

# indicator_dir($name)
# Returns the runtime directory for a named indicator.
# Input: indicator name string.
# Output: directory path string.
sub indicator_dir {
    my ( $self, $name ) = @_;
    die 'Missing indicator name' if !$name;
    return $self->_ensure_dir( File::Spec->catdir( $self->indicators_root, $name ) );
}

# ensure_dir($dir)
# Creates a directory if needed and applies runtime permission hardening.
# Input: directory path string.
# Output: directory path string.
sub ensure_dir {
    my ( $self, $dir ) = @_;
    return $self->_ensure_dir($dir);
}

# is_home_runtime_path($path)
# Checks whether one path lives under the home runtime tree.
# Input: file or directory path string.
# Output: boolean true when the path is inside either home runtime directory.
sub is_home_runtime_path {
    my ( $self, $path ) = @_;
    return 0 if !defined $path || $path eq '';
    my @roots = ( $self->_existing_layer_dirs_for( $self->home ), $self->home_runtime_path );
    for my $root (@roots) {
        return 1 if $self->_same_or_descendant_path( $path, $root );
    }
    return 0;
}

# runtime_layer_root_for($path)
# Finds which of our runtime layers owns a path, so the securing helpers can
# protect a project-local layer exactly as they already protect the home one.
#
# WHY THIS EXISTS (DD-784). secure_file_permissions and secure_dir_permissions
# were both gated on is_home_runtime_path, but DD-OOP-LAYERS makes the DEEPEST
# .developer-dashboard the write target - so every runtime file and directory
# written into a project-local layer kept its umask default. Measured before the
# fix, under umask 002: config/api.json at 0664 inside a 0775 directory, holding
# the machine-tier API secret digests and their route allowlist. A group member
# could read the digests and, because the directory was group-writable, replace
# the file outright and register their own key.
#
# The gap was already known and worked around rather than fixed: atomic_write_secure
# chmods unconditionally and says in its own comment that it avoids the gated
# method for exactly this reason. That closed it for the three writers migrated
# onto it (Auth, SessionStore, Zipper) and left 40-odd other call sites, and the
# comment explaining the workaround is what made the remainder look deliberate.
# Input: file or directory path string.
# Output: the runtime layer root containing the path, or empty string when none does.
# MUST NOT call runtime_layers here, however natural that reads. runtime_layers
# resolves home_runtime_ROOT, which calls _ensure_dir, which calls
# secure_dir_permissions, which would call back into this - an infinite
# recursion that hangs any process touching a runtime path. Measured: the
# config suite went from under a second to a hard timeout the moment this used
# the ensuring accessor. Build the candidate list from the non-creating sources
# instead: home_runtime_PATH and _existing_layer_dirs_for are pure path
# computations, and the env and ancestor layer helpers create nothing.
# The candidate path is canonicalized once while each root retains its own
# current filesystem identity check. During all_paths(), the candidate-root
# list is shared only for that aggregate operation to avoid rescanning an
# unchanged tree for each permission check; the scoped list is discarded on
# return so later operations see new or removed runtime layers.
sub runtime_layer_root_for {
    my ( $self, $path ) = @_;
    return '' if !defined $path || $path eq '';
    my ( $path_identity, $path_identity_ready );
    my $scope = $self->{_runtime_layer_candidate_scope};
    if ( ref($scope) ne 'HASH' ) {
        $scope = {};
    }
    if ( !exists $scope->{roots} ) {
        my @home_layers = reverse $self->_existing_layer_dirs_for( $self->home );
        push @home_layers, $self->home_runtime_path;
        $scope->{roots} = [ $self->_runtime_layers_from_env, @home_layers, $self->_ancestor_runtime_layers_for_scope ];
    }
    for my $root ( @{ $scope->{roots} } ) {
        # None of the three sources above can yield undef or empty in
        # production - the env reader filters blanks itself, home_runtime_path
        # is a pure File::Spec->catdir on an always-set home, and the ancestor
        # walker only ever pushes real existing-directory paths. The guard is
        # exercised directly instead of being annotated: t/93 stubs
        # _runtime_layers_from_env to inject an undef entry and an empty-string
        # entry ahead of a real root, which drives both operands of this OR
        # true independently while a normal run still drives it false.
        next if !defined $root || $root eq '';
        return $root if $path eq $root;
        if ( !$path_identity_ready ) {
            $path_identity = $self->_path_identity($path);
            $path_identity_ready = 1;
        }
        my $root_identity = $self->_path_identity($root);
        return $root if Developer::Dashboard::PathIdentity::_same_or_descendant_identity( $path_identity, $root_identity );
    }
    return '';
}

# is_runtime_layer_path($path)
# Checks whether a path lives under ANY of our runtime layers, home or
# project-local. This is the predicate the securing helpers gate on, so a
# project-local layer is protected exactly as the home layer is.
# Input: file or directory path string.
# Output: boolean true when the path is inside one of our runtime layers.
sub is_runtime_layer_path {
    my ( $self, $path ) = @_;
    return $self->runtime_layer_root_for($path) ne '' ? 1 : 0;
}

# secure_dir_permissions($dir)
# Tightens one runtime directory chain to owner-only mode, skipping chmod
# syscalls when each directory already has the required mode.
# Input: directory path string.
# Output: directory path string.
sub secure_dir_permissions {
    my ( $self, $dir ) = @_;

    # DD-784: anchor on whichever runtime layer owns this directory rather than
    # always the home one. Gated on is_home_runtime_path, this returned early for
    # a project-local layer, so those directories kept the umask default (0775
    # measured under umask 002) while the home layer got 0700. A group-writable
    # runtime directory is what turns a readable secret into a replaceable one.
    my $layer_root = $self->runtime_layer_root_for($dir);
    return $dir if $layer_root eq '';

    my $path = $layer_root;
    if ( -d $path ) {
        my @dir_stat = stat $path;
        die "Unable to inspect runtime directory $path: $!" if !@dir_stat;
        if ( ( $dir_stat[2] & 07777 ) != 0700 ) {
            chmod 0700, $path or die "Unable to chmod $path to 0700: $!";
        }
    }
    return $dir if $dir eq $layer_root;

    my $suffix = substr( $dir, length($layer_root) );
    $suffix =~ s{^/}{};
    for my $part ( grep { $_ ne '' } File::Spec->splitdir($suffix) ) {
        $path = File::Spec->catdir( $path, $part );
        next if !-d $path;
        my @dir_stat = stat $path;
        die "Unable to inspect runtime directory $path: $!" if !@dir_stat;
        if ( ( $dir_stat[2] & 07777 ) != 0700 ) {
            chmod 0700, $path or die "Unable to chmod $path to 0700: $!";
        }
    }

    return $dir;
}

# secure_file_permissions($file, %args)
# Tightens one home-runtime file to owner-only mode, preserving owner execute
# bits when an executable file is expected.
# Input: file path string plus optional executable boolean.
# Output: file path string.
sub secure_file_permissions {
    my ( $self, $file, %args ) = @_;
    return $file if !defined $file || $file eq '';
    # DD-784: gated on ANY runtime layer, not only the home one. This used to
    # read is_home_runtime_path, which silently stopped securing every file
    # written into a project-local .developer-dashboard - the layer that
    # DD-OOP-LAYERS makes the write target whenever one exists.
    return $file if !$self->is_runtime_layer_path($file) && !$self->_is_state_path($file);
    return $file if !-e $file;
    my $mode = $args{executable} ? 0700 : 0600;
    chmod $mode, $file or die sprintf 'Unable to chmod %s to %04o: %s', $file, $mode, $!;
    return $file;
}

# atomic_write_secure($tmp, $file, $content, %opts)
# Writes $content to the given unpredictable per-writer staging path, secures
# it, and only then atomically renames it into its final, predictable
# destination - the one ordering that avoids a window where the file exists
# at $file with loose (umask-determined) permissions (DD-599/600/601/602
# each independently reimplemented this sequence; this is the single place
# every writer should reach for instead).
#
# Deliberately chmods unconditionally rather than going through
# secure_file_permissions, and the REASON CHANGED with DD-784 - read this
# before assuming the old one still applies.
#
# It used to be a coverage gap: secure_file_permissions was gated on
# is_home_runtime_path, so it did not secure config_root (nor anything beneath
# it, e.g. Auth.pm's users_root) once a project-local .developer-dashboard
# layer became the active runtime_root under DD-OOP-LAYERS. Routing through it
# would have silently stopped securing those files. DD-784 closed that gap:
# the method now gates on is_runtime_layer_path, which covers ANY runtime
# layer, so that justification no longer holds.
#
# What remains, and is the reason this still chmods directly: the subject here
# is the STAGING file, not the destination. It must be secured whether or not
# it satisfies any layer predicate, because the whole point of the sequence is
# that the content is already at its final mode before the rename makes it
# reachable at a predictable path. A gated helper is the wrong shape for that -
# a predicate returning false would leave the staging file loose and the
# rename would publish it.
#
# Callers keep their own staging-path-naming helper (e.g. _pending_user_file)
# so existing fault-injection tests that override it to a fixed, predictable
# path keep working unchanged - this method only does the write/secure/rename
# mechanics, not staging-path generation.
# Input: staging file path, final destination path, content string, optional
# executable boolean.
# Output: destination file path string.
sub atomic_write_secure {
    my ( $self, $tmp, $file, $content, %opts ) = @_;
    my $mode = $opts{executable} ? 0700 : 0600;
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} $content or die "Unable to write $tmp: $!";
    close $fh or die "Unable to close $tmp: $!";
    $self->_chmod_pending( $tmp, $mode );
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    return $file;
}

# _chmod_pending($tmp, $mode)
# Secures one staging file before atomic_write_secure's rename. Its own
# method (rather than an inline chmod call) exists so a concurrency test can
# override it to pause a writer between securing its staging file and
# renaming it into place, proving two overlapping writers cannot corrupt
# each other's result (t/54-hunt-collector.t).
# Input: staging file path and target permission mode integer.
# Output: staging file path string.
sub _chmod_pending {
    my ( $self, $tmp, $mode ) = @_;
    chmod $mode, $tmp or die sprintf 'Unable to chmod %s to %04o: %s', $tmp, $mode, $!;
    return $tmp;
}

# _is_state_path($path)
# Checks whether a file path is inside the configured runtime state area.
# Input: path string.
# Output: boolean true when the path is under state_base_root.
sub _is_state_path {
    my ( $self, $path ) = @_;
    return 0 if !defined $path || $path eq '';
    my $state_base = eval { $self->state_base_root };
    return 0 if !defined $state_base || $state_base eq '';
    return $self->_same_or_descendant_path( $path, $state_base );
}

# _ensure_dir($dir)
# Creates a directory if needed and returns it.
# Input: directory path string.
# Output: directory path string.
sub _ensure_dir {
    my ( $self, $dir ) = @_;
    if ( !-d $dir ) {
        # DD-784: create at 0700 for ANY runtime layer, not only the home one -
        # otherwise a project-local runtime directory is born umask-default and
        # is merely tightened afterwards, leaving a window in which it is
        # group-writable.
        if ( $self->is_runtime_layer_path($dir) ) {
            make_path( $dir, { mode => 0700 } );
        }
        else {
            make_path($dir);
        }
    }
    $self->secure_dir_permissions($dir);
    return $dir;
}

# _ensure_state_dir($dir)
# Creates a state directory and applies owner-only hardening.
# Input: directory path string.
# Output: directory path string.
sub _ensure_state_dir {
    my ( $self, $dir ) = @_;
    if ( !-d $dir ) {
        make_path( $dir, { mode => 0700 } );
    }
    else {
        my @dir_stat = stat _;
        die "Unable to inspect state directory $dir: $!" if !@dir_stat;
        chmod 0700, $dir
          or die sprintf 'Unable to chmod %s to 0700: %s', $dir, $!
          if ( $dir_stat[2] & 07777 ) != 0700;
    }
    return $dir;
}

# _expand_home($path)
# Expands leading home shorthands used by config and env values.
# Input: path string that may start with ~ or $HOME.
# Output: expanded path string.
sub _expand_home {
    my ( $self, $path ) = @_;
    return $path if !defined $path;
    $path =~ s/^\$HOME(?=\/|$)/$self->{home}/;
    $path =~ s/^~/$self->{home}/;
    return $path;
}

# _ancestor_runtime_layers()
# Discovers every existing .developer-dashboard and .d2 runtime directory
# between the current working directory and the configured home directory,
# excluding both home-level runtime roots. Exact duplicate home-root spellings
# are removed before canonical identity checks to avoid resolving one path twice.
# Input: none.
# Output: ordered list of runtime root paths from home toward the deepest
# current layer; .d2 precedes .developer-dashboard at the same depth.
sub _ancestor_runtime_layers {
    my ($self) = @_;
    my $cwd = $self->current_working_directory;
    return () if !defined $cwd || $cwd eq '';
    my $home = $self->home;
    # An exact home cwd has no intermediate layer to discover; symlink-spelled
    # equivalents still take the canonical ancestry path below.
    return () if $cwd eq $home;
    my %home_runtime;
    my %seen_home_runtime_path;
    for my $runtime_path ( $self->home_runtime_path, $self->_existing_layer_dirs_for($home) ) {
        next if $seen_home_runtime_path{$runtime_path}++;
        $home_runtime{ $self->_path_identity($runtime_path) } = 1;
    }
    my $project_root = eval { $self->current_project_root } || '';
    my $stop_dir = '';
    if ( $self->_same_or_descendant_path( $cwd, $home ) ) {
        $stop_dir = $home;
    }
    elsif ( $project_root ne '' && $self->_same_or_descendant_path( $cwd, $project_root ) ) {
        $stop_dir = $project_root;
    }
    else {
        return ();
    }

    my @layers;
    my $stop_identity;
    my $dir = $cwd;
    while ($dir) {
        for my $candidate ( $self->_existing_layer_dirs_for($dir) ) {
            next if $home_runtime{ $self->_path_identity($candidate) };
            my $visible_candidate = $self->_display_path($candidate);
            unshift @layers, $visible_candidate;
        }
        last if $dir eq $stop_dir;
        # Resolve a symlink-spelled boundary only once per walk. Deferring this
        # preserves the exact-string fast path when cwd is already the boundary.
        $stop_identity = $self->_path_identity($stop_dir) if !defined $stop_identity;
        last if $self->_path_identity($dir) eq $stop_identity;
        my $parent = dirname($dir);
        last if $parent eq $dir;
        $dir = $parent;
    }
    return @layers;
}

# _ancestor_runtime_layers_for_scope()
# Returns discovered ancestor runtime layers, sharing the result only inside an
# explicit operation scope so runtime creation/removal remains visible later.
# Input: none; reads the existing operation-local candidate scope when present.
# Output: ordered list of ancestor runtime-layer directory paths.
sub _ancestor_runtime_layers_for_scope {
    my ($self) = @_;
    my $scope = $self->{_runtime_layer_candidate_scope};
    return @{ $scope->{ancestor_runtime_layers} }
      if ref($scope) eq 'HASH' && exists $scope->{ancestor_runtime_layers};
    my @layers = $self->_ancestor_runtime_layers;
    $scope->{ancestor_runtime_layers} = \@layers if ref($scope) eq 'HASH';
    return @layers;
}

# _path_identity($path)
# Normalizes a path for identity and ancestry comparisons without requiring the
# caller to care about symlink aliases such as /var versus /private/var on macOS.
# Exact spellings reuse identities only within an explicit all_paths, CLI, or
# web-request scope; no identity survives the operation/request.
# Delegates to Developer::Dashboard::PathIdentity (DD-903) with
# empty_fallback => 1, preserving this class's historical behavior of falling
# back to File::Spec->canonpath when abs_path() returns an empty string.
# Input: path string.
# Output: canonical existing path or a stable canonpath string.
sub _path_identity {
    my ( $self, $path ) = @_;
    my $scope = $self->{_path_identity_scope};
    if ( ref($scope) eq 'HASH' ) {
        my $key = defined $path ? 'S' . $path : 'U';
        return $scope->{$key} if exists $scope->{$key};
        return $scope->{$key} = Developer::Dashboard::PathIdentity::_path_identity(
            $path, empty_fallback => 1,
        );
    }
    return Developer::Dashboard::PathIdentity::_path_identity( $path, empty_fallback => 1 );
}

# _prefer_reference_style($path, $reference)
# Rewrites an equivalent filesystem path into the same textual style as $reference
# when both paths resolve to the same canonical identity.
# Input: filesystem path and reference path.
# Output: styled path string that preserves user-visible aliases when possible.
sub _prefer_reference_style {
    my ( $self, $path, $reference ) = @_;
    return $path if !defined $path || $path eq '';
    return $path if !defined $reference || $reference eq '';

    my $path_id = $self->_path_identity($path);
    my $ref_id  = $self->_path_identity($reference);

    my $prefix = $ref_id;
    $prefix .= '/' if $prefix !~ m{/$};
    return $path if index( $path_id, $prefix ) != 0;

    my $relative = substr( $path_id, length($prefix) );
    $relative =~ s{^/}{};
    return $reference if !$relative;

    my @segments = grep { $_ ne '..' } File::Spec->splitdir($relative);
    return File::Spec->catdir( $reference, @segments );
}

# _display_path($path)
# Returns a stable user-facing path string while keeping canonical identity
# handling separate for comparisons.
# Input: filesystem path string.
# Output: display-stable path string.
sub _display_path {
    my ( $self, $path ) = @_;
    return $path if !defined $path || $path eq '';

    for my $alias_prefix ( '/private/tmp', '/private/var' ) {
        next if index( $path, $alias_prefix ) != 0;
        my $short_prefix = substr( $alias_prefix, length('/private') );
        my $candidate = $short_prefix . substr( $path, length($alias_prefix) );
        next if $self->_path_identity($candidate) ne $self->_path_identity($path);
        return $candidate;
    }

    return $path;
}

# _same_or_descendant_path($path, $root)
# Checks whether one path is identical to or nested beneath another path after
# canonical normalization. Delegates to Developer::Dashboard::PathIdentity
# (DD-903) with empty_fallback => 1, matching this class's own _path_identity.
# Input: candidate path string and root path string.
# Output: boolean.
sub _same_or_descendant_path {
    my ( $self, $path, $root ) = @_;
    return Developer::Dashboard::PathIdentity::_same_or_descendant_path( $path, $root, empty_fallback => 1 );
}

# _runtime_layers_from_env()
# Reads an explicit runtime-layer chain from the process environment when one
# is provided by the parent runtime process.
# Input: none.
# Output: ordered list of runtime root directory path strings from home to
# deepest layer.
sub _runtime_layers_from_env {
    my ($self) = @_;
    my $raw = $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS} || '';
    return () if $raw eq '';
    return grep { $_ ne '' } split /\n/, $raw;
}

# _memoize($key, $builder)
# Caches one derived path or layer value for the lifetime of the current
# registry object so repeated helper calls do not recompute cwd-driven state.
# Input: cache key string and builder code reference.
# Output: cached scalar or reference value.
sub _memoize {
    my ( $self, $key, $builder ) = @_;
    die "Missing memoization key\n" if !defined $key || $key eq '';
    die "Missing memoization builder\n" if ref($builder) ne 'CODE';
    return $self->{memo}{$key} if exists $self->{memo}{$key};
    $self->{memo}{$key} = $builder->();
    return $self->{memo}{$key};
}

1;

__END__

=head1 NAME

Developer::Dashboard::PathRegistry - logical directory registry

=head1 SYNOPSIS

  my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
  my $root  = $paths->current_project_root;

=head1 DESCRIPTION

This module provides the central logical directory registry used across the
dashboard runtime, shell helpers, and background services.

=head1 METHODS

=head2 new

Construct the path registry.

=head2 resolve_dir, resolve_any, locate_projects, locate_dirs_under, current_project_root, project_root_for

Resolve and discover project-related directories.

resolve_dir() (DD-1005) additionally creates a registered alias's target
directory (with parents) on first resolution when that alias was saved with
C<create =E<gt> 1> (see C<Developer::Dashboard::Config>'s
save_global_path_alias()/save_skill_path_alias() C<%opts>), chmod'ing it to
the alias's stored octal mode when one was given. named_paths() collapses
such an alias back to a bare path string for display consumers
(C<dashboard path list>, prefix completion) that have no use for the
metadata; resolve_dir() itself always reads the raw internal registration,
so the create/mode metadata is never lost between the two.

=head2 current_working_directory, cwd, getcwd

Report the effective working directory: the explicit constructor C<cwd> when one was supplied, otherwise a lookup that uses absolute C<PWD> only when its device and inode match the process directory, preserving valid logical symlink paths; otherwise it falls back to C<Cwd::cwd> (undef when the directory is unavailable). C<cwd> remains the object-level accessor consumed by the file registry. The package-level C<getcwd> function preserves the historical imported C<Cwd::getcwd> name while using the verified fast lookup.

=head2 _ensure_state_dir

Creates a missing state directory with mode C<0700>. For an existing directory,
it inspects the mode from the directory check and calls C<chmod 0700> only when
the complete permission/special-bit mask is not already exactly C<0700>. The
directory remains private after either path; inspection or chmod errors are
reported instead of being ignored. It accepts a directory path and returns
that same path on success.

=head2 validated_path_segments

Package function that splits one untrusted relative path into its
separator-delimited segments and rejects any shape able to escape the directory
it will be joined onto: missing or empty paths, NUL or other control bytes,
backslash separators, absolute paths, Windows drive prefixes, and empty,
current-directory, or parent-directory segments. Returns the validated segment
list (segment count in scalar context) or an empty list (undef in scalar
context) on rejection. C<skill_layers> requires exactly one validated segment
for a skill name, and the skill dispatcher and web layer reuse this guard for
every skill-namespaced route, ajax, and static asset path.

=head2 installed_skill_entries

Returns each effective installed skill once with its deepest selected root and
all participating roots in home-to-project precedence order. The optional
C<include_disabled> flag follows C<installed_skill_roots> semantics. This
grouped inventory is intended for readers that need each skill's layered
metadata; it avoids rescanning every runtime's skill directory once per skill.

=head2 skill_layers

Returns the participating roots for one validated top-level skill name in
home-to-leaf precedence order. A disabled first effective layer masks the
skill unless C<include_disabled =E<gt> 1> is supplied; disabled later layers
are skipped in normal lookup. During an explicit installed-skill inventory
scope, directory names and validated name segments are reused, but every
candidate directory and disabled marker is checked on each call. Outside that
scope, the method resolves runtime skill roots afresh so later filesystem
changes are visible. Input is a skill name and optional C<include_disabled>
boolean; output is an ordered list of skill-root paths, or an empty list for
missing, invalid, or effectively disabled skills.

  my @layers = $paths->skill_layers('example-skill');
  my @all    = $paths->skill_layers('example-skill', include_disabled => 1);

=head2 runtime_root, cache_root, home_runtime_root, home_cache_root

Report the layered runtime directories. C<runtime_root> and C<cache_root> follow the deepest discovered layer, which is the write target for layered runtime state. At each depth, both existing C<.d2/> and C<.developer-dashboard/> roots are independently discoverable; C<.developer-dashboard/> wins same-depth lookup precedence and remains the write target when both exist. C<home_runtime_root> and C<home_cache_root> stay pinned to the selected home write root, for per-user artifacts that a fixed external consumer reads from one well-known path.

C<runtime_layers> refreshes filesystem discovery on an unscoped call so a
retained registry notices project runtime-layer creation and removal. Callers
may share its result only within an operation by localizing
C<_runtime_layer_candidate_scope>; C<all_paths> and the path CLI establish
such scopes. A scope snapshots each parent's existing C<.d2> and
C<.developer-dashboard> directories, while unscoped calls always check the
filesystem again. The private C<_existing_layer_dirs_for> helper requires a
defined, non-empty parent path and reports invalid input before touching the
filesystem. Direct Dancer routes establish request-local path-identity
and runtime-layer scopes so repeated spellings are canonicalized once and
directory existence is checked once per parent during that request.
C<runtime_root> also stores the deepest root in that active scope so repeated
accessor calls avoid rebuilding a list from C<runtime_layers>; outside a scope,
it resolves a fresh list on every call. All request-local data is discarded
before the next request; these filesystem-derived values are never retained
across operations or requests.

=head2 _write_state_metadata

Record the runtime-root identity in C<runtime.json> under the private shared
state tree. Recreate missing directories or metadata after temporary cleanup.
An existing file is left untouched only if it is a regular file owned by the
current user, has mode C<0600>, and contains the exact expected JSON. Stale or
loosely permissioned metadata is rewritten and secured; symlinks, non-regular
files, and files owned by another user are refused with an explicit error.
The canonical expected JSON string is kept in a bounded one-entry object cache
for the latest exact runtime-root/application-name pair, avoiding redundant
encoding. Every call still checks the live directory and file, validates
ownership, mode, and type, and reads the on-disk bytes before accepting the
metadata as unchanged.
Filesystem inspection, open, write, and close failures are returned as explicit
errors rather than being ignored. The small C<_state_metadata_lstat>,
C<_open_state_metadata_file>, C<_print_state_metadata>, and
C<_close_state_metadata_file> helpers preserve those operation results for
deterministic failure-path tests.

=head2 config_root, config_roots, config_layers

C<config_root> selects the writable config directory. When
C<DEVELOPER_DASHBOARD_CONFIG_OVERLAY> is set, that private directory becomes
the write target; C<config_roots> still returns the normal layered config
directories and prepends the overlay so its values have the highest lookup
priority. C<config_layers> appends it as the final inherited layer. This lets
container commands store a path-alias override without writing through a
bind-mounted host config or hiding existing config values. The older
C<DEVELOPER_DASHBOARD_CONFIGS> setting remains a replacement config root.
C<config_roots> and C<skills_roots> also accept an internal
C<runtime_roots =E<gt> \@roots> snapshot. Request-scoped discovery uses this
to derive sibling directories from one consistent layer inventory instead of
re-discovering runtime layers for each accessor. Calls without the argument
retain normal live discovery behavior.

=for comment FULL-POD-DOC START

=head2 alias_cache_key

Build the cache key that tells configured-alias consumers whether the runtime
layout they cached against is still the current one. Called as a plain function
rather than a method, because it must return an empty key for a missing or
unblessed argument instead of dying on a method call. C<Developer::Dashboard::File>
and C<Developer::Dashboard::Folder> both delegate to it; each previously carried
its own identical copy of the computation.

=head1 PURPOSE

This module is the authoritative path model for the runtime. It discovers both supported runtime directory names from home to the current project, resolves standard runtime directories, manages named path aliases, and performs project and directory searches such as the regex-based narrowing used by C<cdr>.

=head1 WHY IT EXISTS

It exists because C<DD-OOP-LAYERS> is a cross-runtime contract, not a convenience helper. One path registry has to own how home and project runtimes participate, how parallel C<.d2/> and C<.developer-dashboard/> roots are ordered, which layer is writable, and how named paths and directory searches behave on top of that model.

=head1 WHEN TO USE

Use this file when changing layered runtime discovery, the writable runtime root, named alias behavior, project lookup, or directory-search semantics used by shell navigation helpers.

=head1 HOW TO USE

Construct it with the current home and cwd context, then ask it for runtime roots, named paths, or search results. Avoid rebuilding runtime path math elsewhere; other modules should consume this registry instead.

=head1 WHAT USES IT

It is used throughout the runtime by file, config, page, collector, prompt, shell-bootstrap, and CLI path logic, plus the tests that verify layered runtime behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::PathRegistry -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
