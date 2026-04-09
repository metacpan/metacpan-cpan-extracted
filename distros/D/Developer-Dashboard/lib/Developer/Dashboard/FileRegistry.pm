package Developer::Dashboard::FileRegistry;

use strict;
use warnings;

our $VERSION = '2.02';

use File::Spec;

# new(%args)
# Constructs a logical file registry.
# Input: paths object.
# Output: Developer::Dashboard::FileRegistry object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return bless { paths => $paths }, $class;
}

# paths()
# Returns the associated path registry instance.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object.
sub paths { $_[0]->{paths} }

# resolve_file($name)
# Resolves a logical file name or absolute path to a concrete file path.
# Input: logical file name or absolute path string.
# Output: absolute or resolved file path string.
sub resolve_file {
    my ( $self, $name ) = @_;

    return $name if File::Spec->file_name_is_absolute($name);
    return $self->$name() if $self->can($name);

    die "Unknown file name '$name'";
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

=head2 prompt_log, collector_log, dashboard_log, global_config, dashboard_index, auth_log, web_pid, web_state

Return known runtime file paths.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file resolves named runtime files and keeps file-backed resources consistent.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::FileRegistry> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::FileRegistry -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
