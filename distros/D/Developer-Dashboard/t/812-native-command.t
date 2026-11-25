#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use FindBin;

use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use Local::NativeCommand qw(run_shell_command parse_posix_command);

# WHY THIS FILE EXISTS
#   t/05-cli-smoke.t used to launch every command through
#   `system 'sh', '-c', $cmd`. The Windows Sandbox has no sh or bash, so
#   every one of those calls failed there. Local::NativeCommand gives the
#   suite a shell-independent runner: sh on Unix, a small parser plus
#   direct process launch on Windows. The Windows path cannot run on a
#   Unix CI host, so this file exercises it through the force_windows
#   option and compares the result against a real `sh -c` run, so a
#   regression in the parser shows up on Linux too. On a host with no sh
#   at all (the Windows Sandbox), the comparison cases skip cleanly
#   instead of failing with misleading exit-255 results; the die-tests
#   below never invoke sh and still run everywhere.
#
# Purpose: verify the Windows runner matches sh for every command shape
# the suite uses, and that unsupported constructs die loudly.
# Input:   command strings in the forms t/05 uses
# Output:  Test::More assertions

my $perl = $^X;
my $tmp  = tempdir( CLEANUP => 1 );
my $json = File::Spec->catfile( $tmp, 'data.json' );
open my $json_fh, '>', $json or die "Unable to write $json: $!";
print {$json_fh} "{\"alpha\":{\"beta\":2}}\n";
close $json_fh or die "Unable to close $json: $!";

# Whether a real `sh` exists to compare against. Probed at runtime rather
# than by platform, so a Windows host with sh (for example via Git for
# Windows) still runs the comparisons, and a Unix host without sh skips
# them instead of failing.
my $SH_AVAILABLE = system( 'sh', '-c', 'exit 0' ) == 0;

sub _sh_run {
    my ($cmd) = @_;
    my ( $out, $err, $exit ) = capture { system 'sh', '-c', $cmd; return $? >> 8; };
    return ( $out, $err, $exit );
}

sub _is_same_as_sh {
    my ( $label, $cmd ) = @_;
    SKIP: {
        skip 'sh is not available', 3 unless $SH_AVAILABLE;
        my ( $want_out, $want_err, $want_exit ) = _sh_run($cmd);
        my ( $got_out, $got_err, $got_exit ) = run_shell_command( $cmd, { force_windows => 1 } );
        is( $got_out,  $want_out,  "$label: stdout matches sh" );
        is( $got_err,  $want_err,  "$label: stderr matches sh" );
        is( $got_exit, $want_exit, "$label: exit code matches sh" );
    }
}

# Plain commands and quoting.
_is_same_as_sh( 'plain perl -e', qq{'$perl' -e 'print "hi\\n"'} );
_is_same_as_sh( 'perl -I and single-quoted argv', qq{'$perl' -I'$tmp' -e 'print \$ARGV[0], "\\n"' 'hello world'} );
_is_same_as_sh( 'double-quoted argv with space', qq{'$perl' -e 'print \$ARGV[0], "\\n"' "hello world"} );

# cd && chains.
_is_same_as_sh( 'cd && perl getcwd', qq{cd '$tmp' && '$perl' -e 'use Cwd; print getcwd(), "\\n"'} );
{
    # sh reports a failed cd with its own message and exit 2; the native
    # runner reports the same failure (a missing directory, chain stops)
    # with its own message and exit 1. No test asserts the sh wording.
    my ( $out, $err, $exit ) = run_shell_command( qq{cd '/definitely/not/here-xyz' && '$perl' -e 'print "no\\n"'}, { force_windows => 1 } );
    is( $out, '', 'cd to a missing directory produces no stdout' );
    is( $exit, 1, 'cd to a missing directory stops the chain with exit 1' );
    like( $err, qr/cd: \/definitely\/not\/here-xyz: No such file or directory/, 'cd to a missing directory names the directory' );
}

