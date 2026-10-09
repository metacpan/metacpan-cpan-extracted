package Developer::Dashboard::FileRegistry;

use strict;
use warnings;

our $VERSION = '5.73';

use File::Spec;
use File::Find ();
use File::Path ();
use Developer::Dashboard::Config ();
use Developer::Dashboard::PathsRegistryArg qw(require_paths_arg);

# new(%args)
# Constructs a logical file registry.
# Input: paths object.
# Output: Developer::Dashboard::FileRegistry object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = require_paths_arg(%args);
    return bless {
        paths                  => $paths,
        named_files            => {},
        configured_named_files => {},
    }, $class;
}

# paths()
# Returns the associated path registry instance.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object.
sub paths { $_[0]->{paths} }

# register_named_files($aliases)
# Registers config-backed named file aliases for later resolution.
# Input: hash reference of alias names to absolute file paths.
# Output: invocant.
sub register_named_files {
    my ( $self, $aliases ) = @_;
    return $self if ref($aliases) ne 'HASH';
    for my $name ( keys %{$aliases} ) {
        next if $name eq '';
        my $path = $aliases->{$name};
        next if !defined $path || $path eq '';
        $self->{named_files}{$name} = $path;
    }
    return $self;
}

# unregister_named_file($name)
# Removes one registered named file alias when present.
# Input: alias name string.
# Output: invocant.
sub unregister_named_file {
    my ( $self, $name ) = @_;
    return $self if !defined $name || $name eq '';
    delete $self->{named_files}{$name};
    delete $self->{configured_named_files}{$name};
    return $self;
}

# named_files()
# Returns the registered named file aliases as plain file-path strings for
# display. DD-1005: a lazy-create file alias is stored internally as a
# metadata hash ({path=>,create=>1,mode=>}); this accessor collapses it to
# its bare "path" field, mirroring PathRegistry::named_paths' identical
# treatment - resolve_file reads the raw hash directly, so the metadata is
# never lost, only hidden from display consumers with no use for it.
# Input: none.
# Output: hash reference of alias names to file paths.
sub named_files {
    my ($self) = @_;
    $self->_load_configured_named_files;
    my %raw = (
        %{ $self->{configured_named_files} },
        %{ $self->{named_files} },
    );
    my %plain;
    for my $name ( keys %raw ) {
        my $entry = $raw{$name};
        $plain{$name} = ref($entry) eq 'HASH' ? $entry->{path} : $entry;
    }
    return \%plain;
}

# all_files()
# Returns the complete runtime file inventory plus registered aliases.
# Input: none.
# Output: hash reference of file keys to absolute file paths.
sub all_files {
    my ($self) = @_;
    $self->_load_configured_named_files;
    my %all = %{ $self->all_file_aliases };
    for my $name ( keys %{ $self->named_files } ) {
        $all{$name} = $self->named_files->{$name};
    }
    return \%all;
}

# all_file_aliases()
# Returns the runtime named file inventory exposed by dashboard file list.
# Input: none.
# Output: hash reference of built-in logical file names to absolute file paths.
sub all_file_aliases {
    my ($self) = @_;
    return {
        prompt_log      => $self->prompt_log,
        collector_log   => $self->collector_log,
        dashboard_log   => $self->dashboard_log,
        global_config   => $self->global_config,
        dashboard_index => $self->dashboard_index,
        auth_log        => $self->auth_log,
        web_pid         => $self->web_pid,
        web_state       => $self->web_state,
    };
}

# locate_files(@terms)
# Locates matching files below the current directory.
# Input: one or more non-empty search terms.
# Output: ordered list of matching file paths.
sub locate_files {
    my ( $self, @terms ) = @_;
    @terms = grep { defined && $_ ne '' } @terms;
    return () if !@terms;
    return $self->locate_files_under( $self->paths->cwd, @terms );
}

