package Developer::Dashboard::CLI::OpenFile;

use strict;
use warnings;

our $VERSION = '2.72';

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Cwd qw(cwd);
use Digest::MD5 qw(md5_hex);
use Exporter 'import';
use File::Find ();
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use JSON::XS qw(decode_json);
use LWP::UserAgent;
use URI::Escape qw(uri_escape_utf8);

use Developer::Dashboard::PathRegistry;

our @EXPORT_OK = qw(run_open_file_command build_path_registry);

# build_path_registry()
# Builds the lightweight path registry used by standalone CLI commands.
# Input: none.
# Output: Developer::Dashboard::PathRegistry instance.
sub build_path_registry {
    return Developer::Dashboard::PathRegistry->new(
        workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    );
}

# run_open_file_command(%args)
# Resolves and opens or prints matching files from a direct path, file:line reference, or search scope.
# Input: optional path registry object and mutable argv array reference.
# Output: exits after printing matches or execing the configured editor.
sub run_open_file_command {
    my (%args) = @_;
    my $paths = $args{paths} || build_path_registry();
    my @argv  = @{ $args{args} || [] };
    my $print = 0;
    my $line  = 0;
    my $editor = '';

    GetOptionsFromArray(
        \@argv,
        'print!'   => \$print,
        'line=i'   => \$line,
        'editor=s' => \$editor,
    );

    die "Usage: open-file [--print] [--line N] [--editor CMD] <file|scope> [pattern...]\n"
      if !@argv;

    my ( $line_override, @matches ) = _resolve_open_file_matches(
        paths => $paths,
        args  => \@argv,
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

# _default_editor($editor)
# Resolves the editor command used for interactive open-file execution.
# Input: optional explicit editor command string.
# Output: editor command string, defaulting to the user's editor or vim.
sub _default_editor {
    my ($editor) = @_;
    return $editor || $ENV{VISUAL} || $ENV{EDITOR} || 'vim';
}

# _editor_supports_tabs(%args)
# Detects whether the resolved editor command should receive the older vim tab-open switch.
# Input: command array reference where the first entry is the executable name.
# Output: true when the editor is one of the vim-family commands that support -p.
sub _editor_supports_tabs {
    my (%args) = @_;
    my $command = $args{command} || [];
    my $editor  = $command->[0] || '';
    return 0 if $editor eq '';
    $editor =~ s{.*[\\/]}{};
    return $editor =~ /\A(?:vim|nvim|vi|gvim|iv)\z/i ? 1 : 0;
}

# _select_open_file_matches(%args)
# Resolves the final open-file match list using the older numbered chooser flow.
# Input: hash containing an array reference of matched file path strings.
# Output: one or more selected file path strings, defaulting to all matches when no choice is entered.
sub _select_open_file_matches {
    my (%args) = @_;
    my $matches = $args{matches} || [];
    my @matches = _unique_matches(@$matches);

    return if !@matches;
    return @matches if @matches == 1;

    for my $index ( 0 .. $#matches ) {
        print( $index + 1, ": $matches[$index]\n" );
    }
    print '> ';

    my $selection = <STDIN>;
    return @matches if !defined $selection;

    chomp $selection;
    my @chosen = _selection_matches(
        choices => $selection,
        matches => \@matches,
    );

    return @chosen if @chosen;
    return @matches if $selection eq '';
    die "Invalid file selection '$selection'\n";
}

# _selection_matches(%args)
# Parses one older chooser string into the selected open-file matches.
# Input: choice string plus array reference of matched file path strings.
# Output: zero or more selected file path strings.
sub _selection_matches {
    my (%args) = @_;
    my $choices = defined $args{choices} ? $args{choices} : '';
    my $matches = $args{matches} || [];
    return @$matches if $choices eq '' && @$matches;

    if ( $choices =~ /^\d+(?:\s*-\s*\d+)?(?:[\s,]+\d+(?:\s*-\s*\d+)?)*$/ ) {
        my @chosen;
        for my $chunk ( grep { defined && $_ ne '' } split /[,\s]+/, $choices ) {
            if ( $chunk =~ /^(\d+)-(\d+)$/ ) {
                my ( $start, $end ) = ( $1, $2 );
                return if $start < 1 || $end < $start || $end > @$matches;
                push @chosen, @$matches[ $start - 1 .. $end - 1 ];
                next;
            }
            return if $chunk !~ /^\d+$/ || $chunk < 1 || $chunk > @$matches;
            push @chosen, $matches->[ $chunk - 1 ];
        }
        return @chosen;
    }

    return;
}

# _unique_matches(@matches)
# Deduplicates resolved open-file matches while preserving their original order.
# Input: list of matched file path strings.
# Output: ordered list of unique file path strings.
sub _unique_matches {
    my (@matches) = @_;
    my %seen;
    return grep { defined && $_ ne '' && !$seen{$_}++ } @matches;
}

# _ordered_scope_matches(%args)
# Orders recursive scope-search matches so exact helper/script names sort before broader substring matches.
# Input: pattern array reference plus discovered file path array reference.
# Output: ordered unique file path strings ranked by basename/stem relevance and original discovery order.
sub _ordered_scope_matches {
    my (%args) = @_;
    my @patterns = @{ $args{patterns} || [] };
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
            ),
            index => $index,
        };
    }

    return map { $_->{file} }
      sort {
             $a->{rank}  <=> $b->{rank}
          || $a->{index} <=> $b->{index}
      } @ranked;
}