# Environment prefixes.
_is_same_as_sh( 'env prefix FOO', qq{FOO='bar' '$perl' -e 'print \$ENV{FOO}, "\\n"'} );
_is_same_as_sh( 'env prefix HOME', qq{HOME='$tmp' '$perl' -e 'print \$ENV{HOME}, "\\n"'} );
_is_same_as_sh( 'two env prefixes', qq{FOO='a' BAR='b' '$perl' -e 'print "\$ENV{FOO}\$ENV{BAR}\\n"'} );
{
    my ( $out, undef, $exit ) = run_shell_command( qq{PATH='/fake/bin':"\$PATH" '$perl' -e 'print \$ENV{PATH}, "\\n"'}, { force_windows => 1 } );
    is( $out, "/fake/bin;$ENV{PATH}\n", 'PATH prefix translates a bare : to ; on Windows' );
    is( $exit, 0, 'PATH prefix command succeeds' );
    my $plan = parse_posix_command( qq{PATH='/fake/bin':"\$PATH" '$perl' -e 'x'}, { windows => 1 } );
    is( $plan->{steps}[0]{stages}[0]{env}{PATH}, "/fake/bin;$ENV{PATH}", 'parser translates the PATH separator on Windows' );
    my $plan_unix = parse_posix_command( qq{PATH='/fake/bin':"\$PATH" '$perl' -e 'x'}, { windows => 0 } );
    is( $plan_unix->{steps}[0]{stages}[0]{env}{PATH}, "/fake/bin:$ENV{PATH}", 'parser keeps the PATH separator on Unix' );
    my $plan_quoted = parse_posix_command( qq{PATH='/fake/bin:/other' '$perl' -e 'x'}, { windows => 1 } );
    is( $plan_quoted->{steps}[0]{stages}[0]{env}{PATH}, '/fake/bin:/other', 'parser leaves a colon inside single quotes alone on Windows' );
}

# Pipes: printf and cat pipe sources.
_is_same_as_sh( 'printf json | perl reads stdin', qq{printf '{"alpha":{"beta":2}}' | '$perl' -e 'local \$/; print <STDIN>'} );
_is_same_as_sh( 'printf with newline | perl', qq{printf '2\\n' | '$perl' -e 'print <STDIN>'} );
_is_same_as_sh( 'printf empty | perl', qq{printf '' | '$perl' -e 'print "got:", <STDIN>, "\\n"'} );
_is_same_as_sh( 'cat file | perl', qq{cat '$json' | '$perl' -e 'local \$/; print <STDIN>'} );
_is_same_as_sh( 'cat missing | perl still runs', qq{cat '$tmp/nope.json' | '$perl' -e 'print "ran\\n"'} );
_is_same_as_sh( 'printf | perl | perl (two pipes)', qq{printf 'a\\nb\\n' | '$perl' -pe 's/a/A/' | '$perl' -e 'local \$/; print <STDIN>'} );

# Input redirect: <file feeds the command's stdin.
_is_same_as_sh( 'input redirect feeds stdin', qq{'$perl' -e 'local \$/; print <STDIN>' < '$json'} );
_is_same_as_sh( 'input redirect without a space', qq{'$perl' -e 'local \$/; print <STDIN>' <'$json'} );
_is_same_as_sh( 'input redirect in a cd chain', qq{cd '$tmp' && '$perl' -e 'local \$/; print <STDIN>' < '$json'} );
_is_same_as_sh( 'input redirect overrides piped stdin', qq{printf 'pipe\\n' | '$perl' -e 'local \$/; print <STDIN>' < '$json'} );
{
    # sh fails a missing input file with its own message and exit code;
    # the native runner fails the same command with its own message and
    # exit 1. No test asserts the sh wording.
    my ( $out, $err, $exit ) = run_shell_command( qq{'$perl' -e 'local \$/; print <STDIN>' < '$tmp/nope.json'}, { force_windows => 1 } );
    is( $out, '', 'input redirect from a missing file produces no stdout' );
    is( $exit, 1, 'input redirect from a missing file fails with exit 1' );
    like( $err, qr/cannot read stdin file/, 'input redirect from a missing file names the problem' );
}
{
    # The redirect file belongs to the caller: running a command with
    # `<file` must not delete it (the runner only unlinks temp files it
    # wrote from piped input).
    run_shell_command( qq{'$perl' -e 'local \$/; print <STDIN>' < '$json'}, { force_windows => 1 } );
    ok( -f $json, 'input redirect leaves the input file in place' );
    open my $check_fh, '<', $json or die "Unable to read $json: $!";
    my $content = do { local $/; <$check_fh> };
    close $check_fh;
    is( $content, "{\"alpha\":{\"beta\":2}}\n", 'input redirect leaves the input file contents intact' );
}

