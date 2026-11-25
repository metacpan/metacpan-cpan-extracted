package Developer::Dashboard::CLI::OpenFileGrep;

use strict;
use warnings;

our $VERSION = '6.31';

use Capture::Tiny qw(capture);
use Developer::Dashboard::Platform qw(command_in_path is_real_windows);
use Exporter 'import';
use File::Spec;

our @EXPORT_OK = qw(grep_matching_files native_grep_usage);

# grep_matching_files(%args)
# Runs grep with the caller's argument vector and extracts unique matching
# paths from its line-numbered output.
# Input: hash containing an array reference of grep arguments (excluding argv[0]).
# Output: ordered list of matching file path strings; no-match returns an empty list.
sub grep_matching_files {
    my (%args) = @_;
    my $argv = $args{args} || [];
    die 'grep args must be an array reference' if ref($argv) ne 'ARRAY';
    die "Usage: d2 of grep <grep-options> <pattern> <path...>\n" if !@$argv;

    # -H and -n make grep output parseable even when searching one file or when
    # the caller omitted line numbers. Keeping all supplied arguments separate
    # also prevents shell interpretation of a pattern or path.
    my ( $stdout, $stderr, $exit_code ) = capture {
        my $status = system 'grep', '-H', '-n', @$argv;
        return $status == -1 ? -1 : ( $status >> 8 );
    };

    die "Unable to execute grep: $!\n" if $exit_code < 0;
    if ( $exit_code > 1 ) {
        print STDERR $stderr if defined $stderr && $stderr ne '';
        die "grep failed with exit code $exit_code\n";
    }

    # Exit 1 is ambiguous on real Windows when grep does not resolve:
    # Perl's system() falls back to cmd.exe, which reports the missing
    # binary with exit 1 - the same code grep uses for "no matches" - so
    # the code above returns an empty list and the caller reports "No
    # files found" for a search that never ran (t/05 tests 683-685).
    # On Unix a failed spawn returns -1 and is already reported
    # explicitly above, so Unix behaviour is unchanged. When the exit
    # code is the ambiguous 1 and grep does not resolve on this Windows
    # box, settle it with the Perl-native search below: matches mean
    # grep was missing, no matches mean the search genuinely found
    # nothing. System grep is untouched everywhere it resolves.
    if ( $exit_code == 1 && is_real_windows() && !command_in_path('grep') ) {
        $stdout = _native_grep_output($argv);
        $exit_code = $stdout ne '' ? 0 : 1;
    }
    return if $exit_code == 1;

    my @files;
    my %seen;
    for my $line ( split /\n/, $stdout ) {
        my $file;
        while ( $line =~ /:(\d+):/g ) {
            my $candidate = substr( $line, 0, $-[0] );
            if ( -f $candidate ) {
                $file = $candidate;
                last;
            }
        }
        die "Unable to identify file in grep output: $line\n" if !defined $file;
        push @files, $file if !$seen{$file}++;
    }

    return @files;
}

# native_grep_usage()
# Usage text for the built-in content search, shown when `d2 of grep --help`
# runs on a box with no system grep installed (plain Windows). It lists
# exactly the options _parse_native_grep_args honours, in the same wording
# as the HOW TO USE section below, so the text stays honest about what the
# built-in search can do; with a system grep present the caller execs grep
# unchanged and this text is never shown.
# Input: none.
# Output: the usage string, starting with "Usage: grep", ending with a newline.
sub native_grep_usage {
    return <<'USAGE';
Usage: grep [OPTION]... PATTERN [FILE]...
Search for PATTERN in each FILE, printing file:line:content for matches.
No system grep is installed on this machine, so the dashboard's built-in
search runs instead. It honours -r/-R, -i, -v, -w, -x, -F, -E, -e, -n,
-H, -s, -q, -a, -I, -d and their long forms; any other option is reported
as unsupported rather than searched with the wrong meaning.
USAGE
}

