package Developer::Dashboard::CLI::OpenFileChooser;

use strict;
use warnings;

our $VERSION = '6.31';

use Exporter 'import';

use Developer::Dashboard::CLI::OpenFileUtil qw(_unique_matches);

our @EXPORT_OK = qw(_default_editor _editor_supports_tabs _select_open_file_matches _stdin_has_pending_input _selection_matches);

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
    return $editor =~ /\A(?:vim|nvim|vi|gvim|view)\z/i ? 1 : 0;
}

# _stdin_has_pending_input($timeout_seconds)
# Reports whether STDIN either already has data waiting to be read or is a
# real interactive terminal (where a person is expected to type), within a
# short timeout. Wrapped so tests can override it and force either branch
# without depending on real timing or a real tty.
#
# Deliberately NOT a bare "is STDIN a tty" check: this command's chooser is
# designed to be answered non-interactively by piping an answer ahead of
# time (e.g. `printf '2\n' | d2 of ...`), which is real, documented,
# already-tested behavior (t/05-cli-smoke.t) - a tty-only check would wrongly
# treat that legitimate piped answer as "nobody is coming" and skip reading
# it. The actual hang this guards against is narrower: a STDIN connection
# (pipe or inherited terminal) that stays open with no data and no EOF,
# which a bare read would block on indefinitely. Already-closed STDIN (EOF)
# needs no help here - `<STDIN>` returns undef immediately in that case,
# which the existing "no selection made" fallback below already handles.
# Input: how many seconds to wait for STDIN to become ready before giving up.
# Output: true when STDIN is a tty, already has data ready to read, or is not
# a real OS file descriptor at all (see below).
sub _stdin_has_pending_input {
    my ($timeout_seconds) = @_;
    return 1 if _stdin_is_tty();

    # select()/IO::Select can only examine a real OS file descriptor (a pipe,
    # socket, terminal or regular file) - an in-memory filehandle opened as
    # `open my $fh, '<', \$scalar` (this project's own established way of
    # faking STDIN in tests, see t/98-cli-openfile-coverage.t) reports a
    # DEFINED but negative fileno (-1 on this platform, verified live), not
    # undef, and select() never reports it ready no matter how much data it
    # actually holds - waiting the full timeout every time. Reading from an
    # in-memory handle can never physically block the process regardless of
    # its content, so there is nothing this check needs to protect against
    # there - treat any non-real (missing or negative) fileno as always
    # ready and let the ordinary read proceed.
    my $fileno = fileno(STDIN);
    return 1 if !defined $fileno || $fileno < 0;

    if ( $^O eq 'MSWin32' ) {
        # On Windows IO::Select only works for real sockets, so the call
        # below returns 0 immediately for a regular file (which never
        # blocks) and never waits out the timeout for a pipe, which is
        # exactly backwards. Answer the two cases Windows can answer
        # natively and leave anything else (a socket) to IO::Select.
        return 1 if -f STDIN;
        if ( -p STDIN ) {
            my $ready = _windows_stdin_pipe_ready($timeout_seconds);
            return $ready if defined $ready;
            return 1;    # the native check is unavailable: fall back to the ordinary blocking read
        }
    }

    # select(2) - and therefore IO::Select - is only reliably usable on
    # non-socket handles (a console, a pipe, STDIN itself) on Unix-family
    # platforms; on Windows it is documented to work only for real sockets,
    # and its behavior for a console/pipe handle is unreliable rather than
    # a clean, catchable failure. Guard the call so any platform-specific
    # misbehavior here can only ever fall back to this project's own
    # pre-existing (pre-DD-915) behavior - an ordinary blocking read - never
    # a new, worse failure mode. This project's Windows platform-test gate
    # is answered by this fallback rather than a real Windows run: the
    # worst case on an unsupported platform is exactly what shipped before
    # this ticket, not a regression.
    my $ready = eval {
        require IO::Select;
        my $select = IO::Select->new( \*STDIN );
        $select->can_read($timeout_seconds) ? 1 : 0;
    };
    return 1 if !defined $ready;    # IO::Select misbehaving on this platform: fall back to the ordinary blocking read
    return $ready;
}

# _windows_stdin_pipe_ready($timeout_seconds)
# Polls a Windows pipe STDIN for waiting data with PeekNamedPipe, which is
# the Windows-native readiness check for a pipe: select() cannot wait on
# one. A closed writer (broken pipe) counts as ready, because a read then
# returns end-of-file at once instead of blocking.
#
# PeekNamedPipe lives in kernel32 and is reached through Win32::API;
# Win32API::File does not export it. The real Win32 HANDLE comes from
# Win32API::File::GetOsFHandle with the filehandle glob: passing the fileno
# number instead returns nothing (proved live on Strawberry Perl 5.38.2),
# which made the earlier version of this check report every silent pipe as
# ready at once. This is the same route StreamDrain already takes for its
# Windows pipes, and the byte count is read by its helper.
# Input: how many seconds to wait for data before giving up.
# Output: true when data is waiting or the pipe is at end-of-file, false
# when the timeout expires with nothing waiting, or undef when the native
# check cannot run at all.
sub _windows_stdin_pipe_ready {
    my ($timeout_seconds) = @_;
    my ( $peek, $handle ) = eval {
        require Win32API::File;
        require Win32::API;
        require Developer::Dashboard::StreamDrain;
        my $imported = Win32::API->new( 'kernel32', 'PeekNamedPipe', 'QPIPPP', 'I' );
        die "Could not import PeekNamedPipe from kernel32\n" if !defined $imported;
        my $os_handle = Win32API::File::GetOsFHandle( \*STDIN );
        die "unable to resolve the STDIN operating-system handle\n" if !$os_handle;
        ( $imported, $os_handle );
    };
    return if !$peek || !$handle;
    require Time::HiRes;
    my $deadline = Time::HiRes::time() + $timeout_seconds;
    while (1) {
        my $available = Developer::Dashboard::StreamDrain::_windows_pipe_available( $peek, $handle );
        return 1 if !defined $available;    # writer closed: a read returns end-of-file at once
        return 1 if $available > 0;
        return 0 if Time::HiRes::time() >= $deadline;
        Time::HiRes::sleep(0.01);
    }
}

