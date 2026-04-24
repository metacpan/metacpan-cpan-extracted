package Developer::Dashboard::PathRegistry;

use strict;
use warnings;

our $VERSION = '3.09';

use Digest::MD5 qw(md5_hex);
use Cwd qw(abs_path cwd);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use Developer::Dashboard::JSON qw(json_encode);

# new(%args)
# Constructs the logical path registry for the runtime.
# Input: home, app_name, workspace_roots, project_roots, and named_paths.
# Output: Developer::Dashboard::PathRegistry object.
sub new {
    my ( $class, %args ) = @_;

    my $home = $args{home} || $ENV{HOME} || die 'Missing home directory';

    my $self = bless {
        home            => $home,
        app_name        => $args{app_name} || 'developer-dashboard',
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
        next if !defined $name || $name eq '';
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
# Returns the currently registered logical path aliases.
# Input: none.
# Output: hash reference of alias-to-path mappings.
sub named_paths {
    my ($self) = @_;
    return { %{ $self->{named_paths} || {} } };
}

# all_paths() and all_path_aliases()
# Return the public hash payloads for the same inventories printed by
# dashboard paths and dashboard path list.
# Input: none.
# Output: hash references describing resolved runtime roots and aliases.

# runtime_root()
# Returns the effective runtime root directory.
# Input: none.
# Output: deepest discovered runtime layer directory, falling back to the home runtime directory.
sub runtime_root {
    my ($self) = @_;
    my @layers = $self->runtime_layers;
    return $layers[-1] || $self->home_runtime_root;
}

# home_runtime_root()
# Returns the home-backed runtime root directory.
# Input: none.
# Output: home runtime directory path string.
sub home_runtime_root {
    my ($self) = @_;
    return $self->_ensure_dir( $self->home_runtime_path );
}

# home_runtime_path()
# Returns the canonical home-backed runtime root path without creating it.
# Input: none.
# Output: home runtime directory path string.
sub home_runtime_path {
    my ($self) = @_;
    return File::Spec->catdir( $self->home, '.developer-dashboard' );
}

# project_runtime_root()
# Returns the active project-local runtime root when the project already contains one.
# Input: none.
# Output: project-local runtime directory path string or undef when absent.
sub project_runtime_root {
    my ($self) = @_;
    my $repo = $self->current_project_root or return;
    my $home_runtime = File::Spec->catdir( $self->home, '.developer-dashboard' );
    return if $repo eq $home_runtime;
    my $root = File::Spec->catdir( $repo, '.developer-dashboard' );
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

# runtime_layers()
# Returns the effective runtime roots in inheritance order from home to the
# current working directory layer.
# Input: none.
# Output: ordered list of runtime root directory path strings from home to deepest layer.
sub runtime_layers {
    my ($self) = @_;
    my @roots;
    my %seen;
    for my $root ( $self->_runtime_layers_from_env, $self->home_runtime_root, $self->_ancestor_runtime_layers ) {
        next if !defined $root || $root eq '';
        my $identity = $self->_path_identity($root);
        next if $seen{$identity}++;
        push @roots, $root;
    }
    return @roots;
}

# state_root()
# Returns the state root directory.
# Input: none.
# Output: directory path string.
sub state_root {
    my ($self) = @_;
    my $dir = $self->_ensure_state_dir( File::Spec->catdir( $self->state_base_root, $self->_state_root_key( $self->runtime_root ) ) );
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
    return {
        home                 => $self->home,
        home_runtime_root    => $self->home_runtime_root,
        project_runtime_root => scalar $self->project_runtime_root,
        runtime_root         => $self->runtime_root,
        state_root           => $self->state_root,
        cache_root           => $self->cache_root,
        logs_root            => $self->logs_root,
        dashboards_root      => $self->dashboards_root,
        bookmarks_root       => $self->bookmarks_root,
        cli_root             => $self->cli_root,
        collectors_root      => $self->collectors_root,
        indicators_root      => $self->indicators_root,
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

# skills_roots()
# Returns the installed skill roots in effective lookup order from deepest layer to home.
# Input: none.
# Output: ordered list of skill root directory path strings.
sub skills_roots {
    my ($self) = @_;
    return map { File::Spec->catdir( $_, 'skills' ) } $self->runtime_roots;
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
# skill from normal runtime lookup.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from home to leaf.
sub skill_layers {
    my ( $self, $name, %args ) = @_;
    return () if !defined $name || $name eq '';

    my @matches;
    my $saw_effective = 0;
    for my $skills_root ( $self->skills_roots ) {
        my $skill_root = File::Spec->catdir( $skills_root, $name );
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

# installed_skill_roots()
# Returns every installed skill root in deterministic sorted order.
# Input: none.
# Output: ordered list of installed skill root directory path strings.
sub installed_skill_roots {
    my ( $self, %args ) = @_;
    my @roots;
    my %seen_names;
    for my $skills_root ( $self->skills_roots ) {
        next if !-d $skills_root;
        opendir my $dh, $skills_root or die "Unable to read $skills_root: $!";
        for my $entry (
            sort grep {
                   $_ ne '.'
                && $_ ne '..'
                && -d File::Spec->catdir( $skills_root, $_ )
            } readdir $dh
          )
        {
            next if $seen_names{$entry}++;
            my $skill_root = File::Spec->catdir( $skills_root, $entry );
            my $disabled = -f File::Spec->catfile( $skill_root, '.disabled' ) ? 1 : 0;
            next if !$args{include_disabled} && $disabled;
            push @roots, $skill_root;
        }
        closedir $dh;
    }
    return @roots;
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
      grep {
            my $path = $_;
            $path eq $skills_root || index( $path, $prefix ) == 0;
      } $self->installed_skill_roots(%args);
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
    return md5_hex( defined $identity ? $identity : '' );
}

# _state_root_user()
# Returns a sanitized username used to namespace runtime state roots in the shared temp area.
# Input: none.
# Output: username string.
sub _state_root_user {
    my ($self) = @_;
    my $raw = $ENV{DD_STATE_ROOT_USER} || $ENV{USER} || $ENV{LOGNAME} || getpwuid($<) || 'user';
    $raw =~ s{[^A-Za-z0-9._-]}{_}g;
    return $raw || 'user';
}

# _state_root_for_layer($runtime_root)
# Returns the full state root for a runtime layer.
# Input: runtime layer path string.
# Output: directory path string.
sub _state_root_for_layer {
    my ( $self, $runtime_root ) = @_;
    my $dir = File::Spec->catdir( $self->state_base_root, $self->_state_root_key($runtime_root) );
    $self->_ensure_state_dir($dir);
    $self->_write_state_metadata( $dir, $runtime_root );
    return $dir;
}

# _write_state_metadata($dir, $runtime_root)
# Records the runtime identity for one hashed temp-state root, recreating the
# hashed directory first if temp cleanup removed it.
# Input: state root directory path and originating runtime root path.
# Output: metadata file path string.
sub _write_state_metadata {
    my ( $self, $dir, $runtime_root ) = @_;
    return '' if !defined $dir || $dir eq '';
    return '' if !defined $runtime_root || $runtime_root eq '';
    $self->_ensure_state_dir($dir);
    my $file = File::Spec->catfile( $dir, 'runtime.json' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode(
        {
            runtime_root => $runtime_root,
            app_name     => $self->app_name,
        }
    );
    close $fh or die "Unable to close $file: $!";
    $self->secure_file_permissions($file);
    return $file;
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
# Returns the configuration root directory.
# Input: none.
# Output: directory path string.
sub config_root {
    my ($self) = @_;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIGS} ) {
        return $self->_ensure_dir( $self->_expand_home($dir) );
    }
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'config' ) );
}

# config_roots()
# Returns the configuration roots in effective lookup order.
# Input: none.
# Output: ordered list of configuration root directory path strings.
sub config_roots {
    my ($self) = @_;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIGS} ) {
        return ( $self->_ensure_dir( $self->_expand_home($dir) ) );
    }
    return map { File::Spec->catdir( $_, 'config' ) } $self->runtime_roots;
}

# config_layers()
# Returns the configuration roots in inheritance order from home to deepest
# layer.
# Input: none.
# Output: ordered list of configuration root directory path strings.
sub config_layers {
    my ($self) = @_;
    if ( my $dir = $ENV{DEVELOPER_DASHBOARD_CONFIGS} ) {
        return ( $self->_ensure_dir( $self->_expand_home($dir) ) );
    }
    return map { File::Spec->catdir( $_, 'config' ) } $self->runtime_layers;
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
    return $self->project_root_for( cwd() );
}

# project_root_for($start_dir)
# Resolves the nearest git project root for a starting directory.
# Input: starting directory path.
# Output: directory path string or undef.
sub project_root_for {
    my ( $self, $start_dir ) = @_;

    my $dir = $start_dir || cwd();

    while ($dir) {
        return $dir if -d File::Spec->catdir( $dir, '.git' );

        my $parent = dirname($dir);
        last if !$parent || $parent eq $dir;
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

# resolve_dir($name)
# Resolves a logical directory name or absolute path.
# Input: logical directory name or absolute path.
# Output: resolved directory path string.
sub resolve_dir {
    my ( $self, $name ) = @_;

    die 'Missing path name' if !defined $name || $name eq '';

    return $name if File::Spec->file_name_is_absolute($name);

    return $self->$name() if $self->can($name);

    if ( exists $self->{named_paths}{$name} ) {
        my $path = $self->{named_paths}{$name};
        $path = $self->_expand_home($path);
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
    my $old = cwd();
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
        next if !defined $path || !-d $path;

        my $path_id = $self->_path_identity($path);
        next if $path_id eq '' || $seen{$path_id}++;

        my $relative = $path_id eq $root_id ? '.' : File::Spec->abs2rel( $path_id, $root_id );
        $relative = '.' if !defined $relative || $relative eq '';
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
# Output: boolean true when the path is inside ~/.developer-dashboard.
sub is_home_runtime_path {
    my ( $self, $path ) = @_;
    return 0 if !defined $path || $path eq '';
    return $self->_same_or_descendant_path( $path, $self->home_runtime_path ) ? 1 : 0;
}

# secure_dir_permissions($dir)
# Tightens one home-runtime directory chain to owner-only mode.
# Input: directory path string.
# Output: directory path string.
sub secure_dir_permissions {
    my ( $self, $dir ) = @_;
    return $dir if !$self->is_home_runtime_path($dir);

    my $home_runtime = $self->home_runtime_path;
    my $path = $home_runtime;
    chmod 0700, $path or die "Unable to chmod $path to 0700: $!" if -d $path;
    return $dir if $dir eq $home_runtime;

    my $suffix = substr( $dir, length($home_runtime) );
    $suffix =~ s{^/}{};
    for my $part ( grep { defined && $_ ne '' } File::Spec->splitdir($suffix) ) {
        $path = File::Spec->catdir( $path, $part );
        next if !-d $path;
        chmod 0700, $path or die "Unable to chmod $path to 0700: $!";
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
    return $file if !$self->is_home_runtime_path($file) && !$self->_is_state_path($file);
    return $file if !-e $file;
    my $mode = $args{executable} ? 0700 : 0600;
    chmod $mode, $file or die sprintf 'Unable to chmod %s to %04o: %s', $file, $mode, $!;
    return $file;
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
        if ( $self->is_home_runtime_path($dir) ) {
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
        chmod 0700, $dir or die sprintf 'Unable to chmod %s to 0700: %s', $dir, $!;
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
# Discovers every existing .developer-dashboard layer between the current
# working directory and the configured home directory, excluding the home
# runtime root itself.
# Input: none.
# Output: ordered list of runtime root directory path strings from parentmost
# child layer to the deepest current layer.
sub _ancestor_runtime_layers {
    my ($self) = @_;
    my $cwd = eval { cwd() };
    return () if !defined $cwd || $cwd eq '';
    my $home = $self->home;
    my $home_runtime = $self->home_runtime_path;
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
    my $dir = $cwd;
    while ($dir) {
        my $candidate = File::Spec->catdir( $dir, '.developer-dashboard' );
        my $visible_candidate = $self->_display_path($candidate);
        push @layers, $visible_candidate if -d $candidate && $self->_path_identity($candidate) ne $self->_path_identity($home_runtime);
        last if $self->_path_identity($dir) eq $self->_path_identity($stop_dir);
        my $parent = dirname($dir);
        last if !$parent || $parent eq $dir;
        $dir = $parent;
    }
    return reverse @layers;
}

# _path_identity($path)
# Normalizes a path for identity and ancestry comparisons without requiring the
# caller to care about symlink aliases such as /var versus /private/var on macOS.
# Input: path string.
# Output: canonical existing path or a stable canonpath string.
sub _path_identity {
    my ( $self, $path ) = @_;
    return '' if !defined $path || $path eq '';
    my $resolved = eval { abs_path($path) };
    return $resolved if defined $resolved && $resolved ne '';
    return File::Spec->canonpath($path);
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
    return $path if $path_id eq '' || $ref_id eq '';

    my $prefix = $ref_id;
    $prefix .= '/' if $prefix !~ m{/$};
    return $path if index( $path_id, $prefix ) != 0;

    my $relative = substr( $path_id, length($prefix) );
    $relative =~ s{^/}{} if defined $relative;
    return $reference if !$relative;

    my @segments = grep { $_ ne '' && $_ ne '.' && $_ ne '..' } File::Spec->splitdir($relative);
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
        next if $candidate eq '';
        next if $self->_path_identity($candidate) ne $self->_path_identity($path);
        return $candidate;
    }

    return $path;
}

# _same_or_descendant_path($path, $root)
# Checks whether one path is identical to or nested beneath another path after
# canonical normalization.
# Input: candidate path string and root path string.
# Output: boolean.
sub _same_or_descendant_path {
    my ( $self, $path, $root ) = @_;
    return 0 if !defined $path || $path eq '' || !defined $root || $root eq '';
    my $path_id = $self->_path_identity($path);
    my $root_id = $self->_path_identity($root);
    return 1 if $path_id eq $root_id;
    return index( $path_id, $root_id . '/' ) == 0 ? 1 : 0;
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
    return grep { defined $_ && $_ ne '' } split /\n/, $raw;
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

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the authoritative path model for the runtime. It discovers the layered runtime roots from home to the current project, resolves standard runtime directories, manages named path aliases, and performs project and directory searches such as the regex-based narrowing used by C<cdr>.

=head1 WHY IT EXISTS

It exists because C<DD-OOP-LAYERS> is a cross-runtime contract, not a convenience helper. One path registry has to own how home and project runtimes participate, which layer is writable, and how named paths and directory searches behave on top of that model.

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
