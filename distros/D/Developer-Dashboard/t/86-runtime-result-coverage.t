#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Encode qw(decode);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::XS qw(encode_json);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Runtime::Result;

# Hermetic runtime: everything this module reads comes from %ENV and $0, so pin
# HOME, chdir into an isolated temp tree, and localize each channel env var per
# block so no leaked state can mask the branch under test.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $P = 'Developer::Dashboard::Runtime::Result';

# ---------------------------------------------------------------------------
# current(): decoding contract, non-hash payload rejection.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT};
    delete local $ENV{RESULT_FILE};
    is_deeply( Developer::Dashboard::Runtime::Result::current(), {}, 'current() is an empty hash when no RESULT channel is set' );

    local $ENV{RESULT} = encode_json( { '00-a.pl' => { exit_code => 0 } } );
    is_deeply(
        Developer::Dashboard::Runtime::Result::current(),
        { '00-a.pl' => { exit_code => 0 } },
        'current() decodes inline RESULT JSON into a hash',
    );

    local $ENV{RESULT} = '[1,2]';
    my $err = eval { Developer::Dashboard::Runtime::Result::current(); 1 } ? '' : $@;
    like( $err, qr/RESULT must decode to a hash/, 'current() rejects a non-hash RESULT payload' );
}

# ---------------------------------------------------------------------------
# set_current(): non-hash rejection (line 38 true), empty-hash clear.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT};
    delete local $ENV{RESULT_FILE};
    my $err = eval { Developer::Dashboard::Runtime::Result::set_current( [1,2] ); 1 } ? '' : $@;
    like( $err, qr/RESULT state must be a hash/, 'set_current rejects a non-hash payload' );

    is( Developer::Dashboard::Runtime::Result::set_current( {} ), '', 'set_current clears when given an empty hash' );

    my $mode = Developer::Dashboard::Runtime::Result::set_current( { '00-a.pl' => { exit_code => 0 } } );
    is( $mode, 'inline', 'set_current stores a small payload inline' );
    Developer::Dashboard::Runtime::Result::clear_current();
}

# ---------------------------------------------------------------------------
# last_result(): every calling convention for the class-vs-function shim,
# plus the decode/non-hash paths.
# ---------------------------------------------------------------------------
{
    delete local $ENV{LAST_RESULT};
    delete local $ENV{LAST_RESULT_FILE};
    is( Developer::Dashboard::Runtime::Result::last_result(), undef, 'last_result() returns undef with no channel' );
    is( Developer::Dashboard::Runtime::Result::last_result(undef), undef, 'last_result(undef) tolerates an undef leading argument' );
    is( Developer::Dashboard::Runtime::Result::last_result( [1,2] ), undef, 'last_result(ref) ignores a reference leading argument' );
    is( Developer::Dashboard::Runtime::Result::last_result('other'), undef, 'last_result(string) ignores a non-package leading argument' );
    is( $P->last_result(), undef, 'last_result invoked as a class method strips the package name' );
}
{
    delete local $ENV{LAST_RESULT_FILE};
    local $ENV{LAST_RESULT} = encode_json( { file => 'x' } );
    is_deeply( Developer::Dashboard::Runtime::Result::last_result(), { file => 'x' }, 'last_result decodes a stored previous-hook hash' );

    local $ENV{LAST_RESULT} = '[1,2]';
    my $err = eval { Developer::Dashboard::Runtime::Result::last_result(); 1 } ? '' : $@;
    like( $err, qr/LAST_RESULT must decode to a hash/, 'last_result rejects a non-hash LAST_RESULT payload' );
}

# ---------------------------------------------------------------------------
# set_last_result(): shim conventions and the non-hash / empty-hash paths.
# ---------------------------------------------------------------------------
{
    delete local $ENV{LAST_RESULT};
    delete local $ENV{LAST_RESULT_FILE};

    is( $P->set_last_result( { file => 'y' } ), 'inline', 'set_last_result as a class method stores inline' );

    my $e_none = eval { Developer::Dashboard::Runtime::Result::set_last_result(); 1 } ? '' : $@;
    like( $e_none, qr/LAST_RESULT state must be a hash/, 'set_last_result rejects a missing payload' );

    my $e_undef = eval { Developer::Dashboard::Runtime::Result::set_last_result(undef); 1 } ? '' : $@;
    like( $e_undef, qr/LAST_RESULT state must be a hash/, 'set_last_result rejects an undef payload' );

    my $e_ref = eval { Developer::Dashboard::Runtime::Result::set_last_result( [1,2] ); 1 } ? '' : $@;
    like( $e_ref, qr/LAST_RESULT state must be a hash/, 'set_last_result rejects an array-reference payload' );

    my $e_str = eval { Developer::Dashboard::Runtime::Result::set_last_result('other'); 1 } ? '' : $@;
    like( $e_str, qr/LAST_RESULT state must be a hash/, 'set_last_result rejects a plain-string payload' );

    is( Developer::Dashboard::Runtime::Result::set_last_result( {} ), '', 'set_last_result clears when given an empty hash' );
}

