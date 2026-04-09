package Developer::Dashboard::Folder;

use strict;
use warnings;

our $VERSION = '2.02';

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

Perl module in the Developer Dashboard codebase. This file provides reusable directory helpers used throughout the runtime.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::Folder> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::Folder -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
