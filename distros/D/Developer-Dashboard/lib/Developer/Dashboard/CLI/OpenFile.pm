package Developer::Dashboard::CLI::OpenFile;

use strict;
use warnings;

our $VERSION = '4.45';

use Cwd qw(cwd);
use Exporter 'import';
use File::Find ();
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);

use Developer::Dashboard::CLI::OpenFileChooser qw(_default_editor _editor_supports_tabs _select_open_file_matches _stdin_has_pending_input _selection_matches);
use Developer::Dashboard::CLI::OpenFileJavaSource qw(
    _java_archive_source_matches
    _candidate_java_source_archives
    _java_source_archive_roots
    _extract_java_sources_from_archive
    _matching_java_archive_entries
    _contained_cache_path
    _cached_archive_source_path
    _download_java_source_matches
    _maven_search_documents
    _download_maven_source_jar
);
use Developer::Dashboard::CLI::OpenFileUtil qw(_unique_matches _unique_existing_dirs);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

our @EXPORT_OK = qw(run_open_file_command build_path_registry _unique_matches _unique_existing_dirs);

# build_path_registry()
# Builds the lightweight path registry used by standalone CLI commands.
# Input: none.
# Output: Developer::Dashboard::PathRegistry instance.
sub build_path_registry {
    return Developer::Dashboard::PathRegistry->new(
        workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],    # uncoverable branch false the interpolated map above always yields a defined string
        project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],    # uncoverable branch false the interpolated map above always yields a defined string
    );
}

# run_open_file_command(%args)
# Resolves and opens or prints matching files from a direct path, file:line reference, or search scope.
# Input: optional path registry object and mutable argv array reference.
# Output: exits after printing matches or execing the configured editor.
sub run_open_file_command {
    my (%args) = @_;
    my $paths = $args{paths} || build_path_registry();    # uncoverable condition false build_path_registry always returns a blessed registry object
    my @argv  = @{ $args{args} || [] };
    my $print  = 0;
    my $line   = 0;
    my $editor = '';
    my $online = 0;

    my $options_ok = GetOptionsFromArray(
        \@argv,
        'print!'   => \$print,
        'line=i'   => \$line,
        'editor=s' => \$editor,
        'online!'  => \$online,
    );

    die "Usage: open-file [--print] [--line N] [--editor CMD] [--online] <file|scope> [pattern...]\n"
      if !$options_ok;

    die "Usage: open-file [--print] [--line N] [--editor CMD] [--online] <file|scope> [pattern...]\n"
      if !@argv;

    my ( $line_override, @matches ) = _resolve_open_file_matches(
        paths  => $paths,
        args   => \@argv,
        online => $online,
    );
    $line ||= $line_override || 0;

    die "No files found\n" if !@matches;

    if ($print) {
        print join( "\n", @matches ), "\n";
        _command_exit(0);
    }

    @matches = _select_open_file_matches( matches => \@matches );

    my $editor_cmd = _default_editor($editor);
    my @command = split /\s+/, $editor_cmd;
    push @command, '-p' if _editor_supports_tabs( command => \@command );
    push @command, "+$line" if $line;
    push @command, @matches;
    _command_exec(@command);
}

# _ordered_scope_matches(%args)
# Orders recursive scope-search matches so exact helper/script names sort before broader substring matches.
# Input: pattern array reference, optional pre-compiled regex array reference (DD-912 - same order as
# patterns, so a caller that already compiled its patterns once does not pay to recompile them once per
# candidate file), plus discovered file path array reference.
# Output: ordered unique file path strings ranked by basename/stem relevance and original discovery order.
sub _ordered_scope_matches {
    my (%args) = @_;
    my @patterns = @{ $args{patterns} || [] };
    my @regexes  = @{ $args{regexes} || [] };
    my @entries  = @{ $args{entries} || [] };
    @entries = map { { file => $_, match_path => $_ } } _unique_matches( @{ $args{files} || [] } )
      if !@entries;

    my @ranked;
    for my $index ( 0 .. $#entries ) {
        push @ranked, {
            file  => $entries[$index]{file},
            rank  => _scope_match_rank(
                file      => $entries[$index]{file},
                match_path => $entries[$index]{match_path},
                patterns => \@patterns,
                regexes  => \@regexes,
            ),
            index => $index,
        };
    }

    return map { $_->{file} }
      sort {
             $a->{rank}  <=> $b->{rank}
          || $a->{index} <=> $b->{index}
      } @ranked;    # uncoverable branch true : entries carry unique indexes, so this tiebreaker is never 0 and the comparator never returns 0
}