# locate_files_under($root, @terms)
# Locates matching files beneath one root directory using case-insensitive term matches.
# Input: root directory path plus one or more search terms.
# Output: ordered unique list of matching file paths.
sub locate_files_under {
    my ( $self, $root, @terms ) = @_;
    @terms = grep { defined && $_ ne '' } @terms;
    return () if !defined $root || $root eq '' || !-d $root || !@terms;

    my @found;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if !-f $_;
                # With no_chdir the visited $_ equals $File::Find::name (the full
                # pathname), so matching each term against that path already
                # covers the basename and the directory components.
                my $path = $File::Find::name;
                for my $term (@terms) {
                    return if $path !~ /\Q$term\E/i;
                }
                push @found, $path;
            },
        },
        $root,
    );

    my %seen;
    return grep { !$seen{$_}++ } sort @found;
}

# DD-868: the method-name fallback below must dispatch ONLY to these
# no-arg path getters - never to the class's other public methods (which
# take required arguments and/or mutate state), or a name typed straight
# from the CLI (dashboard file resolve/locate) becomes an arbitrary method
# call on this object.
my %RESOLVABLE_ACCESSOR = map { $_ => 1 } qw(
  prompt_log collector_log dashboard_log global_config
  dashboard_index auth_log web_pid web_state
);

# resolve_file($name)
# Resolves a logical file name or absolute path to a concrete file path.
# DD-1005 (Q-184, option A): when the registered alias carries lazy-create
# metadata and the resolved file's PARENT directory does not exist, the
# parent is created here (with its own parents, mkdir -p semantics) and
# chmod'd to the stored mode if one was given - the file itself is left
# absent, since "lazy create" for a FILE alias means the target is safe to
# open/write, not that an empty file should be fabricated at the exact
# path. This is the one place the logic lives, mirroring
# PathRegistry::resolve_dir's identical single-resolver placement.
# Input: logical file name or absolute path string.
# Output: absolute or resolved file path string.
sub resolve_file {
    my ( $self, $name ) = @_;

    return $name if File::Spec->file_name_is_absolute($name);

    my $entry =
        exists $self->{named_files}{$name}            ? $self->{named_files}{$name}
      : do { $self->_load_configured_named_files; exists $self->{configured_named_files}{$name} ? $self->{configured_named_files}{$name} : undef };

    if ( defined $entry ) {
        my ( $path, $create, $mode ) =
          ref($entry) eq 'HASH' ? ( $entry->{path}, $entry->{create}, $entry->{mode} ) : ( $entry, undef, undef );
        if ($create) {
            # File::Spec->splitpath's second return value is always a
            # defined string (possibly empty), never undef, for any string
            # input; $path itself is always a defined alias path by the
            # time this runs, so "defined $parent" below can never
            # observably be false.
            my $parent = ( File::Spec->splitpath($path) )[1];
            if ( $parent ne '' && !-d $parent ) {
                File::Path::make_path($parent);
                chmod( oct($mode), $parent ) if defined $mode && $mode ne '';
            }
        }
        return $path;
    }

    return $self->$name() if $RESOLVABLE_ACCESSOR{$name};

    die "Unknown file name '$name'";
}

# _load_configured_named_files()
# Lazily loads config-backed file aliases into the registry when they have not
# already been registered explicitly.
# Input: none.
# Output: invocant.
sub _load_configured_named_files {
    my ($self) = @_;
    my $config = Developer::Dashboard::Config->new( files => $self, paths => $self->paths );
    $self->{configured_named_files} = $config->file_aliases;
    return $self;
}

# read($name)
# Reads the full contents of a resolved file.
# Input: logical file name or absolute path string.
# Output: file contents string or undef when the file is missing.
sub read {
    my ( $self, $name ) = @_;
    my $file = $self->resolve_file($name);
    return if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return <$fh>;
}

# write($name, $content)
# Writes full content to a resolved file path.
# Input: logical file name and content string.
# Output: written file path string.
sub write {
    my ( $self, $name, $content ) = @_;
    my $file = $self->resolve_file($name);
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} defined $content ? $content : '';
    close $fh;
    $self->paths->secure_file_permissions($file);
    return $file;
}

# append($name, $content)
# Appends content to a resolved file path.
# Input: logical file name and content string.
# Output: appended file path string.
sub append {
    my ( $self, $name, $content ) = @_;
    my $file = $self->resolve_file($name);
    open my $fh, '>>', $file or die "Unable to append $file: $!";
    print {$fh} defined $content ? $content : '';
    close $fh;
    $self->paths->secure_file_permissions($file);
    return $file;
}