# _scope_match_rank(%args)
# Scores one recursive scope-search file so exact basename hits outrank partial path matches.
# Input: file path string plus the active pattern array reference.
# Output: numeric rank where lower values are stronger matches.
sub _scope_match_rank {
    my (%args) = @_;
    my $file       = $args{file}       || '';
    my $match_path = $args{match_path} || $file;
    my @patterns   = @{ $args{patterns} || [] };
    my ($basename) = $match_path =~ m{([^/\\]+)$};
    $basename ||= $match_path;
    my $stem = $basename;
    $stem =~ s{\.[^.]+$}{};

    my $rank = 0;
    for my $pattern (@patterns) {
        next if !defined $pattern || $pattern eq '';
        my $regex = _compile_open_file_regex($pattern);
        my $score = 50;
        my @components = grep { defined && $_ ne '' } split m{[\\/]+}, $match_path;

        if ( $basename =~ /\A(?:$pattern)\z/i ) {
            $score = 0;
        }
        elsif ( $stem =~ /\A(?:$pattern)\z/i ) {
            $score = 1;
        }
        elsif ( $basename =~ /\A(?:$pattern)/i ) {
            $score = 2;
        }
        elsif ( $basename =~ $regex ) {
            $score = 3;
        }
        elsif ( grep { $_ =~ /\A(?:$pattern)\z/i } @components ) {
            $score = 4;
        }
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
    my $paths = $args{paths} || die 'Missing path registry';
    my @argv  = @{ $args{args} || [] };

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
        my @named_matches = _named_source_matches(
            paths => $paths,
            name  => $first,
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
    }
    else {
        $scope = $paths->current_project_root || cwd();
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
        entries  => \@entries,
    );
    return ( $line, @files );
}

# _named_source_matches(%args)
# Resolves Perl module names or Java class names to matching source files.
# Input: path registry object and logical package/class name string.
# Output: sorted list of matching file path strings.
sub _named_source_matches {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $name  = $args{name}  || return;

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
        scalar( $paths->current_project_root || () ),
        $paths->workspace_roots,
        $paths->project_roots,
        @INC,
    );

    my %seen;
    return grep { defined && $_ ne '' && -d $_ && !$seen{$_}++ } @roots;
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

# _java_archive_source_matches(%args)
# Resolves Java source files from local or downloaded source archives when no live .java file exists.
# Input: path registry object, root array reference, class name string, and relative Java source path string.
# Output: ordered list of extracted Java source file paths.
sub _java_archive_source_matches {
    my (%args) = @_;
    my $paths    = $args{paths}    || die 'Missing path registry';
    my $roots    = $args{roots}    || [];
    my $name     = $args{name}     || return;
    my $relative = $args{relative} || return;

    my @matches;
    for my $archive ( _candidate_java_source_archives( paths => $paths, roots => $roots ) ) {
        push @matches,
          _extract_java_sources_from_archive(
            paths    => $paths,
            archive  => $archive,
            relative => $relative,
          );
    }
    if ( !@matches ) {
        push @matches,
          _download_java_source_matches(
            paths    => $paths,
            name     => $name,
            relative => $relative,
          );
    }
    return _unique_matches(@matches);
}

# _candidate_java_source_archives(%args)
# Builds the ordered archive list used for Java source lookup outside direct filesystem source trees.
# Input: path registry object plus the root array reference already searched for plain files.
# Output: ordered list of candidate archive file paths.
sub _candidate_java_source_archives {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $roots = $args{roots} || [];
    my @archives;
    my %seen;

    for my $root ( _java_source_archive_roots( paths => $paths, roots => $roots ) ) {
        File::Find::find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return if !-f $_;
                    my $path = $File::Find::name;
                    return if $path !~ /(?:-sources\.jar|-src\.jar|src\.zip|source\.zip|\.war|\.jar)\z/i;
                    return if $seen{$path}++;
                    push @archives, $path;
                },
            },
            $root,
        );
    }

    return @archives;
}