# _resolved_scope_match_regex($regexes, $index, $pattern)
# Resolves the regex for one scope-match ranking pattern: the caller's pre-compiled
# regex at this index if one was supplied (DD-912), otherwise compiles the pattern
# itself so direct callers (tests, or any caller with only raw pattern strings) keep
# working unchanged.
# Input: pre-compiled regex array reference, pattern index, and the pattern string.
# Output: compiled regex object.
sub _resolved_scope_match_regex {
    my ( $regexes, $index, $pattern ) = @_;
    # uncoverable condition false _compile_open_file_regex only returns undef for an undef/empty pattern, already excluded by _scope_match_rank before this is called
    return $regexes->[$index] || _compile_open_file_regex($pattern);
}

# _scope_match_rank(%args)
# Scores one recursive scope-search file so exact basename hits outrank partial path matches.
# Input: file path string, the active pattern array reference, and an optional pre-compiled regex array
# reference (DD-912) in the same order as patterns - when the regex at a given index is missing, this
# compiles that one pattern itself so direct callers (tests, or any caller with only raw pattern strings)
# keep working unchanged.
# Output: numeric rank where lower values are stronger matches.
sub _scope_match_rank {
    my (%args) = @_;
    my $file       = $args{file}       || '';
    my $match_path = $args{match_path} || $file;
    my @patterns   = @{ $args{patterns} || [] };
    my @regexes    = @{ $args{regexes} || [] };
    my ($basename) = $match_path =~ m{([^/\\]+)$};
    $basename ||= $match_path;
    my $stem = $basename;
    $stem =~ s{\.[^.]+$}{};

    my $rank = 0;
    for my $index ( 0 .. $#patterns ) {
        my $pattern = $patterns[$index];
        next if !defined $pattern || $pattern eq '';
        my $regex;    # DD-917: resolved lazily below, only if a cheaper check does not already decide the score
        my $score = 50;
        my @components = grep { $_ ne '' } split m{[\\/]+}, $match_path;

        if ( $basename =~ /\A(?:$pattern)\z/i ) {
            $score = 0;
        }
        elsif ( $stem =~ /\A(?:$pattern)\z/i ) {
            $score = 1;
        }
        elsif ( $basename =~ /\A(?:$pattern)/i ) {
            $score = 2;
        }
        elsif (
            do {
                # uncoverable condition left (DD-917) $regex is freshly declared undef on every loop iteration and nothing sets it before this point, so the already-resolved side of ||= is never taken
                # uncoverable condition false (DD-917) _resolved_scope_match_regex never returns a falsy value, so $regex is never falsy after this line
                $regex ||= _resolved_scope_match_regex( \@regexes, $index, $pattern );
                $basename =~ $regex;
            }
          )
        {
            $score = 3;
        }
        elsif ( grep { $_ =~ /\A(?:$pattern)\z/i } @components ) {
            $score = 4;
        }

        # $regex is always already resolved by the elsif above by the time this branch is
        # reached - the if/elsif chain visits that branch first on every path that reaches
        # this one, so there is no remaining case where $regex could still be undef here.
        elsif ( $match_path =~ $regex ) {
            $score = 5;
        }

        $rank += $score;
    }

    return $rank;
}