# && chains, exits and redirects.
_is_same_as_sh( 'redirect >/dev/null mid-chain', qq{'$perl' -e 'print "quiet\\n"' >/dev/null && '$perl' -e 'print "after\\n"'} );
_is_same_as_sh( 'non-zero exit stops the chain', qq{'$perl' -e 'exit 3' && '$perl' -e 'print "no\\n"'} );
_is_same_as_sh( 'exit code 3 passes through', qq{'$perl' -e 'exit 3'} );
_is_same_as_sh( 'exit code 1 passes through', qq{'$perl' -e 'exit 1'} );
_is_same_as_sh( 'stderr kept separate', qq{'$perl' -e 'print STDERR "err\\n"; print "out\\n"'} );
_is_same_as_sh( 'stderr discarded 2>/dev/null', qq{'$perl' -e 'print STDERR "err\\n"; print "out\\n"' 2>/dev/null} );
# The merge appends the captured stderr after stdout. Perl buffers a
# piped STDOUT, so without autoflush sh's interleaving depends on flush
# timing and the two can never match byte-for-byte; autoflush makes the
# write order deterministic (and equal to the runner's concat order).
_is_same_as_sh( 'stderr merged into stdout', qq{'$perl' -e '\$| = 1; print "out\\n"; print STDERR "err\\n"' 2>&1} );
_is_same_as_sh( 'stdout discarded, stderr kept', qq{'$perl' -e 'print STDERR "err\\n"; print "out\\n"' >/dev/null} );
_is_same_as_sh( 'stdout and stderr discarded', qq{'$perl' -e 'print STDERR "err\\n"; print "out\\n"' >/dev/null 2>&1} );
# A mid-pipeline >/dev/null starves the next stage, in sh and here: the
# redirect wins over the pipe, so the next stage reads empty stdin.
# Forwarding the discarded output instead would diverge from sh.
_is_same_as_sh( 'mid-pipeline stdout discard starves the next stage', qq{printf 'hello\\n' >/dev/null | '$perl' -e 'local \$/; print <STDIN>'} );
_is_same_as_sh( 'mid-pipeline stdout discard, real stage', qq{'$perl' -e 'print "data\\n"' >/dev/null | '$perl' -e 'local \$/; print <STDIN>'} );

# An empty pipeline returns a defined zero exit: the parser dies on an
# empty stage, so this is defensive, but the return must never be undef.
{
    my ( $out, $err, $exit ) = Local::NativeCommand::_execute_pipeline( [], undef, {} );
    is( $out, '', 'empty pipeline returns no stdout' );
    is( $err, '', 'empty pipeline returns no stderr' );
    is( $exit, 0, 'empty pipeline returns exit 0' );
}

# Environment option overrides.
{
    local $ENV{DD_NATIVE_COMMAND_TEST} = 'ambient';
    my ( $out, undef, $exit ) = run_shell_command( qq{'$perl' -e 'print \$ENV{DD_NATIVE_COMMAND_TEST} // "undef", "\\n"'},
        { force_windows => 1, env => { DD_NATIVE_COMMAND_TEST => 'override' } } );
    is( $out, "override\n", 'env option overrides the ambient value' );
    is( $exit, 0, 'env option override command succeeds' );
    my ( $out_deleted, undef, $exit_deleted ) = run_shell_command( qq{'$perl' -e 'print \$ENV{DD_NATIVE_COMMAND_TEST} // "undef", "\\n"'},
        { force_windows => 1, env => { DD_NATIVE_COMMAND_TEST => undef } } );
    is( $out_deleted, "undef\n", 'env option undef deletes the key' );
    is( $exit_deleted, 0, 'env option delete command succeeds' );
    my ( $out_kept, undef, $exit_kept ) = run_shell_command( qq{'$perl' -e 'print \$ENV{DD_NATIVE_COMMAND_TEST} // "undef", "\\n"'}, { force_windows => 1 } );
    is( $out_kept, "ambient\n", 'no env option keeps the ambient value' );
    is( $exit_kept, 0, 'no env option command succeeds' );
}

# Windows-only behaviour: a bare backslash is literal, not an escape.
{
    my ( $out, undef, $exit ) = run_shell_command( qq{'$perl' -e 'print \$ARGV[0], "\\n"' C:\\temp\\file.txt}, { force_windows => 1 } );
    is( $out, "C:\\temp\\file.txt\n", 'a bare Windows path keeps its backslashes' );
    is( $exit, 0, 'a bare Windows path command succeeds' );
}

# getcwd() fails when the working directory has been deleted: the runner
# must die loudly naming the cause instead of restoring to HOME.
SKIP: {
    my $safe_cwd = getcwd();
    my $gone = tempdir( CLEANUP => 1 );
    my $deleted = ( chdir $gone && rmdir $gone ) ? 1 : 0;
    chdir $safe_cwd or die "Unable to restore working directory: $!" unless $deleted;
    skip 'cannot delete the working directory on this platform', 2 unless $deleted;
    my $died = eval { run_shell_command( qq{printf 'x' | '$perl' -e 'print <STDIN>'}, { force_windows => 1 } ); 1 } ? 0 : 1;
    my $err = $@;
    ok( $died, 'dies when the working directory has been deleted' );
    like( $err, qr/cannot determine current working directory/, 'deleted-cwd failure names the cause' );
    # Restore after the assertions: they only inspect the captured
    # values, so a failing restore must not stop them running. (A die
    # here still fails the file loudly — nothing is lost silently.)
    chdir $safe_cwd or die "Unable to restore working directory: $!";
}

