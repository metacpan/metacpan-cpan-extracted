package Developer::Dashboard::CLI::Paths;

use strict;
use warnings;

our $VERSION = '2.02';

use Cwd qw(cwd);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;

# run_paths_command(%args)
# Dispatches the lightweight dashboard path/paths CLI behaviour without loading
# the main dashboard runtime.
# Input: command name under "command" plus the remaining argv array reference
# under "args".
# Output: prints the requested path data to STDOUT and exits successfully, or
# dies with a usage message when the arguments are invalid.
sub run_paths_command {
    my (%args) = @_;
    my $command = $args{command} || die "Missing command name\n";
    my $argv    = $args{args}    || die "Missing command arguments\n";
    die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my $paths = _build_paths();
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $aliases_loaded = 0;
    my $load_configured_path_aliases = sub {
        return 1 if $aliases_loaded;
        $paths->register_named_paths( $config->path_aliases );
        $aliases_loaded = 1;
        return 1;
    };

    if ( $command eq 'paths' ) {
        $load_configured_path_aliases->();
        print json_encode( _paths_payload($paths) );
        return 1;
    }

    my @argv = @{$argv};
    my $action = shift @argv || '';
    if ( $action eq 'resolve' ) {
        $load_configured_path_aliases->();
        my $name = shift @argv || die "Usage: dashboard path resolve <name>\n";
        print $paths->resolve_dir($name), "\n";
        return 1;
    }
    if ( $action eq 'locate' ) {
        print json_encode( [ $paths->locate_projects(@argv) ] );
        return 1;
    }
    if ( $action eq 'add' ) {
        my $name = shift @argv || die "Usage: dashboard path add <name> <path>\n";
        my $path = shift @argv || die "Usage: dashboard path add <name> <path>\n";
        my $saved = $config->save_global_path_alias( $name, $path );
        $paths->register_named_paths( { $name => $path } );
        $saved->{resolved} = $paths->resolve_dir($name);
        print json_encode($saved);
        return 1;
    }
    if ( $action eq 'del' ) {
        my $name = shift @argv || die "Usage: dashboard path del <name>\n";
        my $deleted = $config->remove_global_path_alias($name);
        $paths->unregister_named_path($name);
        print json_encode($deleted);
        return 1;
    }
    if ( $action eq 'project-root' ) {
        my $root = $paths->current_project_root;
        print defined $root ? "$root\n" : '';
        return 1;
    }
    if ( $action eq 'list' ) {
        $load_configured_path_aliases->();
        print json_encode( _path_list_payload($paths) );
        return 1;
    }

    die "Usage: dashboard path <resolve|locate|add|del|project-root|list> ...\n";
}

# _build_paths()
# Builds the lightweight path registry used by the path helper commands.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object scoped to the current cwd.
sub _build_paths {
    my $home = $ENV{HOME} || '';
    my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);
    return Developer::Dashboard::PathRegistry->new(
        home            => $home,
        cwd             => cwd(),
        workspace_roots => \@roots,
        project_roots   => \@roots,
    );
}

# _paths_payload($paths)
# Builds the JSON payload for C<dashboard paths>.
# Input: path registry object.
# Output: hash reference describing the active runtime path set.
sub _paths_payload {
    my ($paths) = @_;
    return {
        home                 => $paths->home,
        home_runtime_root    => $paths->home_runtime_root,
        project_runtime_root => scalar $paths->project_runtime_root,
        runtime_root         => $paths->runtime_root,
        state_root           => $paths->state_root,
        cache_root           => $paths->cache_root,
        logs_root            => $paths->logs_root,
        dashboards_root      => $paths->dashboards_root,
        bookmarks_root       => $paths->bookmarks_root,
        cli_root             => $paths->cli_root,
        collectors_root      => $paths->collectors_root,
        indicators_root      => $paths->indicators_root,
        config_root          => $paths->config_root,
        current_project_root => scalar $paths->current_project_root,
        %{ $paths->named_paths },
    };
}

# _path_list_payload($paths)
# Builds the JSON payload for C<dashboard path list>.
# Input: path registry object.
# Output: hash reference of named path aliases plus the standard runtime roots.
sub _path_list_payload {
    my ($paths) = @_;
    return {
        home            => $paths->home,
        home_runtime    => $paths->home_runtime_root,
        project_runtime => scalar $paths->project_runtime_root,
        runtime         => $paths->runtime_root,
        state           => $paths->state_root,
        cache           => $paths->cache_root,
        logs            => $paths->logs_root,
        dashboards      => $paths->dashboards_root,
        bookmarks       => $paths->bookmarks_root,
        cli             => $paths->cli_root,
        config          => $paths->config_root,
        collectors      => $paths->collectors_root,
        indicators      => $paths->indicators_root,
        %{ $paths->named_paths },
    };
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Paths - lightweight path and paths helper dispatch

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Paths qw(run_paths_command);
  run_paths_command(command => 'paths', args => \@ARGV);

=head1 DESCRIPTION

Implements the lightweight C<dashboard path> and C<dashboard paths> commands so
the public entrypoint can hand off path-related work to an extracted helper
script under F<~/.developer-dashboard/cli/>.

=head1 FUNCTIONS

=head2 run_paths_command

Dispatch the path helper command.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file implements the reusable path-reporting logic behind the path and paths helpers.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::CLI::Paths> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::CLI::Paths -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