# _resolve_open_file_matches(%args)
# Resolves direct file targets or recursive search matches for the open-file command.
# Input: path registry object and argv array reference.
# Output: list containing optional line number and matched file path strings.
sub _resolve_open_file_matches {
    my (%args) = @_;
    my $paths  = $args{paths} || die 'Missing path registry';
    my @argv   = @{ $args{args} || [] };
    my $online = $args{online} || 0;
    my ( $files, $config ) = _open_file_registries( paths => $paths );

    my $first = shift @argv;
    my $line  = 0;

    if ( defined $first && $first =~ /^(.+):(\d+)(?::\d+)?$/ ) {
        my ( $file, $parsed_line ) = ( $1, $2 );
        if ( -f $file ) {
            return ( $parsed_line, $file );
        }
    }

    if ( defined $first && -f $first ) {
        return ( $line, $first );
    }

    if ( defined $first ) {
        my $resolved_file = eval { $files->resolve_file($first) };
        return ( $line, $resolved_file ) if defined $resolved_file && -f $resolved_file;
    }

    if ( defined $first ) {
        my @named_matches = _named_source_matches(
            paths  => $paths,
            name   => $first,
            online => $online,
        );
        return ( $line, @named_matches ) if @named_matches;
    }

    my $scope;
    my @patterns;

    if ( defined $first ) {
        $scope = eval { $paths->resolve_dir($first) };
        $scope = $first if !$scope && -d $first;
    }

    if ( $scope && -d $scope ) {
        @patterns = @argv;
        my $relative_match = _scope_relative_path_match(
            scope   => $scope,
            pattern => \@patterns,
        );
        return ( $line, $relative_match ) if defined $relative_match;
    }
    else {
        $scope = $paths->current_project_root || cwd();    # uncoverable condition false cwd never returns an empty value on the test host
        @patterns = grep { defined && $_ ne '' } ( $first, @argv );
    }

    my @entries;
    my @regexes = map { _compile_open_file_regex($_) } @patterns;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if !-f $_;
                my $path = $File::Find::name;
                my $relative = File::Spec->abs2rel( $path, $scope );
                $relative =~ s{\A\.[/\\]}{};
                for my $regex (@regexes) {
                    return if $relative !~ $regex;
                }
                push @entries, {
                    file       => $path,
                    match_path => $relative,
                };
            },
        },
        $scope,
    );

    my @files = _ordered_scope_matches(
        patterns => \@patterns,
        regexes  => \@regexes,
        entries  => \@entries,
    );
    return ( $line, @files );
}

# _open_file_registries(%args)
# Builds the config-backed path and file registries used by the open-file command.
# Input: hash containing the active path registry under "paths".
# Output: file registry object plus config object with configured aliases loaded.
sub _open_file_registries {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    $paths->register_named_paths( $config->path_aliases );
    $files->register_named_files( $config->file_aliases );
    return ( $files, $config );
}

# _scope_relative_path_match(%args)
# Resolves an exact relative file path inside one search scope before regex fallback search.
# Input: scope directory path and pattern array reference representing one relative path.
# Output: exact file path string or undef when the pattern list is not one existing relative file.
sub _scope_relative_path_match {
    my (%args) = @_;
    my $scope    = $args{scope}   || return;
    my @patterns = @{ $args{pattern} || [] };
    return if !@patterns;
    return if grep { !defined $_ || $_ eq '' } @patterns;

    my $relative = File::Spec->catfile(@patterns);
    my $target   = File::Spec->catfile( $scope, $relative );
    return -f $target ? $target : undef;
}

# _named_source_matches(%args)
# Resolves Perl module names or Java class names to matching source files.
# Input: path registry object and logical package/class name string.
# Output: sorted list of matching file path strings.
sub _named_source_matches {
    my (%args) = @_;
    my $paths  = $args{paths} || die 'Missing path registry';
    my $name   = $args{name}  || return;
    my $online = $args{online} || 0;

    my @roots = _open_file_roots( paths => $paths );
    my @matches;

    if ( $name =~ /::/ ) {
        my $relative = File::Spec->catfile( split /::/, $name ) . '.pm';
        @matches = _existing_named_files( roots => \@roots, relative => $relative );
    }
    elsif ( $name =~ /^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+$/ ) {
        my $relative = File::Spec->catfile( split /\./, $name ) . '.java';
        @matches = _existing_named_files(
            roots    => \@roots,
            relative => $relative,
            prefixes => [
                '',
                File::Spec->catdir('src'),
                File::Spec->catdir( 'src', 'main', 'java' ),
                File::Spec->catdir( 'src', 'test', 'java' ),
            ],
        );
        push @matches,
          _java_archive_source_matches(
            paths    => $paths,
            roots    => \@roots,
            name     => $name,
            relative => $relative,
            online   => $online,
          );
    }

    return _unique_matches(@matches);
}


# _open_file_roots(%args)
# Builds the ordered root list used for module/class source resolution.
# Input: path registry object.
# Output: sorted list of unique directory path strings.
sub _open_file_roots {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my @roots = (
        cwd(),
        scalar( $paths->current_project_root ),
        $paths->workspace_roots,
        $paths->project_roots,
        @INC,
    );

    return _unique_existing_dirs(@roots);
}

# _existing_named_files(%args)
# Resolves a relative source path below a set of candidate roots.
# Input: array reference of roots, relative file path string, and optional prefixes array reference.
# Output: sorted list of existing file path strings.
sub _existing_named_files {
    my (%args) = @_;
    my $roots    = $args{roots} || [];
    my $relative = $args{relative} || return;
    my $prefixes = $args{prefixes} || [''];
    my @found;
    my %seen;

    for my $root (@$roots) {
        for my $prefix (@$prefixes) {
            my $file = $prefix eq ''
              ? File::Spec->catfile( $root, $relative )
              : File::Spec->catfile( $root, $prefix, $relative );
            next if !-f $file || $seen{$file}++;
            push @found, $file;
        }
    }

    return sort @found;
}

