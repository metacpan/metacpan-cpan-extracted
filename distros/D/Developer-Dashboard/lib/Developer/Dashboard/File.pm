package Developer::Dashboard::File;

use strict;
use warnings;

our $VERSION = '3.14';

use File::Spec;
use Scalar::Util qw(blessed);

use Developer::Dashboard::Config ();
use Developer::Dashboard::FileRegistry ();
use Developer::Dashboard::PathRegistry ();

our $FILES;
our %ALIASES;
our %CONFIG_ALIASES;
our $CONFIG_ALIASES_KEY = '';
our $AUTOLOAD;

# configure(%args)
# Configures the compatibility file registry from runtime paths and aliases.
# Input: optional file registry object, optional paths object, and aliases hash.
# Output: true value.
sub configure {
    my ( $class, %args ) = @_;
    $FILES = $args{files} if $args{files};
    if ( !$FILES && $args{paths} ) {
        $FILES = Developer::Dashboard::FileRegistry->new( paths => $args{paths} );
    }
    %ALIASES = %{ $args{aliases} || {} };
    %CONFIG_ALIASES = ();
    $CONFIG_ALIASES_KEY = '';
    return 1;
}

# all()
# Returns the full runtime file inventory exposed by C<dashboard files>.
# Input: none.
# Output: hash reference describing the active runtime file set plus named aliases.
sub all {
    my $files = _files_obj();
    _load_configured_aliases();
    return {} if !$files || !$files->can('all_files');
    return $files->all_files;
}

# exists($file)
# Checks whether a resolved file path exists on disk.
# Input: logical file name, alias, or literal path.
# Output: boolean true when the file exists.
sub exists {
    my ( $class, $file ) = @_;
    my $path = $class->_resolve_file($file);
    return $path && -f $path ? 1 : 0;
}

# read($file)
# Reads a file by absolute path or configured alias.
# Input: file path or alias.
# Output: file contents string or undef.
sub read {
    my ( $class, $file ) = @_;
    my $path = $class->_resolve_file($file);
    return if !defined $path || !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    return <$fh>;
}

# cat($file)
# Compatibility alias for read that returns the full file content.
# Input: file path or alias.
# Output: file contents string or undef.
sub cat {
    my ( $class, $file ) = @_;
    return $class->read($file);
}

# resolve($file)
# Resolves a file path or configured alias without reading the file content.
# Input: file path or alias string.
# Output: resolved file path string or undef.
sub resolve {
    my ( $class, $file ) = @_;
    return $class->_resolve_file($file);
}

# write($file, $content, $append)
# Writes full content to a file path or alias, optionally appending.
# Input: file path or alias, content string, and optional append flag.
# Output: file path string.
sub write {
    my ( $class, $file, $content, $append ) = @_;
    my $path = $class->_resolve_file($file);
    die 'Missing file path' if !defined $path || $path eq '';
    my $mode = $append ? '>>' : '>';
    open my $fh, $mode, $path or die "Unable to write $path: $!";
    print {$fh} defined $content ? $content : '';
    close $fh or die "Unable to close $path: $!";
    my $files = _files_obj();
    $files->paths->secure_file_permissions($path) if $files && $files->can('paths');
    return $path;
}

# touch($file)
# Ensures a resolved file exists without changing its content meaningfully.
# Input: file path or alias.
# Output: file path string.
sub touch {
    my ( $class, $file ) = @_;
    my $path = $class->_resolve_file($file);
    die 'Missing file path' if !defined $path || $path eq '';
    open my $fh, '>>', $path or die "Unable to touch $path: $!";
    close $fh or die "Unable to close $path: $!";
    my $files = _files_obj();
    $files->paths->secure_file_permissions($path) if $files && $files->can('paths');
    return $path;
}

# rm($file)
# Deletes a resolved file if it exists.
# Input: file path or alias.
# Output: file path string.
sub rm {
    my ( $class, $file ) = @_;
    my $path = $class->_resolve_file($file);
    unlink $path if defined $path && -e $path;
    return $path;
}

# _files_obj()
# Returns the configured file registry or lazily builds a default runtime-backed registry.
# Input: none.
# Output: blessed file registry object or undef when no home directory is available.
sub _files_obj {
    return $FILES if blessed($FILES);
    my $home = $ENV{HOME} || '';
    return if $home eq '';
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$home/$_" } qw(projects src work) ],
    );
    $FILES = Developer::Dashboard::FileRegistry->new( paths => $paths );
    _load_configured_aliases();
    return $FILES;
}