# _native_grep_output($argv)
# Perl-native equivalent of `grep -H -n @$argv`, used only to disambiguate
# the exit-1 case on real Windows when grep does not resolve (see
# grep_matching_files). It produces output lines in exactly the
# "file:line:content" shape the shared parser above expects, so a native
# result flows through the same decoding as a system-grep result. With
# -q the lines are suppressed and the empty string is returned even when
# matches exist, matching what system grep -q feeds the same parser.
# Input: grep argument array reference.
# Output: matching lines joined by "\n" with a trailing newline, or the
# empty string when nothing matches. Dies with a "grep failed: ..." message
# for an unsupported option, an invalid pattern, or any file error
# (missing path, unreadable file, directory without -r) - the same failure
# class system grep reports with exit 2, which the caller turns into a
# "grep failed with exit code 2" die. File errors dominate matches, as
# with system grep: the search runs to completion and the first error is
# reported even when other files matched.
sub _native_grep_output {
    my ($argv) = @_;
    my $spec = _parse_native_grep_args($argv);
    my @lines;
    if ( !@{ $spec->{paths} } ) {
        push @lines, _native_grep_handle( $spec, \*STDIN, '(standard input)' );
    }
    else {
        for my $path ( @{ $spec->{paths} } ) {
            push @lines, _native_grep_path( $spec, $path );
        }
    }
    die "$spec->{errors}[0]" if @{ $spec->{errors} };
    return @lines ? join( "\n", @lines ) . "\n" : '';
}

