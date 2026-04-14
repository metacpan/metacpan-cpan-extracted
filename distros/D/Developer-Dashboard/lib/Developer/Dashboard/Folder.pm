package Developer::Dashboard::Folder;

use strict;
use warnings;

our $VERSION = '2.35';

use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Find ();
use File::Path qw(make_path);
use File::Spec;
use Scalar::Util qw(blessed);

use Developer::Dashboard::Config ();
use Developer::Dashboard::FileRegistry ();
use Developer::Dashboard::PathRegistry ();

our $PATHS;
our %ALIASES;
our %CONFIG_ALIASES;
our $CONFIG_ALIASES_KEY = '';
our $AUTOLOAD;

# configure(%args)
# Configures the compatibility folder registry from runtime paths and aliases.
# Input: optional paths object and aliases hash.
# Output: true value.
sub configure {
    my ( $class, %args ) = @_;
    $PATHS = $args{paths} if $args{paths};
    %ALIASES = %{ $args{aliases} || {} };
    %CONFIG_ALIASES = ();
    $CONFIG_ALIASES_KEY = '';
    return 1;
}

# home()
# Returns the current home directory path.
# Input: none.
# Output: directory path string.
sub home {
    return $ENV{HOME} || '';
}

# tmp()
# Returns the temporary directory path.
# Input: none.
# Output: directory path string.
sub tmp {
    return File::Spec->tmpdir;
}

# dd()
# Returns the dashboard runtime root directory.
# Input: none.
# Output: directory path string.
sub dd {
    my $paths = _paths_obj();
    return $paths && $paths->can('runtime_root') ? $paths->runtime_root : '';
}

# bookmarks()
# Returns the dashboard bookmark directory.
# Input: none.
# Output: directory path string.
sub bookmarks {
    my $paths = _paths_obj();
    return $paths && $paths->can('dashboards_root') ? $paths->dashboards_root : '';
}

# configs()
# Returns the dashboard config directory.
# Input: none.
# Output: directory path string.
sub configs {
    my $paths = _paths_obj();
    return $paths && $paths->can('config_root') ? $paths->config_root : '';
}

# postman()
# Returns the neutral default postman collection directory.
# Input: none.
# Output: directory path string.
sub postman {
    my $dir = File::Spec->catdir( configs(), 'postman' );
    make_path($dir) if $dir ne '' && !-d $dir;
    return $dir;
}

# _paths_obj()
# Returns the configured paths object or lazily builds a default runtime path registry.
# Input: none.
# Output: blessed paths object or undef when no home directory is available.
sub _paths_obj {
    return $PATHS if blessed($PATHS);
    my $home = $ENV{HOME} || '';
    return if $home eq '';
    $PATHS = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
    );
    _load_configured_aliases();
    return $PATHS;
}

# _configured_alias_cache_key($paths)
# Builds a stable cache key for config-backed Folder aliases.
# Input: resolved path registry object.
# Output: cache key string.
sub _configured_alias_cache_key {
    my ($paths) = @_;
    return '' if !$paths || !blessed($paths);
    my $project_root = eval { $paths->current_project_root } || '';
    my @runtime_roots = eval { $paths->runtime_roots } || ();
    return join "\n", $project_root, @runtime_roots;
}

# _load_configured_aliases()
# Lazily loads config-backed path aliases into the compatibility resolver.
# Input: none.
# Output: true value.
sub _load_configured_aliases {
    my $paths = blessed($PATHS) ? $PATHS : return 1;
    my $key = _configured_alias_cache_key($paths);
    return 1 if $key ne '' && $CONFIG_ALIASES_KEY eq $key;

    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    %CONFIG_ALIASES = %{ $config->path_aliases || {} };
    $CONFIG_ALIASES_KEY = $key;
    return 1;
}

# cd($where, $code)
# Temporarily changes directory and invokes a callback.
# Input: named path or literal directory path plus callback.
# Output: callback return value or undef.
sub cd {
    my ( $class, $where, $code ) = @_;
    return if ref($code) ne 'CODE';
    my $pwd = cwd();
    my $dir = $class->_resolve_path($where);
    return if !$dir || !-d $dir;
    chdir $dir or return;
    my $parent = dirname($dir);
    my $result = $code->(
        {
            caller => $pwd,
            parent => $parent,
            dir    => $dir,
            stay   => sub { $pwd = $_[0] if defined $_[0] && $_[0] ne '' },
        }
    );
    chdir $pwd if $pwd;
    return $result;
}