# ---------------------------------------------------------------------------
# clear_last_result(): every shim convention (it ignores @_ otherwise).
# ---------------------------------------------------------------------------
{
    delete local $ENV{LAST_RESULT};
    delete local $ENV{LAST_RESULT_FILE};
    is( Developer::Dashboard::Runtime::Result::clear_last_result(), '', 'clear_last_result() returns empty' );
    is( Developer::Dashboard::Runtime::Result::clear_last_result(undef), '', 'clear_last_result(undef) returns empty' );
    is( Developer::Dashboard::Runtime::Result::clear_last_result( [1,2] ), '', 'clear_last_result(ref) returns empty' );
    is( Developer::Dashboard::Runtime::Result::clear_last_result('other'), '', 'clear_last_result(string) returns empty' );
    is( $P->clear_last_result(), '', 'clear_last_result as a class method returns empty' );
}

# ---------------------------------------------------------------------------
# stop_requested(): shim conventions, scalar vs hash inputs, STDERR/stderr
# precedence, and the empty-hash fall-through.
# ---------------------------------------------------------------------------
{
    is( Developer::Dashboard::Runtime::Result::stop_requested(), 0, 'stop_requested() with no argument is false' );
    is( Developer::Dashboard::Runtime::Result::stop_requested(undef), 0, 'stop_requested(undef) is false' );
    is( Developer::Dashboard::Runtime::Result::stop_requested( [1,2] ), 0, 'stop_requested(ref) is false without the marker' );
    is( Developer::Dashboard::Runtime::Result::stop_requested('plain output'), 0, 'stop_requested(string) is false without the marker' );
    is( $P->stop_requested('[[STOP]] please'), 1, 'stop_requested as a class method detects the marker on a scalar' );

    is( Developer::Dashboard::Runtime::Result::stop_requested( { STDERR => '[[STOP]] now' } ), 1, 'stop_requested reads the upper-case STDERR key' );
    is( Developer::Dashboard::Runtime::Result::stop_requested( { stderr => '[[STOP]] low' } ), 1, 'stop_requested falls back to the lower-case stderr key' );
    is( Developer::Dashboard::Runtime::Result::stop_requested( {} ), 0, 'stop_requested is false for a hash with neither stderr key' );
}

# ---------------------------------------------------------------------------
# has(): undef and empty name short-circuits, plus present/absent lookups.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT_FILE};
    local $ENV{RESULT} = encode_json( { present => { exit_code => 0 } } );
    is( Developer::Dashboard::Runtime::Result::has(undef), 0, 'has(undef) is false' );
    is( Developer::Dashboard::Runtime::Result::has(''), 0, 'has(empty-string) is false' );
    is( Developer::Dashboard::Runtime::Result::has('present'), 1, 'has() finds a stored hook name' );
    is( Developer::Dashboard::Runtime::Result::has('absent'), 0, 'has() rejects an unknown hook name' );
}

# ---------------------------------------------------------------------------
# stdout()/stderr(): entries that are hashes but lack the requested stream.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT_FILE};
    local $ENV{RESULT} = encode_json( { 'x' => {}, 'y' => { stdout => 'out', stderr => 'err' } } );
    is( Developer::Dashboard::Runtime::Result::stdout('x'), '', 'stdout is empty when the entry has no stdout' );
    is( Developer::Dashboard::Runtime::Result::stderr('x'), '', 'stderr is empty when the entry has no stderr' );
    is( Developer::Dashboard::Runtime::Result::stdout('y'), 'out', 'stdout returns the captured stream' );
    is( Developer::Dashboard::Runtime::Result::stderr('y'), 'err', 'stderr returns the captured stream' );
    is( Developer::Dashboard::Runtime::Result::stdout('absent'), '', 'stdout is empty when the hook name is unknown (non-hash entry)' );
    is( Developer::Dashboard::Runtime::Result::stderr('absent'), '', 'stderr is empty when the hook name is unknown (non-hash entry)' );
}

