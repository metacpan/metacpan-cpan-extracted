package Developer::Dashboard::PathRegistry;

use strict;
use warnings;

our $VERSION = '1.33';

use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Find ();
use File::Path qw(make_path);
use File::Spec;

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

# runtime_root()
# Returns the effective runtime root directory.
# Input: none.
# Output: project-local runtime directory when available, otherwise the home runtime directory.
sub runtime_root {
    my ($self) = @_;
    return $self->project_runtime_root || $self->home_runtime_root;
}

# home_runtime_root()
# Returns the home-backed runtime root directory.
# Input: none.
# Output: home runtime directory path string.
sub home_runtime_root {
    my ($self) = @_;
    return $self->_ensure_dir(
        File::Spec->catdir( $self->home, '.developer-dashboard' )
    );
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
# Output: ordered list of runtime root directory path strings.
sub runtime_roots {
    my ($self) = @_;
    my @roots;
    my %seen;
    for my $root ( $self->project_runtime_root, $self->home_runtime_root ) {
        next if !defined $root || $root eq '';
        next if $seen{$root}++;
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
    return $self->_ensure_dir( File::Spec->catdir( $self->runtime_root, 'state' ) );
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
    return map { $self->_ensure_dir( File::Spec->catdir( $_, 'dashboards' ) ) } $self->runtime_roots;
}

# bookmarks()
# Returns the legacy bookmark directory alias.
# Input: none.
# Output: directory path string.
sub bookmarks {
    my ($self) = @_;
    return $self->dashboards_root;
}

# bookmarks_root()
# Returns the legacy bookmark root alias.
# Input: none.
# Output: directory path string.
sub bookmarks_root {
    my ($self) = @_;
    return $self->dashboards_root;
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
    return map { $self->_ensure_dir( File::Spec->catdir( $_, 'cli' ) ) } $self->runtime_roots;
}

# collectors_root()
# Returns the collectors state root directory.
# Input: none.
# Output: directory path string.
sub collectors_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->state_root, 'collectors' ) );
}

# indicators_root()
# Returns the indicators state root directory.
# Input: none.
# Output: directory path string.
sub indicators_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->state_root, 'indicators' ) );
}

# sessions_root()
# Returns the sessions state root directory.
# Input: none.
# Output: directory path string.
sub sessions_root {
    my ($self) = @_;
    return $self->_ensure_dir( File::Spec->catdir( $self->state_root, 'sessions' ) );
}

# sessions_roots()
# Returns the session storage roots in effective lookup order.
# Input: none.
# Output: ordered list of session root directory path strings.
sub sessions_roots {
    my ($self) = @_;
    return map { $self->_ensure_dir( File::Spec->catdir( $_, 'state', 'sessions' ) ) } $self->runtime_roots;
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
    return map { $self->_ensure_dir( File::Spec->catdir( $_, 'config' ) ) } $self->runtime_roots;
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
    return map { $self->_ensure_dir( File::Spec->catdir( $_, 'auth' ) ) } $self->config_roots;
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
    return map { $self->_ensure_dir( File::Spec->catdir( $_, 'users' ) ) } $self->auth_roots;
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

# _ensure_dir($dir)
# Creates a directory if needed and returns it.
# Input: directory path string.
# Output: directory path string.
sub _ensure_dir {
    my ( $self, $dir ) = @_;
    make_path($dir) if !-d $dir;
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

=head2 resolve_dir, resolve_any, locate_projects, current_project_root, project_root_for

Resolve and discover project-related directories.

=cut
