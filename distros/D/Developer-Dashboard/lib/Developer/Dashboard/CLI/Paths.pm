package Developer::Dashboard::CLI::Paths;

use strict;
use warnings;

our $VERSION = '2.26';

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
    if ( $action eq 'cdr' ) {
        $load_configured_path_aliases->();
        print json_encode( _cdr_payload( paths => $paths, args => \@argv ) );
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

    die "Usage: dashboard path <resolve|locate|cdr|add|del|project-root|list> ...\n";
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

# _cdr_payload(%args)
# Resolves the shell helper target for cdr/which_dir without pushing fuzzy
# search logic into shell code.
# Input: hash containing a path registry under "paths" and an argv array
# reference under "args".
# Output: hash reference with "target" and "matches" keys.
sub _cdr_payload {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $argv  = $args{args}  || [];
    die "cdr args must be an array reference\n" if ref($argv) ne 'ARRAY';

    my @terms = @{$argv};
    return { target => '', matches => [] } if !@terms;

    my $first = $terms[0];
    my $alias_target = eval { $paths->resolve_dir($first) };
    if ( defined $alias_target && $alias_target ne '' ) {
        shift @terms;
        return { target => $alias_target, matches => [] } if !@terms;
        my @matches = $paths->locate_dirs_under( $alias_target, @terms );
        return {
            target  => @matches == 1 ? $matches[0] : $alias_target,
            matches => @matches == 1 ? [] : \@matches,
        };
    }

    my @matches = $paths->locate_dirs_under( cwd(), @terms );
    return {
        target  => @matches == 1 ? $matches[0] : '',
        matches => @matches == 1 ? [] : \@matches,
    };
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
script under F<~/.developer-dashboard/cli/>. That includes the shared
target-selection logic used by shell helpers such as C<cdr> and
C<which_dir>.

=head1 FUNCTIONS

=head2 run_paths_command

Dispatch the path helper command.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the command runtime behind C<dashboard paths> and C<dashboard path ...>. It prints the active runtime roots, resolves named aliases, persists alias add/delete operations, and computes the JSON payload used by shell helpers such as C<cdr> and C<which_dir>.

=head1 WHY IT EXISTS

It exists because path reporting and shell-navigation semantics should live in Perl, not in duplicated shell code. That keeps the layered runtime rules, alias loading, and regex-based directory narrowing consistent across bash, zsh, POSIX sh, and PowerShell.

=head1 WHEN TO USE

Use this file when changing the output of C<dashboard paths>, the behavior of C<dashboard path resolve/add/del/list/project-root>, or the C<cdr> payload contract consumed by shell helpers.

=head1 HOW TO USE

Call C<run_paths_command> with the public command name and argv list. The
module builds a lightweight path registry, loads configured aliases on demand,
and returns either JSON payloads or newline-delimited path output depending on
the selected subcommand. For C<dashboard path cdr>, the first argument is
treated as a saved alias when one exists; otherwise it becomes the first search
regex under the current directory. Any remaining narrowing terms are
case-insensitive regexes and all of them must match a candidate path. A single
match becomes the target directory; multiple matches are returned as a list
while the target stays at the alias root or current directory.

=head1 WHAT USES IT

It is used by the staged path helpers, by the shell bootstrap generated from
C<_dashboard-core>, and by tests that cover alias resolution, regex narrowing,
current-directory fallback, layered runtime lookup, and platform-portable shell
output.

=head1 EXAMPLES

  dashboard paths
  dashboard path resolve bookmarks
  dashboard path cdr project alpha ".*service"
  dashboard path add work ~/projects/work
  dashboard path list

=for comment FULL-POD-DOC END

=cut