# A die while writing the stdin temp file must not orphan it: the file
# is created with UNLINK => 0, so the name is recorded before the write
# and unlinked on failure. The tempfile call is stubbed to return a
# closed handle, which makes the write die.
{
    no warnings 'redefine';
    my $leak_path;
    local *Local::NativeCommand::tempfile = sub {
        my ( $fh, $name ) = File::Temp::tempfile( UNLINK => 0 );
        close $fh;
        $leak_path = $name;
        open my $dead, '<', $name or die "cannot reopen $name: $!";
        close $dead;
        return ( $dead, $name );
    };
    # The stubbed handle is closed by design, so the binmode/print on it
    # warn as expected; silence those warnings here, they are the point
    # of the stub, not a failure.
    local $SIG{__WARN__} = sub { };
    my $died = eval { run_shell_command( qq{printf 'x\\n' | '$perl' -e 'print <STDIN>'}, { force_windows => 1 } ); 1 } ? 0 : 1;
    ok( $died, 'dies when the stdin temp file cannot be written' );
    ok( !-e $leak_path, 'a failed stdin temp-file write leaves no orphan file' );
}

# The _gate_run shape: cd && HOME=... perl entrypoint args.
_is_same_as_sh( 'gate-run shape', qq{cd '$tmp' && HOME='$tmp' '$perl' -I'$tmp' -e 'print join(",", \@ARGV), "\\n"' one two} );

# Unsupported constructs must die loudly, never guess.
for my $case (
    [ 'bash -lc',              qq{bash -lc 'echo hi'} ],
    [ 'sh -c',                 qq{sh -c 'echo hi'} ],
    [ 'semicolon',             qq{'$perl' -e 'print "a"'; '$perl' -e 'print "b"'} ],
    [ 'or operator',           qq{'$perl' -e 'exit 1' || '$perl' -e 'print "b"'} ],
    [ 'command substitution',  qq{'$perl' -e 'print "x"' \$(echo hi)} ],
    [ 'backticks',             qq{'$perl' -e 'print "x"' `echo hi`} ],
    [ 'redirect to a file',    qq{'$perl' -e 'print "x"' > $tmp/out.txt} ],
    [ 'append redirect',       qq{'$perl' -e 'print "x"' >> $tmp/out.txt} ],
    [ 'heredoc',               qq{'$perl' -e 'print <STDIN>' << EOF} ],
    [ 'stderr-fd input redirect', qq{'$perl' -e 'print <STDIN>' 2< '$json'} ],
    [ 'unterminated quote',    qq{'$perl' -e 'print "x} ],
    [ 'command -v',            qq{command -v '$perl'} ],
  )
{
    my ( $label, $cmd ) = @{$case};
    my $died = eval { run_shell_command( $cmd, { force_windows => 1 } ); 1 } ? 0 : 1;
    ok( $died, "dies on unsupported construct: $label" );
}

done_testing;

__END__

=head1 NAME

t/812-native-command.t - regression coverage for the shell-independent test command runner

=head1 PURPOSE

Prove that Local::NativeCommand behaves identically on the Unix path
(C<sh -c>) and the Windows path (the C<force_windows> parser plus direct
launch), and that it dies loudly on constructs it does not support.

=head1 WHY IT EXISTS

The runner is the only thing letting t/05 launch commands on the Windows
Sandbox, where no sh exists. A quiet regression in its parser would re-break
the whole CLI smoke file on Windows while the suite stayed green on Linux,
so the behaviour is pinned here case by case instead of being left to the
larger smoke file to catch.

=head1 WHEN TO USE

When changing Local::NativeCommand.pm, or when adding a shell fragment to a
test that must run on Windows: extend the cases here first, so the new
construct is covered before the test that needs it starts relying on it.

=head1 HOW TO USE

Run C<prove -Iblib/lib -Iblib/arch t/812-native-command.t> from the built
tree. Each case runs the same fragment through real C<sh -c> and through
C<force_windows> and compares stdout, stderr and exit code; the die cases
assert the Windows path refuses the construct instead of guessing at it.
On a host with no C<sh>, the comparison cases skip cleanly and the die
cases still run.

=head1 WHAT USES IT

Nothing loads this file at runtime. It is run by the test harness (prove or
the full suite) as part of the suite, and it exists to guard
Local::NativeCommand, which t/05-cli-smoke.t relies on for every command it
launches.

=head1 EXAMPLES

Compare a chain through both paths:

    my ($sh_out, $sh_err, $sh_rc) = run_shell_command($cmd, {});
    my ($win_out, $win_err, $win_rc) = run_shell_command($cmd, { force_windows => 1 });
    is($win_out, $sh_out, 'Windows path matches sh output');
    is($win_rc, $sh_rc, 'Windows path matches sh exit code');

Assert an unsupported construct dies instead of guessing:

    my $died = eval { run_shell_command('a; b', { force_windows => 1 } ); 1 } ? 0 : 1;
    ok($died, 'dies on unsupported construct: semicolon');

=cut
