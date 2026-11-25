package Local::NativeCommand;

# Local::NativeCommand
#
# Runs the small POSIX shell fragments the test suite uses, without a shell.
#
# The tests historically launched commands through `system 'sh', '-c', $cmd`.
# That works on Unix, but the Windows Sandbox used for Windows testing has
# no sh (and no bash) at all, so every such call failed there. This module
# gives the tests a shell-independent way to run the same command strings:
# on Unix it still delegates to `sh -c` (unchanged behaviour); on Windows
# it parses the fragment and runs the argv list directly, so no shell
# binary is needed.
#
# The parser understands only the constructs the test suite actually uses,
# and dies loudly on anything else rather than guessing:
#   * plain commands with single/double/bare words, $VAR inside double
#     quotes, and `VAR='value'` environment prefixes;
#   * `&&` chains, `|` pipes, `cd 'dir'` (changes the directory for the
#     rest of the chain), `printf '...'` and `cat 'file'` as pipe sources;
#   * output redirects `>/dev/null`, `2>/dev/null` and `2>&1`;
#   * input redirect `<file` (the file becomes the command's stdin, and
#     wins over piped input, as in sh).
# Unsupported constructs (`;`, `||`, `$(...)`, backticks, `>file`,
# `>>`, `bash`/`sh` as a command) are fatal - a test that needs them must
# either be rewritten or skipped on Windows.
#
# One Windows-only behaviour: a bare `:` segment inside an environment
# value is translated to `;` (the Windows PATH separator). The suite
# builds PATH values as `PATH='$fake_bin':"$PATH"`, and a literal `:` would
# glue the fake bin dir and the rest of PATH into one unusable entry.
# Only a bare `:` part is translated: a colon inside a quoted string
# (for example `PATH='a:b'`) is part of that literal value and is
# intentionally left alone, exactly as POSIX quoting would keep it.
#
# Options to run_shell_command:
#   env           => { NAME => value, ... } - environment overrides applied
#                  to every command in the fragment (undef deletes the key,
#                  matching `local $ENV{NAME};`).
#   force_windows => 1 - take the Windows code path on any platform, so the
#                  parser and runner can be exercised on Linux (the test
#                  suite uses this to compare against `sh -c`).
#
# Return of run_shell_command: list of (stdout, stderr, exit_code), where
# exit_code is the shifted exit status ($? >> 8), as Capture::Tiny callers
# in the suite expect.

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use Exporter qw(import);
use File::Spec;
use File::Temp qw(tempfile);

our @EXPORT_OK = qw(run_shell_command parse_posix_command);

# run_shell_command($cmd, \%options)
# Runs one shell fragment and returns (stdout, stderr, exit_code).
# Input: command string as the suite writes it for `sh -c`; options as
# documented above.
# Output: list of (stdout, stderr, exit_code).
sub run_shell_command {
    my ( $cmd, $options ) = @_;
    $options ||= {};
    my $windows = $options->{force_windows} ? 1 : ( $^O eq 'MSWin32' ? 1 : 0 );
    if ( !$windows ) {
        my ( $stdout, $stderr, $exit ) = capture {
            local %ENV = %ENV;
            _apply_env_overrides( $options->{env} );
            system 'sh', '-c', $cmd;
            return $? >> 8;
        };
        return ( $stdout, $stderr, $exit );
    }
    my $plan = parse_posix_command( $cmd, { windows => 1 } );
    return _execute_plan( $plan, $options );
}