# _stdin_is_tty()
# Wraps the tty test so tests can exercise both answers without a real terminal.
# Input: none.
# Output: true when STDIN is a terminal.
sub _stdin_is_tty {
    return -t STDIN;    ## no critic (InputOutput::ProhibitInteractiveTest)
}

# _select_open_file_matches(%args)
# Resolves the final open-file match list using the older numbered chooser flow.
# Falls back to listing every match without blocking on a read when STDIN is
# neither a real terminal nor already has an answer waiting, so a script or
# CI step whose STDIN is connected but will genuinely never send anything can
# never hang forever - while a deliberately piped answer (the documented,
# tested way to drive this chooser non-interactively) is read exactly as
# before.
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

    return @matches if !_stdin_has_pending_input(5);

    print '> ';

    my $selection = <STDIN>;
    return @matches if !defined $selection;

    chomp $selection;
    my @chosen = _selection_matches(
        choices => $selection,
        matches => \@matches,
    );

    return @chosen if @chosen;
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

    # Collapse whitespace around a range's dash BEFORE splitting on
    # whitespace, so "1 - 5" survives as one "1-5" chunk instead of being
    # torn into "1", "-", "5" by the same /[,\s]+/ split that also has to
    # separate distinct selections (DD-908).
    ( my $normalized = $choices ) =~ s/\s*-\s*/-/g;

    if ( $normalized =~ /^\d+(?:-\d+)?(?:[\s,]+\d+(?:-\d+)?)*$/ ) {
        my @chosen;
        for my $chunk ( grep { $_ ne '' } split /[,\s]+/, $normalized ) {
            if ( $chunk =~ /^(\d+)-(\d+)$/ ) {
                my ( $start, $end ) = ( $1, $2 );
                return if $start < 1 || $end < $start || $end > @$matches;
                push @chosen, @$matches[ $start - 1 .. $end - 1 ];
                next;
            }
            return if $chunk < 1 || $chunk > @$matches;
            push @chosen, $matches->[ $chunk - 1 ];
        }
        return @chosen;
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFileChooser - interactive match chooser and editor selection for d2 of

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFileChooser qw(_default_editor _editor_supports_tabs _select_open_file_matches);

=head1 DESCRIPTION

Extracted from C<Developer::Dashboard::CLI::OpenFile> (DD-918) to keep that
module under this project's 500-line-per-module guideline. Holds the
editor-command resolution, the vim-family tab-flag detection, the
non-interactive-safe STDIN readiness check (DD-915), and the numbered
multi-match chooser prompt itself.

=for comment FULL-POD-DOC START

=head1 PURPOSE

When C<d2 of> resolves more than one matching file and C<--print> was
not given, this module decides how to present the choice (a numbered list),
how to read an answer safely without hanging on a STDIN that will never send
one, how to parse that answer into a selection (single index, comma list, or
range), and which editor command (with which flags) finally opens the
chosen file(s).

=head1 WHY IT EXISTS

C<Developer::Dashboard::CLI::OpenFile> mixed CLI dispatch, this entire
interactive-chooser/editor-selection concern, scope-search ranking, and
Java-source lookup in one file. The chooser has no dependency on the rest of
that file's search logic beyond one small shared helper
(C<_unique_matches>, provided by C<Developer::Dashboard::CLI::OpenFileUtil>),
making it a natural, low-risk seam.

=head1 WHEN TO USE

Use this file when changing how multiple matches are presented or chosen,
how STDIN readiness is detected, how a chooser answer string is parsed
(single index / comma list / range), or which editor flags are added for
which editor.

=head1 HOW TO USE

  use Developer::Dashboard::CLI::OpenFileChooser qw(_default_editor _editor_supports_tabs _select_open_file_matches);

Called by C<Developer::Dashboard::CLI::OpenFile>'s C<run_open_file_command>
once C<_resolve_open_file_matches> has produced more than one candidate and
C<--print> was not requested.

=head1 WHAT USES IT

C<Developer::Dashboard::CLI::OpenFile>, and this module's own coverage
tests.

=head1 EXAMPLES

  my $editor_cmd = _default_editor($explicit_editor_or_undef);
  my @matches = _select_open_file_matches( matches => \@candidates );

=for comment FULL-POD-DOC END

=cut