# ---------------------------------------------------------------------------
# report(): shim conventions with no names (early return), then the full
# report with an explicit-command override, the empty-command fallback, and
# all three exit-code icon branches.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT};
    delete local $ENV{RESULT_FILE};
    is( Developer::Dashboard::Runtime::Result::report(), '', 'report() is empty when there are no hook names' );
    is( Developer::Dashboard::Runtime::Result::report( [1,2], 'v' ), '', 'report(ref, ...) skips the shim and is empty with no names' );
    is( Developer::Dashboard::Runtime::Result::report( 'other', 'v' ), '', 'report(string, ...) skips the shim and is empty with no names' );
    is( $P->report(), '', 'report as a class method strips the package and is empty with no names' );
}
{
    delete local $ENV{RESULT_FILE};
    local $ENV{RESULT} = encode_json(
        {
            '00-a.pl' => { exit_code => 0 },
            '10-b.pl' => { exit_code => 1 },
            '20-c.pl' => {},
        }
    );

    my $fallback = decode( 'UTF-8', Developer::Dashboard::Runtime::Result::report( command => '' ) );
    like( $fallback, qr/Run Report/, 'report with an empty command string falls back to the derived command name' );

    my $named = decode( 'UTF-8', Developer::Dashboard::Runtime::Result::report( command => 'MyCmd' ) );
    like( $named, qr/MyCmd Run Report/, 'report uses an explicit command name when supplied' );
    like( $named, qr/\x{2705}\s*00-a\.pl/, 'report marks a zero exit code with the success icon' );
    like( $named, qr/\x{1F6A8}\s*10-b\.pl/, 'report marks a non-zero exit code with the failure icon' );
    like( $named, qr/\x{1F6A8}\s*20-c\.pl/, 'report marks a missing exit code with the failure icon' );

    my $derived = decode( 'UTF-8', Developer::Dashboard::Runtime::Result::report() );
    like( $derived, qr/Run Report/, 'report with no command argument derives the command name from the running script' );
}

# ---------------------------------------------------------------------------
# last_name()/last_entry(): the sorted-last accessors over stored names.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT_FILE};
    local $ENV{RESULT} = encode_json( { '00-a.pl' => { exit_code => 0 }, '99-z.pl' => { exit_code => 2 } } );
    is( Developer::Dashboard::Runtime::Result::last_name(), '99-z.pl', 'last_name returns the highest sorted hook name' );
    is_deeply( Developer::Dashboard::Runtime::Result::last_entry(), { exit_code => 2 }, 'last_entry returns the entry for the last hook name' );
    is( Developer::Dashboard::Runtime::Result::exit_code('99-z.pl'), 2, 'exit_code returns the stored exit code' );
}

# ---------------------------------------------------------------------------
# _max_inline_bytes(): argument and environment override validation, plus the
# fall-through to the conservative default when neither is a valid integer.
# ---------------------------------------------------------------------------
{
    delete local $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX};
    is( Developer::Dashboard::Runtime::Result::_max_inline_bytes( max_inline_bytes => 4096 ), 4096, 'a valid max_inline_bytes argument is honoured' );
    is( Developer::Dashboard::Runtime::Result::_max_inline_bytes( max_inline_bytes => 'abc' ), 65536, 'a non-numeric max_inline_bytes argument falls through to the default' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX} = 2048;
    is( Developer::Dashboard::Runtime::Result::_max_inline_bytes(), 2048, 'a valid inline-max environment override is honoured' );

    local $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX} = 'xyz';
    is( Developer::Dashboard::Runtime::Result::_max_inline_bytes(), 65536, 'a non-numeric inline-max environment override falls through to the default' );
}

# ---------------------------------------------------------------------------
# File-backed channel: force the RESULT_FILE spill path, read it back through
# the inherited descriptor, and release it. This exercises the successful
# fcntl/truncate/seek/close sides of _open_channel_file and _set_channel.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT};
    delete local $ENV{RESULT_FILE};
    my $payload = { big => 'x' x 32 };
    my $mode = Developer::Dashboard::Runtime::Result::set_current( $payload, max_inline_bytes => 0 );
    is( $mode, 'file', 'set_current spills to the file-backed channel when the payload exceeds the inline limit' );
    ok( defined $ENV{RESULT_FILE} && length $ENV{RESULT_FILE}, 'RESULT_FILE names the fd-backed channel path' );
    ok( !defined $ENV{RESULT} || $ENV{RESULT} eq '', 'the inline RESULT env var is cleared while the file channel is active' );

    is_deeply( Developer::Dashboard::Runtime::Result::current(), $payload, 'current() reads the payload back through the file-backed channel' );

    is( Developer::Dashboard::Runtime::Result::clear_current(), '', 'clear_current releases the file-backed channel handle' );
}