# _java_source_archive_roots(%args)
# Returns the filesystem roots that can contain Java source archives for open-file lookup.
# Input: path registry object plus the current open-file roots array reference.
# Output: ordered list of existing directory path strings.
sub _java_source_archive_roots {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $roots = $args{roots} || [];
    my @candidates = (
        @$roots,
        File::Spec->catdir( $paths->home, '.m2', 'repository' ),
        File::Spec->catdir( $paths->home, '.gradle', 'caches' ),
        grep { defined && $_ ne '' } ( $ENV{JAVA_HOME}, $ENV{JDK_HOME} ),
    );

    my %seen;
    return grep { defined && $_ ne '' && -d $_ && !$seen{$_}++ } @candidates;
}

# _extract_java_sources_from_archive(%args)
# Extracts matching Java source members from one zip-like archive into the dashboard cache tree.
# Input: path registry object, archive file path string, and relative Java source path string.
# Output: ordered list of extracted source file path strings.
sub _extract_java_sources_from_archive {
    my (%args) = @_;
    my $paths    = $args{paths}    || die 'Missing path registry';
    my $archive  = $args{archive}  || return;
    my $relative = $args{relative} || return;
    my $zip      = Archive::Zip->new();
    return if $zip->read($archive) != AZ_OK;

    my @matches;
    for my $entry ( _matching_java_archive_entries( zip => $zip, relative => $relative ) ) {
        my $member = $zip->memberNamed($entry) || next;
        my $target = _cached_archive_source_path(
            paths   => $paths,
            archive => $archive,
            entry   => $entry,
        );
        my ( $volume, $directories ) = File::Spec->splitpath($target);
        make_path( File::Spec->catpath( $volume, $directories, '' ) );
        open my $fh, '>', $target or die "Unable to write $target: $!";
        print {$fh} $member->contents;
        close $fh;
        push @matches, $target;
    }

    return @matches;
}

# _matching_java_archive_entries(%args)
# Finds archive member names whose trailing path matches one requested Java source path.
# Input: Archive::Zip object and relative Java source path string.
# Output: ordered list of matching archive member path strings.
sub _matching_java_archive_entries {
    my (%args) = @_;
    my $zip      = $args{zip}      || return;
    my $relative = $args{relative} || return;
    my $suffix   = $relative;
    $suffix =~ s{\\}{/}g;

    my @entries;
    for my $member ( $zip->members ) {
        my $name = $member->fileName || next;
        next if $name !~ /(?:\A|\/)\Q$suffix\E\z/;
        push @entries, $name;
    }

    return @entries;
}

# _cached_archive_source_path(%args)
# Builds the stable cache location used for one extracted Java source member.
# Input: path registry object, archive file path string, and archive member path string.
# Output: extracted source file path string.
sub _cached_archive_source_path {
    my (%args) = @_;
    my $paths   = $args{paths}   || die 'Missing path registry';
    my $archive = $args{archive} || die 'Missing archive path';
    my $entry   = $args{entry}   || die 'Missing archive entry';
    my $digest  = md5_hex( join "\0", $archive, $entry );
    my @parts   = grep { defined && $_ ne '' } split m{/+}, $entry;

    return File::Spec->catfile(
        $paths->cache_root,
        'open-file',
        'java-sources',
        $digest,
        @parts,
    );
}