# ls($where)
# Lists files and folders in a directory.
# Input: named path or literal directory path.
# Output: list of detail hashes.
sub ls {
    my ( $class, $where ) = @_;
    my $dir = $class->_resolve_path($where);
    return () if !$dir || !-d $dir;
    opendir my $dh, $dir or return ();
    my @items;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        my $path = File::Spec->catfile( $dir, $entry );
        push @items, {
            NAME => $entry,
            path => $path,
            type => -d $path ? 'folder' : 'file',
            size => -s $path || 0,
        };
    }
    closedir $dh;
    return sort { $b->{type} cmp $a->{type} || $a->{NAME} cmp $b->{NAME} } @items;
}

# locate(@parts)
# Locates matching directories below configured workspace roots.
# Input: name fragments.
# Output: matching absolute directory paths.
sub locate {
    my ( $class, @parts ) = @_;
    @parts = grep { defined && $_ ne '' } @parts;
    my $paths = _paths_obj();
    return () if !@parts || !$paths || !$paths->can('workspace_roots');
    my @found;
    for my $root ( $paths->workspace_roots ) {
        next if !-d $root;
        File::Find::find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return if !-d $_;
                    my $path = $File::Find::name;
                    my $name = $_;
                    for my $part (@parts) {
                        return if $name !~ /\Q$part\E/i && $path !~ /\Q$part\E/i;
                    }
                    push @found, $path;
                },
            },
            $root,
        );
    }
    my %seen;
    return grep { !$seen{$_}++ } sort @found;
}

# _resolve_path($where)
# Resolves a named folder alias or literal path.
# Input: alias or path string.
# Output: directory path string or undef.
sub _resolve_path {
    my ( $class, $where ) = @_;
    return if !defined $where || $where eq '';
    return $where if File::Spec->file_name_is_absolute($where) || -d $where;
    _paths_obj();
    _load_configured_aliases();
    my %legacy_aliases = (
        runtime_root   => 'dd',
        bookmarks_root => 'bookmarks',
        config_root    => 'configs',
    );
    if ( my $legacy = $legacy_aliases{$where} ) {
        return $class->$legacy() if $class->can($legacy);
    }
    return $class->$where() if $class->can($where);
    return $ALIASES{$where} if defined $ALIASES{$where};
    return $CONFIG_ALIASES{$where} if defined $CONFIG_ALIASES{$where};
    my $env = 'DEVELOPER_DASHBOARD_PATH_' . uc($where);
    return $ENV{$env} if defined $ENV{$env} && $ENV{$env} ne '';
    return;
}

# AUTOLOAD()
# Resolves unknown folder names from configured aliases or env overrides.
# Input: none.
# Output: directory path string or dies on unknown alias.
sub AUTOLOAD {
    my ($class) = @_;
    my ($name) = $AUTOLOAD =~ /::([^:]+)$/;
    return if $name eq 'DESTROY';
    my $path = $class->_resolve_path($name);
    die "Unknown folder '$name'" if !defined $path;
    make_path($path) if $path ne '' && $path =~ m{^/} && !-e $path;
    return $path;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Folder - older folder compatibility wrapper

=head1 SYNOPSIS

  Developer::Dashboard::Folder->configure(paths => $paths, aliases => { postman => '/tmp/postman' });
  my $dir = Developer::Dashboard::Folder->postman;

=head1 DESCRIPTION

This module exposes a project-neutral compatibility layer for older bookmark
code that expects a C<Folder> package.

=head1 METHODS

=head2 configure, home, tmp, dd, bookmarks, configs, cd, ls, locate

Configure and resolve compatibility folders.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module provides named folder resolution for runtime roots and configured aliases. It gives callers the same conceptual folder names exposed by C<dashboard paths> without forcing them to know the exact on-disk layout under the current runtime.

=head1 WHY IT EXISTS

It exists so code and bookmark snippets can refer to stable folder concepts such as C<runtime>, C<dashboards>, or configured aliases instead of hard-coding layout paths. That keeps folder-aware code portable across home and project-local runtimes.

=head1 WHEN TO USE

Use this file when a module, bookmark, or helper needs a named runtime directory and should not know whether the active path came from the home runtime, a project override, or a user-defined alias.

=head1 HOW TO USE

Load C<Developer::Dashboard::Folder> and ask it for the named folder you need. Use it as the semantic folder layer above the lower-level path registry instead of hard-coding F<~/.developer-dashboard> descendants.

=head1 WHAT USES IT

It is used by bookmark/runtime helper code, by prompt and file operations that want named folder resolution, and by tests that keep alias and runtime-root behavior consistent.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Folder -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/21-refactor-coverage.t t/00-load.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
