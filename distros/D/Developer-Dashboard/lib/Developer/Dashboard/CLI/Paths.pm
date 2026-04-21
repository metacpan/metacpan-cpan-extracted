package Developer::Dashboard::CLI::Paths;

use strict;
use warnings;

our $VERSION = '2.76';

use Cwd qw(cwd);
use File::Basename qw(basename);
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
        print json_encode( $paths->all_paths );
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
    if ( $action eq 'complete-cdr' ) {
        $load_configured_path_aliases->();
        my $index = shift @argv;
        $index = 0 if !defined $index || $index eq '';
        print join( "\n", _cdr_completion( paths => $paths, words => \@argv, index => $index ) ), "\n";
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
        print json_encode( $paths->all_path_aliases );
        return 1;
    }

    die "Usage: dashboard path <resolve|locate|cdr|complete-cdr|add|del|project-root|list> ...\n";
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

# _cdr_completion(%args)
# Returns shell-completion candidates for the cdr/dd_cdr/which_dir helpers.
# Input: hash containing a path registry under "paths", the raw shell words
# array reference under "words", and the active completion index under "index".
# Output: ordered list of candidate strings.
sub _cdr_completion {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $words = $args{words} || die "Missing completion words\n";
    my $index = defined $args{index} ? $args{index} : die "Missing completion index\n";
    die "cdr completion words must be an array reference\n" if ref($words) ne 'ARRAY';

    my @words = @{$words};
    return () if !@words;

    my $current = defined $words[$index] ? $words[$index] : '';
    my @args = @words > 1 ? @words[ 1 .. $#words ] : ();
    my $arg_index = $index - 1;

    if ( $arg_index <= 0 ) {
        return _cdr_initial_candidates(
            paths   => $paths,
            prefix  => $current,
            include => [ cwd() ],
        );
    }

    my $first = $args[0] // '';
    my $alias_target = eval { $paths->resolve_dir($first) };
    my $base_root = defined $alias_target && $alias_target ne '' ? $alias_target : cwd();
    my $filter_start = defined $alias_target && $alias_target ne '' ? 1 : 0;
    my @filters = @args >= $arg_index ? @args[ $filter_start .. ( $arg_index - 1 ) ] : ();

    return _cdr_directory_candidates(
        paths   => $paths,
        root    => $base_root,
        terms   => \@filters,
        prefix  => $current,
    );
}

# _cdr_initial_candidates(%args)
# Builds first-argument completion candidates for cdr-family shell helpers from
# saved aliases and directories beneath the current working directory.
# Input: hash containing the path registry under "paths", one current-token
# prefix under "prefix", and an array reference of roots under "include".
# Output: ordered list of alias or directory candidate strings.
sub _cdr_initial_candidates {
    my (%args) = @_;
    my $paths  = $args{paths}   || die "Missing paths registry\n";
    my $prefix = defined $args{prefix} ? $args{prefix} : '';
    my $roots  = $args{include} || [];
    die "cdr completion include roots must be an array reference\n" if ref($roots) ne 'ARRAY';

    my @candidates = grep { index( $_, $prefix ) == 0 } keys %{ $paths->named_paths || {} };
    push @candidates, _cdr_directory_candidates(
        paths  => $paths,
        root   => $_,
        terms  => [],
        prefix => $prefix,
    ) for grep { defined && $_ ne '' && -d $_ } @{$roots};

    my %seen;
    return sort grep { defined && $_ ne '' && !$seen{$_}++ } @candidates;
}

# _cdr_directory_candidates(%args)
# Builds unique directory-basename candidates beneath one root for cdr-family
# shell completion without exposing unreadable-subtree failures to the shell.
# Input: hash containing the path registry under "paths", one search root under
# "root", an array reference of already-accepted narrowing terms under "terms",
# and the current token prefix under "prefix".
# Output: ordered list of directory basename strings.
sub _cdr_directory_candidates {
    my (%args) = @_;
    my $paths  = $args{paths} || die "Missing paths registry\n";
    my $root   = $args{root}  || return ();
    my $terms  = $args{terms} || [];
    my $prefix = defined $args{prefix} ? $args{prefix} : '';
    die "cdr completion terms must be an array reference\n" if ref($terms) ne 'ARRAY';

    my @matches = $paths->locate_dirs_under( $root, @{$terms} );
    my %seen;
    my @candidates;
    for my $path (@matches) {
        next if !defined $path || $path eq '' || $path eq $root;
        my $name = basename($path);
        next if !defined $name || $name eq '';
        next if $prefix ne '' && index( $name, $prefix ) != 0;
        next if $seen{$name}++;
        push @candidates, $name;
    }

    return sort @candidates;
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

This module is the command runtime behind C<dashboard paths> and C<dashboard path ...>. It prints the active runtime roots, resolves named aliases, persists alias add/delete operations, computes the JSON payload used by shell helpers such as C<cdr> and C<which_dir>, and returns the live completion candidates used by the C<cdr> shell functions.

=head1 WHY IT EXISTS

It exists because path reporting and shell-navigation semantics should live in Perl, not in duplicated shell code. That keeps the layered runtime rules, alias loading, and regex-based directory narrowing consistent across bash, zsh, POSIX sh, and PowerShell.

=head1 WHEN TO USE

Use this file when changing the output of C<dashboard paths>, the behavior of C<dashboard path resolve/add/del/list/project-root>, the C<cdr> payload contract consumed by shell helpers, or the completion candidates exposed to C<cdr>, C<dd_cdr>, and C<which_dir>.

=head1 HOW TO USE

Call C<run_paths_command> with the public command name and argv list. The
module builds a lightweight path registry, loads configured aliases on demand,
and returns either JSON payloads or newline-delimited path output depending on
the selected subcommand. For C<dashboard path cdr>, the first argument is
treated as a saved alias when one exists; otherwise it becomes the first search
regex under the current directory. Any remaining narrowing terms are
case-insensitive regexes and all of them must match a candidate path. A single
match becomes the target directory; multiple matches are returned as a list
while the target stays at the alias root or current directory. For
C<dashboard path complete-cdr>, pass the shell completion index followed by the
raw shell words, for example C<cdr foobar alp>; the helper returns newline
delimited completion candidates for aliases or matching directory basenames.

=head1 WHAT USES IT

It is used by the staged path helpers, by the shell bootstrap generated from
C<_dashboard-core>, and by tests that cover alias resolution, regex narrowing,
current-directory fallback, layered runtime lookup, and platform-portable shell
output.

=head1 EXAMPLES

  dashboard paths
  dashboard path resolve bookmarks
  dashboard path cdr project alpha ".*service"
  dashboard path complete-cdr 2 cdr project alp
  dashboard path add work ~/projects/work
  dashboard path list

=for comment FULL-POD-DOC END

=cut