# _configured_alias_cache_key($files)
# Builds a stable cache key for config-backed File aliases.
# Input: resolved file registry object.
# Output: cache key string.
sub _configured_alias_cache_key {
    my ($files) = @_;
    return '' if !$files || !blessed($files);
    my $paths = $files->paths;
    return '' if !$paths || !blessed($paths);
    my $project_root = eval { $paths->current_project_root } || '';
    my @runtime_roots = eval { $paths->runtime_roots } || ();
    return join "\n", $project_root, @runtime_roots;
}

# _load_configured_aliases()
# Lazily loads config-backed file aliases into the compatibility resolver.
# Input: none.
# Output: true value.
sub _load_configured_aliases {
    my $files = blessed($FILES) ? $FILES : return 1;
    my $key = _configured_alias_cache_key($files);
    return 1 if $key ne '' && $CONFIG_ALIASES_KEY eq $key;

    my $config = Developer::Dashboard::Config->new( files => $files, paths => $files->paths );
    %CONFIG_ALIASES = %{ $config->file_aliases || {} };
    $files->register_named_files( \%CONFIG_ALIASES );
    $CONFIG_ALIASES_KEY = $key;
    return 1;
}

# _resolve_file($where)
# Resolves a named file alias or literal path.
# Input: alias or path string.
# Output: file path string or undef.
sub _resolve_file {
    my ( $class, $where ) = @_;
    return if !defined $where || $where eq '';
    return $where if File::Spec->file_name_is_absolute($where) || $where =~ m{/};
    _files_obj();
    _load_configured_aliases();
    my $files = blessed($FILES) ? $FILES : undef;
    return $files->$where() if $files && $files->can($where);
    return $ALIASES{$where} if defined $ALIASES{$where};
    return $CONFIG_ALIASES{$where} if defined $CONFIG_ALIASES{$where};
    my $env = 'DEVELOPER_DASHBOARD_FILE_' . uc($where);
    return $ENV{$env} if defined $ENV{$env} && $ENV{$env} ne '';
    return;
}

# AUTOLOAD()
# Resolves unknown file names from configured aliases or env overrides.
# Input: none.
# Output: file path string or dies on unknown alias.
sub AUTOLOAD {
    my ($class) = @_;
    my ($name) = $AUTOLOAD =~ /::([^:]+)$/;
    return if $name eq 'DESTROY';
    my $path = $class->_resolve_file($name);
    die "Unknown file '$name'" if !defined $path;
    return $path;
}

1;

__END__

=head1 NAME

Developer::Dashboard::File - older file compatibility wrapper

=head1 SYNOPSIS

  Developer::Dashboard::File->configure(aliases => { output => '/tmp/output.txt' });
  my $file = Developer::Dashboard::File->output;
  my $notes = Developer::Dashboard::File->resolve('notes');
  my $name = 123;
  my $numeric = Developer::Dashboard::File->$name();
  Developer::Dashboard::File->write(output => "ok\n");

=head1 DESCRIPTION

This module exposes a project-neutral compatibility layer for older bookmark
code that expects a C<File> package.

=head1 METHODS

=head2 resolve

Returns the resolved file path for one configured alias or literal path
without reading file content.

=head1 METHODS

=head2 configure, all, exists, read, cat, write, touch, rm

Configure and resolve compatibility files.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module provides named file resolution for runtime files and configured
aliases. It gives callers the same conceptual file names exposed by
C<dashboard files> and C<dashboard file list> without forcing them to know the
exact on-disk layout under the current runtime.

=head1 WHY IT EXISTS

It exists so code and bookmark snippets can refer to stable file concepts such
as C<global_config>, C<dashboard_log>, or configured aliases instead of
hard-coding file paths. That keeps file-aware code portable across home and
project-local runtimes.

=head1 WHEN TO USE

Use this file when a module, bookmark, or helper needs a named runtime file and
should not know whether the active file path came from the home runtime, a
project override, or a user-defined alias.

=head1 HOW TO USE

Load C<Developer::Dashboard::File> and ask it for the named file you need. Use
it as the semantic file layer above the lower-level file registry instead of
hard-coding F<~/.developer-dashboard> descendants.

When you need the complete resolved file payload that C<dashboard files>
prints, call C<Developer::Dashboard::File-E<gt>all>. It returns the same hash
shape as the CLI command.

=head1 WHAT USES IT

It is used by bookmark/runtime helper code, by compatibility tests, and by
contributors who need the older top-level File abstraction to resolve through
the current layered runtime.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::File -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's
behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a
load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before
release.

=for comment FULL-POD-DOC END

=cut