# _parse_native_grep_args($argv)
# Parses one grep argument vector into the native search specification.
# Options come first (bundled short options and long options, with or
# without "=value"); the first operand is the pattern unless -e/--regexp
# supplied one, and the remaining operands are paths. The pattern is a
# Perl regex, as the product passes it straight through; -F quotes it.
# Input: grep argument array reference.
# Output: hash reference with the search flags, the compiled regex, the
# path list, and an empty error list. Dies with a "grep failed: ..."
# message naming the offending option for any flag the native search
# cannot honour, for a missing option value, for no pattern, or for an
# invalid pattern - never silently mis-searching.
sub _parse_native_grep_args {
    my ($argv) = @_;
    my $spec = {
        directories      => undef,
        recursive_follow => 0,
        ignore_case      => 0,
        invert           => 0,
        word             => 0,
        line_regexp      => 0,
        fixed            => 0,
        quiet            => 0,
        text             => 0,
        patterns         => [],
        paths            => [],
        errors           => [],
    };
    my @args = @$argv;
    my $i = 0;
    my $positional_pattern_seen = 0;
    my $no_more_options         = 0;
    while ( $i < @args ) {
        my $arg = $args[$i];
        if ( !$no_more_options && $arg eq '--' ) {
            $no_more_options = 1;
            $i++;
            next;
        }
        if ( !$no_more_options && !$positional_pattern_seen && substr( $arg, 0, 2 ) eq '--' ) {
            my ( $name, $value );
            if ( $arg =~ /\A--([A-Za-z][A-Za-z0-9_-]*)(?:=(.*))?\z/s ) {
                ( $name, $value ) = ( $1, $2 );
            }
            else {
                die "grep failed: unsupported grep option '$arg' for the native content search\n";
            }
            my $has_value = defined $value;
            if ( $name eq 'regexp' ) {
                die "grep failed: option '--regexp' requires a pattern\n" if !$has_value && $i + 1 >= @args;
                push @{ $spec->{patterns} }, $has_value ? $value : $args[ ++$i ];
            }
            elsif ( $name eq 'directories' ) {
                die "grep failed: option '--directories' requires a value\n" if !$has_value && $i + 1 >= @args;
                _native_grep_set_directories( $spec, $has_value ? $value : $args[ ++$i ] );
            }
            elsif ( $name eq 'binary-files' ) {
                die "grep failed: option '--binary-files' requires a value\n" if !$has_value && $i + 1 >= @args;
                my $mode = $has_value ? $value : $args[ ++$i ];
                $spec->{text} = 1 if $mode eq 'text';
                die "grep failed: unsupported --binary-files mode '$mode'\n"
                  if $mode ne 'text' && $mode ne 'binary' && $mode ne 'without-match';
            }
            elsif ( $name eq 'recursive' ) {
                die "grep failed: option '--recursive' does not take a value\n" if $has_value;
                $spec->{directories}      = 'recurse';
                $spec->{recursive_follow} = 0;
            }
            elsif ( $name eq 'ignore-case' ) {
                die "grep failed: option '--ignore-case' does not take a value\n" if $has_value;
                $spec->{ignore_case} = 1;
            }
            elsif ( $name eq 'invert-match' ) {
                die "grep failed: option '--invert-match' does not take a value\n" if $has_value;
                $spec->{invert} = 1;
            }
            elsif ( $name eq 'word-regexp' ) {
                die "grep failed: option '--word-regexp' does not take a value\n" if $has_value;
                $spec->{word} = 1;
            }
            elsif ( $name eq 'line-regexp' ) {
                die "grep failed: option '--line-regexp' does not take a value\n" if $has_value;
                $spec->{line_regexp} = 1;
            }
            elsif ( $name eq 'fixed-strings' ) {
                die "grep failed: option '--fixed-strings' does not take a value\n" if $has_value;
                $spec->{fixed} = 1;
            }
            elsif ( $name eq 'extended-regexp' ) {
                die "grep failed: option '--extended-regexp' does not take a value\n" if $has_value;
            }
            elsif ( $name eq 'line-number' || $name eq 'with-filename' ) {
                die "grep failed: option '--$name' does not take a value\n" if $has_value;
            }
            elsif ( $name eq 'no-messages' ) {
                die "grep failed: option '--no-messages' does not take a value\n" if $has_value;
            }
            elsif ( $name eq 'quiet' || $name eq 'silent' ) {
                die "grep failed: option '--$name' does not take a value\n" if $has_value;
                $spec->{quiet} = 1;
            }
            elsif ( $name eq 'text' ) {
                die "grep failed: option '--text' does not take a value\n" if $has_value;
                $spec->{text} = 1;
            }
            else {
                die "grep failed: unsupported grep option '--$name' for the native content search\n";
            }
            $i++;
            next;
        }
        if ( !$no_more_options && !$positional_pattern_seen && $arg =~ /\A-([A-Za-z]+)\z/ ) {
            my @chars = split //, $1;
            my $j = 0;
            while ( $j < @chars ) {
                my $c = $chars[$j];
                if ( $c eq 'e' ) {
                    my $rest = join '', @chars[ $j + 1 .. $#chars ];
                    if ( $rest ne '' ) {
                        push @{ $spec->{patterns} }, $rest;
                    }
                    else {
                        $i++;
                        die "grep failed: option '-e' requires a pattern\n" if $i >= @args;
                        push @{ $spec->{patterns} }, $args[$i];
                    }
                    $j = @chars;
                }
                elsif ( $c eq 'd' ) {
                    my $rest = join '', @chars[ $j + 1 .. $#chars ];
                    if ( $rest ne '' ) {
                        _native_grep_set_directories( $spec, $rest );
                    }
                    else {
                        $i++;
                        die "grep failed: option '-d' requires a value\n" if $i >= @args;
                        _native_grep_set_directories( $spec, $args[$i] );
                    }
                    $j = @chars;
                }
                elsif ( $c eq 'r' ) {
                    $spec->{directories}      = 'recurse';
                    $spec->{recursive_follow} = 0;
                    $j++;
                }
                elsif ( $c eq 'R' ) {
                    $spec->{directories}      = 'recurse';
                    $spec->{recursive_follow} = 1;
                    $j++;
                }
                elsif ( $c eq 'i' ) { $spec->{ignore_case} = 1; $j++; }
                elsif ( $c eq 'v' ) { $spec->{invert}      = 1; $j++; }
                elsif ( $c eq 'w' ) { $spec->{word}        = 1; $j++; }
                elsif ( $c eq 'x' ) { $spec->{line_regexp} = 1; $j++; }
                elsif ( $c eq 'F' ) { $spec->{fixed}       = 1; $j++; }
                elsif ( $c eq 'E' ) { $j++; }
                elsif ( $c eq 'n' || $c eq 'H' ) { $j++; }
                elsif ( $c eq 's' ) { $j++; }
                elsif ( $c eq 'q' ) { $spec->{quiet} = 1; $j++; }
                elsif ( $c eq 'a' ) { $spec->{text}  = 1; $j++; }
                elsif ( $c eq 'I' ) { $j++; }
                else {
                    die "grep failed: unsupported grep option '-$c' for the native content search\n";
                }
            }
            $i++;
            next;
        }
        if ( !$no_more_options && !$positional_pattern_seen && $arg =~ /\A-/ && $arg ne '-' ) {
            die "grep failed: unsupported grep option '$arg' for the native content search\n";
        }
        if ( !@{ $spec->{patterns} } && !$positional_pattern_seen ) {
            push @{ $spec->{patterns} }, $arg;
            $positional_pattern_seen = 1;
        }
        else {
            push @{ $spec->{paths} }, $arg;
        }
        $i++;
    }
    die "grep failed: no search pattern given\n" if !@{ $spec->{patterns} };

    my @parts = map { $spec->{fixed} ? quotemeta($_) : $_ } @{ $spec->{patterns} };
    @parts = map { "(?<![A-Za-z0-9_])(?:$_)(?![A-Za-z0-9_])" } @parts if $spec->{word};
    @parts = map { "\\A(?:$_)\\z" } @parts if $spec->{line_regexp};
    my $combined = join '|', map { "(?:$_)" } @parts;
    my $regex = eval { $spec->{ignore_case} ? qr/(?i:$combined)/ : qr/$combined/ };
    die "grep failed: invalid search pattern: $@" if !$regex;
    $spec->{regex} = $regex;
    return $spec;
}

# _native_grep_set_directories($spec, $mode)
# Applies one -d/--directories value to the native search specification.
# 'read' is the default behaviour when no -d or -r option is given. Like
# -r and -R, each -d sets the directory mode and the last one wins,
# matching GNU grep, where `-d skip -r` recurses and `-r -d skip` skips.
# Input: specification hash reference and mode string.
# Output: none. Dies naming the value for anything else.
sub _native_grep_set_directories {
    my ( $spec, $mode ) = @_;
    die "grep failed: unsupported --directories mode '$mode'\n"
      if $mode ne 'read' && $mode ne 'skip' && $mode ne 'recurse';
    $spec->{directories} = $mode;
    return;
}

# _native_grep_path($spec, $path)
# Searches one command-line path with the native search: '-' reads
# standard input, a directory recurses only when the directory mode says
# so, and anything else is searched as a file. A directory given without
# recursion is a file error, exactly as system grep reports it with exit
# 2; -d skip silences it.
# Input: specification hash reference and path string.
# Output: matching "file:line:content" lines; file errors are recorded on
# the specification for the caller to report after the search completes.
sub _native_grep_path {
    my ( $spec, $path ) = @_;
    return _native_grep_handle( $spec, \*STDIN, '(standard input)' ) if $path eq '-';
    if ( -d $path ) {
        my $mode = $spec->{directories} // 'read';
        return _native_grep_dir( $spec, $path, [] ) if $mode eq 'recurse';
        return if $mode eq 'skip';
        push @{ $spec->{errors} }, "grep failed: $path: Is a directory\n";
        return;
    }
    if ( !-e $path ) {
        push @{ $spec->{errors} }, "grep failed: $path: No such file or directory\n";
        return;
    }
    return _native_grep_file( $spec, $path, $path );
}

# _native_grep_dir($spec, $dir, $ancestors)
# Recursively searches one directory with the native search. Entries are
# visited in readdir order, as with grep -r; symlinked files are searched
# and symlinked directories are followed only with -R, and a directory
# already on the current ancestor stack is skipped so a symlink cycle
# cannot recurse forever. Unreadable directories are recorded as file
# errors; non-regular entries are skipped silently.
# Input: specification hash reference, directory path, and array reference
# of "dev:ino" pairs for the directories on the current descent stack.
# Output: matching "file:line:content" lines.
sub _native_grep_dir {
    my ( $spec, $dir, $ancestors ) = @_;
    my ( $dev, $ino ) = stat $dir;
    if ( defined $dev && grep { $_ eq "$dev:$ino" } @$ancestors ) {
        return;
    }
    my @stack = @$ancestors;
    push @stack, "$dev:$ino" if defined $dev && defined $ino;
    my $dh;
    if ( !opendir $dh, $dir ) {
        push @{ $spec->{errors} }, "grep failed: $dir: $!\n";
        return;
    }
    my @entries = readdir $dh;
    closedir $dh;
    my @lines;
    for my $entry (@entries) {
        next if $entry eq '.' || $entry eq '..';
        my $path = File::Spec->catfile( $dir, $entry );
        if ( -l $path ) {
            if ( -d $path ) {
                next if !$spec->{recursive_follow};
                push @lines, _native_grep_dir( $spec, $path, \@stack );
            }
            elsif ( -f $path ) {
                push @lines, _native_grep_file( $spec, $path, $path );
            }
            next;
        }
        if ( -d $path ) {
            push @lines, _native_grep_dir( $spec, $path, \@stack );
        }
        elsif ( -f $path ) {
            push @lines, _native_grep_file( $spec, $path, $path );
        }
    }
    return @lines;
}

# _native_grep_file($spec, $file, $display)
# Searches one regular file with the native search, reporting it under
# its display path. A file that cannot be opened is a file error.
# Input: specification hash reference, file path, and display path.
# Output: matching "file:line:content" lines.
sub _native_grep_file {
    my ( $spec, $file, $display ) = @_;
    open my $fh, '<:raw', $file or do {
        push @{ $spec->{errors} }, "grep failed: $file: $!\n";
        return;
    };
    my @lines = _native_grep_handle( $spec, $fh, $display );
    close $fh;
    return @lines;
}

# _native_grep_handle($spec, $fh, $display)
# Searches one open handle line by line with the native search. A line
# matches when the compiled pattern matches it, inverted with -v; the
# whole line must match with -x. A NUL byte anywhere marks the file
# binary - grep reports "binary file matches" and never prints its lines,
# so a binary file contributes nothing (unless -a/--text says to search
# it as text). The line content is printed as-is apart from its newline,
# so a trailing carriage return survives exactly as grep leaves it.
# Input: specification hash reference, open filehandle, and display path.
# Output: matching "display:line:content" lines, or none with -q.
sub _native_grep_handle {
    my ( $spec, $fh, $display ) = @_;
    my @lines;
    my $lineno = 0;
    while ( my $line = <$fh> ) {
        $lineno++;
        if ( !$spec->{text} && index( $line, "\0" ) >= 0 ) {
            return;
        }
        $line =~ s/\n\z//;
        my $matched = $line =~ $spec->{regex} ? 1 : 0;
        $matched = !$matched if $spec->{invert};
        next if !$matched;
        push @lines, "$display:$lineno:$line" if !$spec->{quiet};
    }
    return @lines;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFileGrep - content-search adapter for d2 of

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFileGrep qw(grep_matching_files);
  my @files = grep_matching_files( args => [ '-nr', 'needle', 'src' ] );

=head1 DESCRIPTION

Runs the system C<grep> executable for the historical C<d2 of grep>
mode and returns the unique files containing matches. Arguments remain an
array rather than shell text, so patterns and paths are passed literally to
the child process. C<-H> and C<-n> are added to make output consistently
identifiable when the search scope contains only one file.

On real Windows, when C<grep> does not resolve, the system call cannot
tell a missing binary from no match: Perl's C<system()> falls back to
cmd.exe, which reports the missing binary with exit 1, the same code grep
uses for "no matches". In that one case the adapter settles the ambiguous
exit code with a Perl-native content search that produces the same
"file:line:content" output and flows through the same result decoding;
everywhere C<grep> resolves, the system executable runs untouched.

=head1 PURPOSE

This module adapts content grep results to the file chooser used by the
d2 open-file command.

=head1 WHY IT EXISTS

Path-name regex search and content search are distinct operations. Keeping
grep execution and result decoding here prevents the main open-file resolver
from confusing `grep` options with path patterns and keeps process handling
small and testable.

=head1 WHEN TO USE

Use this module when changing the `d2 of grep` content-search
interface, grep process failure handling, or conversion of grep output into
file matches. The Perl-native fallback lives here too: change it when the
set of grep options it honours needs to grow, or when its output shape
must stay identical to what the system executable produces.
C<native_grep_usage()> prints the usage text for that fallback; C<d2 of
grep --help> shows it when no system grep is installed.

=head1 HOW TO USE

Call C<grep_matching_files> with the arguments following the C<grep> token.
It returns matching paths in first-seen order, returns an empty list for
grep's normal no-match status, and reports execution errors or invalid grep
arguments explicitly. The native fallback honours C<-r>/C<-R>, C<-i>,
C<-v>, C<-w>, C<-x>, C<-F>, C<-E>, C<-e>, C<-n>, C<-H>, C<-s>, C<-q>,
C<-a>, C<-I>, C<-d> and their long forms; any other option dies naming
the flag rather than searching with the wrong meaning, and any file error
dies naming the file, exactly as a system grep failure with exit 2 does.

=head1 WHAT USES IT

C<Developer::Dashboard::CLI::OpenFile> dispatches the public C<d2 of
grep> form to this module, then sends the returned paths to the regular print
or editor-selection flow.

=head1 EXAMPLES

  my @recursive = grep_matching_files( args => [ '-nr', 'needle', 'lib' ] );
  my @literal   = grep_matching_files( args => [ '-nr', '-F', 'a+b', 'lib' ] );

=cut