# parse_posix_command($cmd, \%options)
# Parses one shell fragment into a plan the executor runs.
# Input: command string; options { windows => 1 } for the Windows-only
# `:` to `;` translation inside environment values.
# Output: hashref { steps => [ ... ] } where a step is either
# { type => 'cd', dir => $dir } or { type => 'pipeline', stages => [...] };
# a stage is { argv => [...], env => {...}, producer => undef | {...},
# discard_stdout => 0|1, discard_stderr => 0|1, merge_stderr => 0|1,
# stdin_file => undef | $path }.
sub parse_posix_command {
    my ( $cmd, $options ) = @_;
    $options  ||= {};
    my $windows = $options->{windows} ? 1 : 0;
    my $tokens  = _tokenise($cmd);
    _merge_fd_redirects($tokens);
    my @steps;
    for my $step_tokens ( _split_tokens( $tokens, 'AND' ) ) {
        die "empty command segment in command: $cmd" if !@{$step_tokens};
        my @stages;
        for my $stage_tokens ( _split_tokens( $step_tokens, 'PIPE' ) ) {
            die "empty pipeline stage in command: $cmd" if !@{$stage_tokens};
            push @stages, _build_stage( $stage_tokens, $cmd, $windows );
        }
        if ( @stages == 1 && defined $stages[0]{argv} && $stages[0]{argv}[0] eq 'cd' ) {
            die "cd takes exactly one directory argument in command: $cmd"
              if @{ $stages[0]{argv} } != 2 || keys %{ $stages[0]{env} };
            push @steps, { type => 'cd', dir => $stages[0]{argv}[1] };
        }
        else {
            for my $stage (@stages) {
                die "cd is only supported as a chain step, not inside a pipeline, in command: $cmd"
                  if defined $stage->{argv} && $stage->{argv}[0] eq 'cd';
            }
            push @steps, { type => 'pipeline', stages => \@stages };
        }
    }
    return { steps => \@steps };
}

# _apply_env_overrides($overrides)
# Applies an env override map to %ENV: a defined value sets the key, an
# undefined value deletes it. The caller localises %ENV first.
sub _apply_env_overrides {
    my ($overrides) = @_;
    return if !$overrides;
    while ( my ( $key, $value ) = each %{$overrides} ) {
        if ( defined $value ) { $ENV{$key} = $value; }
        else                  { delete $ENV{$key}; }
    }
    return;
}