# touch($name)
# Ensures a resolved file exists without changing its content meaningfully.
# Input: logical file name.
# Output: touched file path string.
sub touch {
    my ( $self, $name ) = @_;
    my $file = $self->resolve_file($name);
    open my $fh, '>>', $file or die "Unable to touch $file: $!";
    close $fh;
    $self->paths->secure_file_permissions($file);
    return $file;
}

# remove($name)
# Deletes a resolved file if it exists.
# Input: logical file name.
# Output: removed file path string.
sub remove {
    my ( $self, $name ) = @_;
    my $file = $self->resolve_file($name);
    unlink $file if -e $file;
    return $file;
}

# prompt_log()
# Returns the prompt log file path.
# Input: none.
# Output: file path string.
sub prompt_log {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->logs_root, 'prompt.log' );
}

# collector_log()
# Returns the collector log file path.
# Input: none.
# Output: file path string.
sub collector_log {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->logs_root, 'collectors.log' );
}

# dashboard_log()
# Returns the dashboard runtime log file path.
# Input: none.
# Output: file path string.
sub dashboard_log {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->logs_root, 'dashboard.log' );
}

# global_config()
# Returns the global configuration file path.
# Input: none.
# Output: file path string.
sub global_config {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->config_root, 'config.json' );
}

# dashboard_index()
# Returns the dashboard index file path.
# Input: none.
# Output: file path string.
sub dashboard_index {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->dashboards_root, 'index' );
}

# auth_log()
# Returns the auth log file path.
# Input: none.
# Output: file path string.
sub auth_log {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->logs_root, 'auth.log' );
}

# web_pid()
# Returns the web service pid file path.
# Input: none.
# Output: file path string.
sub web_pid {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->state_root, 'web.pid' );
}

# web_state()
# Returns the persisted web service state file path.
# Input: none.
# Output: file path string.
sub web_state {
    my ($self) = @_;
    return File::Spec->catfile( $self->paths->state_root, 'web.json' );
}

1;

__END__

=head1 NAME

Developer::Dashboard::FileRegistry - logical file registry for Developer Dashboard

=head1 SYNOPSIS

  my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
  my $json  = $files->read('global_config');

=head1 DESCRIPTION

This module maps logical file names to concrete runtime files and provides
small convenience methods for reading and writing them.

=head1 METHODS

=head2 new

Construct a registry bound to a path registry.

=head2 resolve_file, read, write, append, touch, remove

Resolve and manage named files.

resolve_file() (DD-1005, Q-184 option A) additionally creates a registered
file alias's PARENT directory (with its own parents) on first resolution
when that alias was saved with C<create =E<gt> 1> (see
C<Developer::Dashboard::Config>'s save_global_file_alias()'s C<%opts>),
chmod'ing the parent to the alias's stored octal mode when one was given -
the file itself is deliberately left absent, since lazy-create for a file
alias means the target is safe to open/write, not that an empty file
should be fabricated at the exact path. named_files() collapses such an
alias back to a bare path string for display consumers, mirroring
C<Developer::Dashboard::PathRegistry>'s named_paths().

=head2 prompt_log, collector_log, dashboard_log, global_config, dashboard_index, auth_log, web_pid, web_state

Return known runtime file paths.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the runtime file-system facade. It resolves the concrete files and directories under the layered runtime tree, loads and writes dashboard-managed files, and gives higher-level services a single place to ask for runtime paths and file content without rebuilding path logic themselves.

=head1 WHY IT EXISTS

It exists because many subsystems need to read and write runtime files, but they should not each re-implement path resolution and permission handling. Centralizing file access keeps layered lookup and file ownership consistent across the runtime.

=head1 WHEN TO USE

Use this file when changing how runtime files are discovered, written, or permissioned, especially for config, dashboard pages, state files, or staged helper assets.

=head1 HOW TO USE

Construct it with a path registry and use it as the file access layer for modules that need runtime data. Keep raw path math and secure write behavior here rather than repeating it in feature modules.

=head1 WHAT USES IT

It is used by config, auth, page, session, init, and web modules throughout the runtime, along with the tests that verify layered file lookup and non-destructive writes.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::FileRegistry -e 1

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