# _compile_open_file_regex($pattern)
# Compiles one user-supplied open-file token as the regex matcher used by the command.
# Input: one search token string.
# Output: compiled regex object, or dies when the token is not a valid regex.
sub _compile_open_file_regex {
    my ($pattern) = @_;
    return if !defined $pattern || $pattern eq '';
    my $regex = eval { qr/$pattern/i };
    die "Invalid regex '$pattern': $@\n" if !$regex;
    return $regex;
}


# _command_exit($code)
# Wraps process exit so tests can override it and exercise command flow in-process.
# Input: integer process exit code.
# Output: never returns during normal command execution.
sub _command_exit {
    my ($code) = @_;
    exit $code;
}

# _command_exec(@command)
# Wraps process exec so tests can override it and inspect the final editor command.
# A failed exec() returns false rather than dying, so without this check a
# missing or unexecutable editor binary would fall through silently and the
# whole command would exit 0 as though the editor had actually run (DD-910).
# Input: shell command array.
# Output: never returns during normal command execution.
sub _command_exec {
    my (@command) = @_;
    exec { $command[0] } @command;

    # Reached only when exec() fails to replace the process image, and
    # proven reachable by t/98-cli-openfile-coverage.t's own passing
    # assertion - but the exec() op boundary is structurally invisible to
    # this coverage instrument, matching the documented fork/exec pattern
    # already annotated the same way in PaxCache.pm.
    die "Unable to run editor '$command[0]': $!\n";    # uncoverable statement
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFile - dashboard open-file command support

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFile qw(run_open_file_command);
  run_open_file_command( args => \@ARGV );

=head1 DESCRIPTION

Provides the shared implementation behind the built-in C<dashboard of> and
C<dashboard open-file> command paths.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module implements the search and resolution logic behind C<dashboard of> and C<dashboard open-file>. It can open direct paths, search within scopes, resolve Perl module names, resolve Java dotted class names through source trees and source archives, and rank file matches before opening or printing them.

=head1 WHY IT EXISTS

It exists because open-file behavior is much richer than a one-line shell wrapper. The dashboard needs one tested place that owns regex matching, module lookup, archive inspection, editor command selection, and the fallback rules between direct paths and scoped search.

=head1 WHEN TO USE

Use this file when changing regex matching, how Java source is found, how Perl modules are mapped to files, how multiple matches are ranked, or how the helper chooses between printing and launching an editor.

=head1 HOW TO USE

Call C<run_open_file_command> with the raw argv array from the helper command,
or use the lower-level lookup routines from tests. Direct file paths,
configured file aliases, and C<file:line> targets are handled immediately.
Scoped lookup mode treats the first non-option argument as the search root or
saved alias and every remaining argument as a case-insensitive regex that must
match the candidate path, except when those remaining arguments join into one
existing relative file path inside the resolved scope. In that exact-file case,
the helper opens the scoped file directly instead of falling back to regex
search. A single hit opens or prints that file, while multiple hits are ranked
and shown as a chooser or plain list. Perl module lookup maps C<Foo::Bar> to
C<Foo/Bar.pm>; Java lookup maps dotted class names to C<.java> source files or
local source archives entirely offline. When neither is found, the helper
prints a notice and stops rather than reaching the network - pass C<--online>
to let it fall through to a Maven Central search and download a source jar
into the dashboard cache (DD-914) before deciding whether to print the path
or exec the configured editor.

=head1 WHAT USES IT

It is used by the private C<of> and C<open-file> helper scripts, by shell
users who want repo-local open-file behavior, and by the CLI coverage tests
that exercise direct-path, regex, Perl-module, Java-source, ranking, and
print-vs-editor flows.

=head1 EXAMPLES

  dashboard open-file path/to/file.txt
  dashboard open-file lib 'OpenFile\.pm$'
  dashboard of notes
  dashboard of foobar 456.txt
  dashboard of . "Ok\.js$"
  dashboard open-file javax.jws.WebService
  dashboard open-file --online javax.jws.WebService
  dashboard of Developer::Dashboard::CLI::Paths
  dashboard open-file --print bookmarks index

=for comment FULL-POD-DOC END

=cut