# _tokenise($text)
# Splits a command string into tokens. A WORD token carries its parts
# (single/double/bare) plus its byte offsets, so a digit word immediately
# before a redirect can be recognised as its file descriptor.
sub _tokenise {
    my ($text) = @_;
    my @tokens;
    my $i = 0;
    my $n = length $text;
    while ( $i < $n ) {
        my $c    = substr( $text, $i, 1 );
        my $rest = substr( $text, $i );
        if ( $c =~ /\s/ ) { $i++; next; }
        if ( $rest =~ /\A((?:>&1|>\/dev\/null))/ ) {
            my $matched = $1;
            my $target = $matched eq '>&1' ? 'merge' : 'null';
            push @tokens, { type => 'REDIR', fd => 1, target => $target, start => $i, end => $i + length $matched };
            $i += length $matched;
            next;
        }
        if ( $rest =~ /\A>>/ ) {
            die "unsupported append redirect '>>' in command: $text";
        }
        if ( $c eq '>' ) {
            die "unsupported output redirect in command: $text";
        }
        if ( $c eq '<' ) {
            die "unsupported heredoc '<<' in command: $text" if substr( $text, $i, 2 ) eq '<<';
            push @tokens, { type => 'REDIR', fd => 0, target => 'input', start => $i, end => $i + 1 };
            $i++;
            next;
        }
        if ( $c eq '|' ) {
            die "unsupported shell operator '||' in command: $text" if substr( $text, $i, 2 ) eq '||';
            push @tokens, { type => 'PIPE', start => $i, end => $i + 1 };
            $i++;
            next;
        }
        if ( $c eq '&' ) {
            die "unsupported shell operator '&' in command: $text" if substr( $text, $i, 2 ) ne '&&';
            push @tokens, { type => 'AND', start => $i, end => $i + 2 };
            $i += 2;
            next;
        }
        if ( $c eq ';' ) {
            die "unsupported shell operator ';' in command: $text";
        }
        if ( $c eq '`' ) {
            die "unsupported backtick command substitution in command: $text";
        }
        if ( substr( $text, $i, 2 ) eq '$(' ) {
            die "unsupported command substitution '\$(...)' in command: $text";
        }
        my $start = $i;
        my @parts;
        while ( $i < $n ) {
            $c = substr( $text, $i, 1 );
            last if $c =~ /\s/ || $c eq '|' || $c eq '&' || $c eq ';' || $c eq '>' || $c eq '<';
            if ( $c eq "'" ) {
                my $end = index( $text, "'", $i + 1 );
                die "unterminated single quote in command: $text" if $end < 0;
                push @parts, { kind => 'single', text => substr( $text, $i + 1, $end - $i - 1 ) };
                $i = $end + 1;
            }
            elsif ( $c eq '"' ) {
                my $end = _find_double_quote_end( $text, $i + 1 );
                die "unterminated double quote in command: $text" if $end < 0;
                push @parts, { kind => 'double', text => substr( $text, $i + 1, $end - $i - 1 ) };
                $i = $end + 1;
            }
            elsif ( $c eq '\\' ) {

                # A bare backslash is literal (Windows paths), so a pair
                # is consumed together and kept as-is.
                die "trailing backslash in command: $text" if $i + 1 >= $n;
                push @parts, { kind => 'bare', text => substr( $text, $i, 2 ) };
                $i += 2;
            }
            else {
                my $word_start = $i;
                while ( $i < $n ) {
                    my $ch = substr( $text, $i, 1 );
                    last if $ch =~ /[\s|&;><'"]/ || $ch eq '\\';
                    $i++;
                }
                push @parts, { kind => 'bare', text => substr( $text, $word_start, $i - $word_start ) };
            }
        }
        push @tokens, { type => 'WORD', parts => \@parts, start => $start, end => $i } if @parts;
    }
    return \@tokens;
}

# _find_double_quote_end($text, $offset)
# Finds the closing double quote at or after $offset, skipping `\"` and
# `\\` pairs. Returns the offset of the quote, or -1 when unterminated.
sub _find_double_quote_end {
    my ( $text, $offset ) = @_;
    my $n = length $text;
    my $i = $offset;
    while ( $i < $n ) {
        my $c = substr( $text, $i, 1 );
        return $i if $c eq '"';
        $i += 2, next if $c eq '\\' && $i + 1 < $n;
        $i++;
    }
    return -1;
}

# _merge_fd_redirects($tokens)
# A digit word ending exactly where a redirect begins is the redirect's
# file descriptor (`2>&1`, `2>/dev/null`), not an argument. Anything else
# (a digit word separated from the redirect by whitespace) stays a word.
sub _merge_fd_redirects {
    my ($tokens) = @_;
    my @merged;
    for my $token ( @{$tokens} ) {
        if (   $token->{type} eq 'REDIR'
            && @merged
            && $merged[-1]{type} eq 'WORD'
            && $merged[-1]{end} == $token->{start} )
        {
            my $word = _word_value( $merged[-1]{parts}, 0, 0 );
            if ( $word =~ /\A[12]\z/ ) {
                $token->{fd} = $word;
                pop @merged;
            }
        }
        push @merged, $token;
    }
    @{$tokens} = @merged;
    return;
}

# _split_tokens($tokens, $type)
# Splits a token list at tokens of the given type, keeping the pieces.
sub _split_tokens {
    my ( $tokens, $type ) = @_;
    my @pieces = ( [] );
    for my $token ( @{$tokens} ) {
        if ( $token->{type} eq $type ) { push @pieces, []; }
        else                           { push @{ $pieces[-1] }, $token; }
    }
    return @pieces;
}

# _build_stage($tokens, $cmd, $windows)
# Turns a stage's tokens into a stage hash: environment assignments,
# argv, redirects, and the printf/cat pipe sources.
sub _build_stage {
    my ( $tokens, $cmd, $windows ) = @_;
    my $stage = {
        argv           => [],
        env            => {},
        producer       => undef,
        discard_stdout => 0,
        discard_stderr => 0,
        merge_stderr   => 0,
        stdin_file     => undef,
    };
    my $i = 0;
    while ( $i < @{$tokens} ) {
        my $token = $tokens->[$i];
        if ( $token->{type} eq 'REDIR' ) {
            if ( $token->{target} eq 'input' ) {
                die "input redirect on fd $token->{fd} is unsupported (only stdin) in command: $cmd"
                  if $token->{fd} != 0;
                die "multiple input redirects in command: $cmd" if defined $stage->{stdin_file};
                die "input redirect without a file in command: $cmd"
                  if $i + 1 >= @{$tokens} || $tokens->[ $i + 1 ]{type} ne 'WORD';
                $stage->{stdin_file} = _word_value( $tokens->[ $i + 1 ]{parts}, $windows, 0 );
                $i += 2;
                next;
            }
            if ( $token->{target} eq 'null' ) {
                if    ( $token->{fd} == 1 ) { $stage->{discard_stdout} = 1; }
                elsif ( $token->{fd} == 2 ) { $stage->{discard_stderr} = 1; }
            }
            elsif ( $token->{target} eq 'merge' ) {
                die "unsupported redirect '1>&1' in command: $cmd" if $token->{fd} == 1;
                $stage->{merge_stderr} = 1;
            }
            $i++;
            next;
        }
        my $word = $token;
        if ( !@{ $stage->{argv} } && !defined $stage->{producer} ) {
            my $assignment = _assignment_parts( $word->{parts} );
            if ($assignment) {
                my ( $name, $value_parts ) = @{$assignment};
                $stage->{env}{$name} = _parts_value( $value_parts, $windows, 1 );
                $i++;
                next;
            }
        }
        push @{ $stage->{argv} }, _word_value( $word->{parts}, $windows, 0 );
        $i++;
    }
    die "environment assignment without a command is unsupported in command: $cmd"
      if !@{ $stage->{argv} } && !defined $stage->{producer};
    if ( @{ $stage->{argv} } ) {
        my $command = $stage->{argv}[0];
        if ( $command eq 'bash' || $command eq 'sh' || $command eq 'zsh' ) {
            die "command runs $command, which is not available on Windows: $cmd";
        }
        # `command` is a shell builtin: in sh it takes precedence over
        # PATH lookup, so an external binary of the same name must never
        # satisfy it — on the macOS CI runner a `command` binary on PATH
        # let `command -v` run instead of dying. Reject it by name, so
        # `command -v` can never work through this runner.
        if ( $command eq 'command' ) {
            die "command is a shell builtin, which is not available on Windows: $cmd";
        }
        if ( $command eq 'printf' ) {
            die "printf takes exactly one format argument in command: $cmd" if @{ $stage->{argv} } != 2;
            die "printf formats with '%' are unsupported in command: $cmd" if $stage->{argv}[1] =~ /%/;
            $stage->{producer} = { kind => 'printf', format => $stage->{argv}[1] };
            $stage->{argv} = undef;
        }
        elsif ( $command eq 'cat' ) {
            die "cat takes exactly one file argument in command: $cmd" if @{ $stage->{argv} } != 2;
            $stage->{producer} = { kind => 'cat', file => $stage->{argv}[1] };
            $stage->{argv} = undef;
        }
    }
    return $stage;
}

# _assignment_parts($parts)
# Recognises a `NAME=value` assignment word: its first part must be bare
# and start with NAME=. Returns [ name, value parts ] or undef.
sub _assignment_parts {
    my ($parts) = @_;
    return undef if !@{$parts} || $parts->[0]{kind} ne 'bare';
    my $first = $parts->[0]{text};
    return undef if $first !~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s;
    my ( $name, $rest ) = ( $1, $2 );
    my @value_parts;
    push @value_parts, { kind => 'bare', text => $rest } if $rest ne '';
    push @value_parts, @{$parts}[ 1 .. $#{$parts} ] if @{$parts} > 1;
    return [ $name, \@value_parts ];
}

# _word_value($parts, $windows, $is_env_value)
# Evaluates a word's parts into a string. Single quotes are literal,
# double quotes expand $VAR, bare parts are literal.
sub _word_value {
    my ( $parts, $windows, $is_env_value ) = @_;
    return _parts_value( $parts, $windows, $is_env_value );
}

# _parts_value($parts, $windows, $is_env_value)
# Evaluates a list of parts into one string.
sub _parts_value {
    my ( $parts, $windows, $is_env_value ) = @_;
    my $value = '';
    for my $part ( @{$parts} ) {
        if ( $part->{kind} eq 'bare' ) {
            my $text = $part->{text};
            $text = ';' if $windows && $is_env_value && $text eq ':';
            $value .= $text;
        }
        elsif ( $part->{kind} eq 'single' ) {
            $value .= $part->{text};
        }
        else {
            $value .= _expand_double_quoted( $part->{text} );
        }
    }
    return $value;
}

# _expand_double_quoted($text)
# Expands a double-quoted string: $VAR and ${VAR} from %ENV, with `\"`,
# `\\`, `\$` and backtick escapes taken literally.
sub _expand_double_quoted {
    my ($text) = @_;
    my $value = '';
    my $i     = 0;
    my $n     = length $text;
    while ( $i < $n ) {
        my $c = substr( $text, $i, 1 );
        if ( $c eq '\\' && $i + 1 < $n ) {
            my $next = substr( $text, $i + 1, 1 );
            if ( $next eq '"' || $next eq '\\' || $next eq '$' || $next eq '`' ) {
                $value .= $next;
                $i += 2;
                next;
            }
            $value .= $c;
            $i++;
            next;
        }
        if ( $c eq '$' ) {
            my $rest = substr( $text, $i );
            if ( $rest =~ /\A(\$\{[A-Za-z_][A-Za-z0-9_]*\})/ ) {
                my $matched = $1;
                my ($name) = $matched =~ /\A\$\{([A-Za-z_][A-Za-z0-9_]*)\}/;
                $value .= $ENV{$name} // '';
                $i += length $matched;
                next;
            }
            if ( $rest =~ /\A(\$[A-Za-z_][A-Za-z0-9_]*)/ ) {
                my $matched = $1;
                my ($name) = $matched =~ /\A\$([A-Za-z_][A-Za-z0-9_]*)/;
                $value .= $ENV{$name} // '';
                $i += length $matched;
                next;
            }
            die "unsupported dollar expansion in double-quoted text: $text";
        }
        $value .= $c;
        $i++;
    }
    return $value;
}

# _execute_plan($plan, $options)
# Runs a parsed plan: && chain steps in order, stopping at the first
# non-zero exit. Returns (stdout, stderr, exit_code).
sub _execute_plan {
    my ( $plan, $options ) = @_;
    my ( $total_out, $total_err ) = ( '', '' );
    my $exit = 0;
    my $cwd;
    for my $step ( @{ $plan->{steps} } ) {
        if ( $step->{type} eq 'cd' ) {
            if ( !-d $step->{dir} ) {
                $total_err .= "cd: $step->{dir}: No such file or directory\n";
                $exit = 1;
                last;
            }
            $cwd  = $step->{dir};
            $exit = 0;
            next;
        }
        my ( $out, $err, $rc ) = _execute_pipeline( $step->{stages}, $cwd, $options );
        $total_out .= $out;
        $total_err .= $err;
        $exit = $rc;
        last if $rc != 0;
    }
    return ( $total_out, $total_err, $exit );
}

# _execute_pipeline($stages, $cwd, $options)
# Runs one pipeline: producers feed the next stage's stdin, real stages
# run directly. Returns (stdout, stderr, exit_code) of the pipeline,
# whose exit is the last stage's exit, as in sh.
sub _execute_pipeline {
    my ( $stages, $cwd, $options ) = @_;
    my ( $pipeline_out, $pipeline_err ) = ( '', '' );
    # Start at 0: the parser dies on an empty pipeline stage, so no
    # stages is unreachable in practice — but the return must stay
    # defined even then, instead of leaking an undef exit code.
    my $exit = 0;
    my $input_bytes;
    for my $stage ( @{$stages} ) {
        my ( $stage_out, $stage_err, $stage_exit );
        if ( defined $stage->{producer} ) {
            ( $stage_out, $stage_err, $stage_exit ) = _run_producer( $stage->{producer} );
        }
        else {
            ( $stage_out, $stage_err, $stage_exit ) = _run_stage( $stage, $input_bytes, $cwd, $options );
        }
        # Merge first, then discard: when a stage has both `>/dev/null`
        # and `2>&1`, stderr is merged into a stdout that is then thrown
        # away, so both streams end up discarded — exactly as sh does for
        # that order. (Redirect order is not tracked: `2>&1 >/dev/null`
        # would keep stderr in sh, but the suite never writes it that way.)
        if ( $stage->{merge_stderr} ) {
            $stage_out .= $stage_err;
            $stage_err = '';
        }
        $stage_out = '' if $stage->{discard_stdout};
        $stage_err = '' if $stage->{discard_stderr};
        $input_bytes  = $stage_out;
        $pipeline_out = $stage_out;
        $pipeline_err .= $stage_err;
        $exit = $stage_exit;
    }
    return ( $pipeline_out, $pipeline_err, $exit );
}

# _run_producer($producer)
# Produces the bytes a printf or cat pipe source feeds the next stage.
sub _run_producer {
    my ($producer) = @_;
    if ( $producer->{kind} eq 'printf' ) {
        return ( _interpret_printf_format( $producer->{format} ), '', 0 );
    }
    my $file = $producer->{file};
    open my $fh, '<:raw', $file or return ( '', "cat: $file: No such file or directory\n", 1 );
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $file: $!";
    return ( $content // '', '', 0 );
}

# _interpret_printf_format($format)
# Interprets the escapes sh's printf applies to its format: \n \t \r \\
# \' \" \a \b \f \v and \0; anything else keeps its backslash.
sub _interpret_printf_format {
    my ($format) = @_;
    my %escape = (
        'n'  => "\n",
        't'  => "\t",
        'r'  => "\r",
        '\\' => '\\',
        "'"  => "'",
        '"'  => '"',
        'a'  => "\a",
        'b'  => "\b",
        'f'  => "\f",
        'v'  => "\013",
        '0'  => "\0",
    );
    $format =~ s/\\(.)/exists $escape{$1} ? $escape{$1} : "\\$1"/ge;
    return $format;
}

# _quote_windows_arg($arg)
# Quotes one argv element for the Windows command line, using the
# MSVC CRT rules the child applies when it parses its command line
# (CommandLineToArgvW): an element with no space, tab, newline or
# double quote passes through unchanged; otherwise it is wrapped in
# double quotes, each embedded double quote is escaped as \", and
# each run of backslashes before a double quote (or before the
# closing quote) is doubled, so a trailing backslash cannot escape
# the closing quote.
# This is needed because Perl's list-form system() on Windows joins
# argv with spaces and quotes space-containing elements but does NOT
# escape embedded double quotes: an element such as
# `print "hello\n"` reaches the child split into `print` and
# `hello\n`, so -e receives the truncated program `print ` and
# prints nothing with exit 0. Pre-quoting here round-trips: Perl
# wraps the already-quoted element once more and the CRT parser
# strips the outer pair, leaving the original element intact
# (verified by probe on win-ts: a pre-quoted `print "hello\n"`
# arrives as one arg, while the unquoted form splits in two).
# Gated on $^O, not on force_windows: on Unix list-form system()
# is a direct exec with no command-line parsing, so quoting there
# would corrupt argv (the quotes would become literal characters
# of the argument), and the Unix comparison cases must stay
# byte-identical to sh.
sub _quote_windows_arg {
    my ($arg) = @_;
    return $arg if $arg ne '' && $arg !~ /[\s"]/;
    my $quoted     = '"';
    my $backslashes = 0;
    for my $char ( split //, $arg ) {
        if ( $char eq '\\' ) {
            $backslashes++;
            next;
        }
        if ( $char eq '"' ) {
            $quoted .= '\\' x ( 2 * $backslashes + 1 );
            $quoted .= '"';
        }
        else {
            $quoted .= '\\' x $backslashes;
            $quoted .= $char;
        }
        $backslashes = 0;
    }
    $quoted .= '\\' x ( 2 * $backslashes );
    $quoted .= '"';
    return $quoted;
}

# _run_stage($stage, $stdin_bytes, $cwd, $options)
# Runs one real command directly (no shell): list-form system under
# Capture::Tiny, with stdin fed from a temp file when the stage reads
# from a pipe, and the caller's env overrides applied. On Windows the
# argv elements are quoted first (see _quote_windows_arg): list-form
# system() mangles elements containing embedded double quotes there.
sub _run_stage {
    my ( $stage, $stdin_bytes, $cwd, $options ) = @_;
    my ( $stdout, $stderr, $exit );
    # getcwd() first: it returns undef when the working directory has
    # been deleted, and chdir undef would silently go to HOME instead of
    # dying — so the failure must surface here, before any temp file is
    # created and before anything chdirs.
    my $orig_cwd = getcwd() // die "cannot determine current working directory: $!";
    my $stdin_file;
    my $stdin_is_temp = 0;
    if ( defined $stage->{stdin_file} ) {

        # An explicit `<file` redirect wins over piped input, as in sh.
        # A missing file fails the command (exit 1) instead of dying: the
        # test that needs the file created it, so a missing file is a test
        # failure, not a runner failure. The redirect file belongs to the
        # caller, so it is never unlinked afterwards (only a temp file
        # written from piped input is).
        $stdin_file = $stage->{stdin_file};
        my $probe;
        if ( !open $probe, '<:raw', $stdin_file ) {
            return ( '', "cannot read stdin file '$stdin_file': $!\n", 1 );
        }
        close $probe;
    }
    elsif ( defined $stdin_bytes ) {
        my ( $fh, $name ) = tempfile( UNLINK => 0 );
        # Record the name before writing: the file is created with
        # UNLINK => 0, so a die from print or close below would
        # otherwise orphan it — the cleanup unlink at the end of this
        # sub is only reached when the write succeeds. The write is
        # wrapped so a failure unlinks the file before re-dying;
        # merely assigning the name early would not help, because the
        # die would still skip past the unlink.
        $stdin_file = $name;
        my $write_ok = eval {
            binmode $fh;
            print {$fh} $stdin_bytes or die "Unable to write stdin file: $!";
            close $fh or die "Unable to close stdin file: $!";
            1;
        };
        if ( !$write_ok ) {
            my $error = $@;
            unlink $stdin_file;
            die $error;
        }
        $stdin_is_temp = 1;
    }
    my $ok = eval {
        ( $stdout, $stderr, $exit ) = capture {
            local %ENV = %ENV;
            _apply_env_overrides( $options->{env} );
            _apply_env_overrides( $stage->{env} );
            chdir $cwd or die "cannot change to directory '$cwd': $!" if defined $cwd;
            my $command = $stage->{argv}[0];
            die "command '$command' is not available (no shell is present to resolve it)"
              if !_find_executable($command);
            # On Windows, quote the argv elements first: list-form
            # system() mangles elements with embedded double quotes
            # (see _quote_windows_arg). The Unix path — including
            # force_windows runs on Unix — stays unquoted, because
            # there list-form system() is a direct exec.
            my @argv = @{ $stage->{argv} };
            @argv = map { _quote_windows_arg($_) } @argv if $^O eq 'MSWin32';
            my $rc = _with_stdin_file(
                $stdin_file,
                sub {
                    system @argv;
                    return $? >> 8;
                }
            );
            return $rc;
        };
        1;
    };
    my $error = $@;
    my $restore_failed = !chdir $orig_cwd;
    unlink $stdin_file if $stdin_is_temp;
    die "cannot restore working directory '$orig_cwd': $!" if $restore_failed;
    die $error if !$ok;
    return ( $stdout, $stderr, $exit );
}

# _with_stdin_file($file, $code)
# Runs $code with STDIN reading from $file (undef means leave STDIN
# alone), restoring the original stdin afterwards. A `local *STDIN` does
# NOT do this: it shadows the glob without touching file descriptor 0,
# so a child would still inherit the harness stdin and block on it. The
# descriptor is duplicated aside and restored, so a failure inside $code
# cannot leave the process with a redirected stdin.
sub _with_stdin_file {
    my ( $file, $code ) = @_;
    return $code->() if !defined $file;
    open my $saved, '<&', \*STDIN or die "cannot save stdin file descriptor: $!";
    my $result;
    my $ok = eval {
        open STDIN, '<:raw', $file or die "cannot read stdin file '$file': $!";
        $result = $code->();
        1;
    };
    my $error = $@;
    open STDIN, '<&', $saved or warn "cannot restore stdin file descriptor: $!";
    close $saved or warn "cannot close saved stdin file descriptor: $!";
    die $error if !$ok;
    return $result;
}

# _find_executable($name)
# Checks a command is runnable without a shell: a path is checked
# directly (with .exe/.bat/.cmd tried on Windows), a bare name is
# searched on PATH. A missing command dies loudly by design — with no
# shell present there is no exit 127 to return. Under force_windows on
# Unix the check uses Unix -x semantics (extension candidates only on
# real MSWin32); the native Unix path never reaches here, it delegates
# to sh -c.
sub _find_executable {
    my ($name) = @_;
    my @candidates = ($name);
    push @candidates, "$name.exe", "$name.bat", "$name.cmd" if $^O eq 'MSWin32';
    if ( $name =~ m{[/\\]} ) {
        for my $candidate (@candidates) {
            return 1 if -x $candidate;
        }
        return 0;
    }
    for my $dir ( File::Spec->path() ) {
        for my $candidate (@candidates) {
            return 1 if -x File::Spec->catfile( $dir, $candidate );
        }
    }
    return 0;
}

1;

__END__

=head1 NAME

Local::NativeCommand - shell-independent runner for the test suite's small POSIX fragments

=head1 PURPOSE

Run the small POSIX shell fragments the test suite uses without a shell, so
tests that launch commands work on the Windows Sandbox, where no sh or bash
exists at all.

=head1 WHY IT EXISTS

The test suite historically launched commands through C<system 'sh', '-c',
$cmd>. That works on Unix, but the Windows Sandbox used for Windows testing
has no sh, so every such call failed there and the CLI smoke file aborted
after 36 subtests. This module gives the tests a shell-independent way to run
the same command strings: on Unix it still delegates to C<sh -c>, unchanged;
on Windows it parses the fragment and runs the argv list directly.

=head1 WHEN TO USE

When a test needs to run a shell fragment (a command chain, a pipe, a
redirect, an env prefix) and must work on Windows as well as Unix. Use
C<force_windows> to exercise the Windows path on Linux while developing the
parser, and to compare its output against real C<sh -c>.

=head1 HOW TO USE

Call C<run_shell_command($cmd, \%options)>; it returns a list of
C<(stdout, stderr, exit_code)>, where the exit code is the shifted exit
status as Capture::Tiny callers expect. Options are C<env> (a map of
environment overrides applied to every command in the fragment; an undef
value deletes the key) and C<force_windows> (take the Windows code path on
any platform). The parser understands plain commands, C<&&> chains, C<|>
pipes, C<cd>, C<printf>/C<cat> pipe sources, C<E<gt>/dev/null>,
C<2E<gt>/dev/null> and C<2E<gt>&1>, input redirect C<E<lt>file>, plus
environment prefixes with C<$VAR> expansion. Anything else dies loudly
rather than guessing.

=head1 WHAT USES IT

C<t/05-cli-smoke.t> uses it for every command it launches (its C<_run>,
C<_gate_run> and C<_sh_capture> helpers), and C<t/812-native-command.t>
covers the runner itself.

=head1 EXAMPLES

Run a chain with no shell:

    my ($out, $err, $rc) = run_shell_command("cd '$dir' && $perl -e 'print 1'", {});

Feed a pipe source through the Windows path while on Linux:

    my ($out, $err, $rc) = run_shell_command(
        "printf 'a\\nb\\n' | $perl -ne 'print'",
        { force_windows => 1 },
    );

=cut