# _download_java_source_matches(%args)
# Downloads Maven source jars when local archive lookup cannot satisfy the requested Java class.
# Input: path registry object, fully qualified class name string, and relative Java source path string.
# Output: ordered list of extracted Java source file path strings.
sub _download_java_source_matches {
    my (%args) = @_;
    my $paths    = $args{paths}    || die 'Missing path registry';
    my $name     = $args{name}     || return;
    my $relative = $args{relative} || return;

    my @matches;
    for my $doc ( _maven_search_documents($name) ) {
        next if ref($doc) ne 'HASH';
        next if !grep { defined && $_ eq '-sources.jar' } @{ $doc->{ec} || [] };
        my $archive = _download_maven_source_jar( paths => $paths, doc => $doc ) or next;
        push @matches,
          _extract_java_sources_from_archive(
            paths    => $paths,
            archive  => $archive,
            relative => $relative,
          );
        last if @matches;
    }

    return @matches;
}

# _maven_search_documents($name)
# Queries Maven Central for one fully qualified Java class name.
# Input: fully qualified Java class name string.
# Output: ordered list of Maven search document hash references.
sub _maven_search_documents {
    my ($name) = @_;
    return if !defined $name || $name eq '';

    my $query = uri_escape_utf8(qq{fc:"$name"});
    my $url   = "https://search.maven.org/solrsearch/select?q=$query&rows=20&wt=json";
    my $ua    = LWP::UserAgent->new( timeout => 10 );
    my $res   = $ua->get($url);
    return if !$res->is_success;

    my $payload = eval { decode_json( $res->decoded_content ) };
    return if !$payload || ref($payload) ne 'HASH';
    return @{ $payload->{response}{docs} || [] };
}

# _download_maven_source_jar(%args)
# Downloads one Maven Central source jar into the dashboard cache tree when it is missing.
# Input: path registry object and one Maven search document hash reference.
# Output: local source-jar path string or undef on failure.
sub _download_maven_source_jar {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $doc   = $args{doc}   || return;
    return if ref($doc) ne 'HASH';
    return if !defined $doc->{g} || !defined $doc->{a} || !defined $doc->{v};

    my $group_path = join '/', split /\./, $doc->{g};
    my $file       = "$doc->{a}-$doc->{v}-sources.jar";
    my $target     = File::Spec->catfile(
        $paths->cache_root,
        'open-file',
        'maven-sources',
        split( /\//, $group_path ),
        $doc->{a},
        $doc->{v},
        $file,
    );
    return $target if -f $target;

    my ( $volume, $directories ) = File::Spec->splitpath($target);
    make_path( File::Spec->catpath( $volume, $directories, '' ) );

    my $url = join '/',
      'https://repo1.maven.org/maven2',
      $group_path,
      $doc->{a},
      $doc->{v},
      $file;
    my $ua  = LWP::UserAgent->new( timeout => 20 );
    my $res = $ua->mirror( $url, $target );
    return if !$res->is_success && $res->code != 304;
    return -f $target ? $target : undef;
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
# Input: shell command array.
# Output: never returns during normal command execution.
sub _command_exec {
    my (@command) = @_;
    exec { $command[0] } @command;
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
or use the lower-level lookup routines from tests. Direct file paths and
C<file:line> targets are handled immediately. Scoped lookup mode treats the
first non-option argument as the search root or saved alias and every remaining
argument as a case-insensitive regex that must match the candidate path. A
single hit opens or prints that file, while multiple hits are ranked and shown
as a chooser or plain list. Perl module lookup maps C<Foo::Bar> to
C<Foo/Bar.pm>; Java lookup maps dotted class names to C<.java> source files,
source archives, or cached Maven source jars before the helper decides whether
to print the path or exec the configured editor.

=head1 WHAT USES IT

It is used by the private C<of> and C<open-file> helper scripts, by shell
users who want repo-local open-file behavior, and by the CLI coverage tests
that exercise direct-path, regex, Perl-module, Java-source, ranking, and
print-vs-editor flows.

=head1 EXAMPLES

  dashboard open-file path/to/file.txt
  dashboard open-file lib 'OpenFile\.pm$'
  dashboard of . "Ok\.js$"
  dashboard open-file javax.jws.WebService
  dashboard of Developer::Dashboard::CLI::Paths
  dashboard open-file --print bookmarks api-dashboard

=for comment FULL-POD-DOC END

=cut