# ---------------------------------------------------------------------------
# _channel_json failure and empty-file sides through the file-backed channel.
# ---------------------------------------------------------------------------
{
    delete local $ENV{RESULT};
    local $ENV{RESULT_FILE} = File::Spec->catfile( $home, 'definitely', 'missing', 'result.json' );
    my $err = eval { Developer::Dashboard::Runtime::Result::current(); 1 } ? '' : $@;
    like( $err, qr/Unable to read RESULT file/, 'current() dies when the file-backed channel path cannot be opened' );
}
{
    delete local $ENV{RESULT};
    my $empty = File::Spec->catfile( $home, 'empty-result.json' );
    open my $ef, '>', $empty or die "Unable to create $empty: $!";
    close $ef;
    local $ENV{RESULT_FILE} = $empty;
    is_deeply( Developer::Dashboard::Runtime::Result::current(), {}, 'current() is an empty hash when the file-backed channel is empty' );
}

# ---------------------------------------------------------------------------
# _command_name(): the normalized-separator early returns and the run-wrapper
# parent-directory fall-through.
# ---------------------------------------------------------------------------
{
    local $0 = '/';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'a root slash script path resolves to the default command name' );
}
{
    local $0 = '///';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'a slash-only script path normalizes to the default command name' );
}
{
    local $0 = "\\";
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'a backslash-only script path resolves to the default command name' );
}
{
    local $0 = 'C:';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'a bare drive script path resolves to the default command name' );
}
{
    local $0 = '/opt/tools/run';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'tools', 'a run-wrapper script path falls back to its parent directory name' );
}
{
    delete local $ENV{DEVELOPER_DASHBOARD_COMMAND};
    local $0 = '/run';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'a run wrapper whose parent is the root falls back to the default command name' );
}
{
    delete local $ENV{DEVELOPER_DASHBOARD_COMMAND};
    local $0 = '/\\/run';
    is( Developer::Dashboard::Runtime::Result::_command_name(), 'dashboard', 'a run wrapper whose parent basename is a bare separator falls back to the default command name' );
}

done_testing;

__END__

=head1 NAME

t/86-runtime-result-coverage.t - branch and condition coverage for the hook RESULT runtime helper

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::Runtime::Result>, the helper that decodes, writes,
clears, and reports the per-hook C<RESULT> and C<LAST_RESULT> payloads. It
drives every decode/encode path, the inline-versus-file-backed channel
overflow, the class-method-versus-function calling shim on each public
routine, the C<[[STOP]]> stderr marker contract, and the command-name
derivation used in run reports.

=head1 WHY IT EXISTS

It exists because that module carries several hard-to-reach guards that only
fire on malformed input or the file-backed overflow channel: non-hash
payloads, the class-versus-function argument shim, an empty file-backed
descriptor, and the separator/run-wrapper edge cases of command-name
derivation. Those branches are almost never hit from the CLI or web flows, so
a dedicated test keeps them honest and stops the coverage gate from silently
regressing when the transport format changes.

=head1 WHEN TO USE

Use this file when changing hook result serialization, the inline C<RESULT>
versus file-backed spill rules, the C<LAST_RESULT> handoff, the stop-marker
detection, or the command-name resolution that heads a run report.

=head1 HOW TO USE

Run C<prove -lv t/86-runtime-result-coverage.t> while iterating on the module,
then confirm the branch and condition columns for the module stay at 100
percent under the repository coverage gate before release. Each block localizes
its own channel environment variables, so the assertions can be read and
extended in isolation without leaking state between cases.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep the hook RESULT helper's guard and
overflow branches covered.

=head1 EXAMPLES

Example 1:

  prove -lv t/86-runtime-result-coverage.t

Run the focused coverage test by itself while changing the RESULT helper.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/86-runtime-result-coverage.t

Exercise the same test while collecting coverage for the module it targets.

Example 3:

  prove -lr t

Put the change back through the whole repository suite before calling it done.

=cut
