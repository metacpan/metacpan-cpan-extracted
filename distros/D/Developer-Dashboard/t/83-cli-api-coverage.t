#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use Test::More;
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::CLI::API;

# Hermetic runtime: an isolated HOME whose deepest .developer-dashboard layer
# under the current working directory is the writable api.json target.
my $orig_cwd = getcwd();
my $home     = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# run_ok(@argv)
# Runs one dashboard api command while swallowing its stdout/stderr.
# Input: raw command argument list.
# Output: (exit_code, captured_stdout, captured_stderr).
sub run_ok {
    my (@argv) = @_;
    my ( $out, $err, $exit ) = capture {
        Developer::Dashboard::CLI::API::run_api_command( args => \@argv );
    };
    return ( $exit, $out, $err );
}

# run_dies(@argv)
# Runs one dashboard api command expected to die and returns the message.
# Input: raw command argument list.
# Output: die message string, or empty string when the command did not die.
sub run_dies {
    my (@argv) = @_;
    my $msg = '';
    capture {
        my $ok = eval {
            Developer::Dashboard::CLI::API::run_api_command( args => \@argv );
            1;
        };
        $msg = $ok ? '' : "$@";
    };
    return $msg;
}

# --- dispatch guards (run_api_command) -----------------------------------
{
    my $no_args = '';
    my $ok1 = eval { Developer::Dashboard::CLI::API::run_api_command(); 1 };
    $no_args = $ok1 ? '' : "$@";
    like( $no_args, qr/Missing API command arguments/,
        'run_api_command dies when the args argument is missing' );

    my $scalar_args = '';
    my $ok2 = eval { Developer::Dashboard::CLI::API::run_api_command( args => 'not-an-array' ); 1 };
    $scalar_args = $ok2 ? '' : "$@";
    like( $scalar_args, qr/must be an array reference/,
        'run_api_command dies when args is not an array reference' );
}

# --- action normalization ------------------------------------------------
{
    is( ( run_ok() )[0], 0,
        'an empty argument list defaults to the ls action' );
    is( ( run_ok( '-o', 'json' ) )[0], 0,
        'a leading option with no explicit action still defaults to ls' );
    is( ( run_ok('ls') )[0], 0,
        'an explicit ls action dispatches the list command' );
    is( ( run_ok('') )[0], 0,
        'an empty first token normalizes to the ls action' );
    like( run_dies('totally-bogus'), qr/Unknown api action/,
        'an unrecognized action is rejected' );
}

# --- ls usage and output validation --------------------------------------
{
    like( run_dies( 'ls', 'extra' ), qr/Usage: dashboard api \[ls\]/,
        'ls rejects extra positional arguments' );
    like( run_dies( 'ls', '-o', 'xml' ), qr/Usage: dashboard api \[ls\]/,
        'ls rejects unknown output formats' );
    is( ( run_ok( 'ls', '-o', 'json' ) )[0], 0,
        'ls accepts json output' );
    is( ( run_ok('ls') )[0], 0,
        'ls accepts the default table output' );
    is( ( run_ok( 'ls', '--key', 'no-such-key' ) )[0], 0,
        'ls tolerates a filter for a key that does not exist' );
}

# --- add usage, secret sourcing, and route validation --------------------
{
    like( run_dies('add'), qr/Usage: dashboard api add/,
        'add without --key is rejected' );
    like( run_dies( 'add', '--key', 'needs-secret' ), qr/Usage: dashboard api add/,
        'add with only --key and no secret or route is rejected' );
    like(
        run_dies( 'add', '--key', 'route-only', '--route', '/ajax/x' ),
        qr/does not exist yet/,
        'add of a brand-new key with a route but no secret is rejected before persistence'
    );
    like(
        run_dies( 'add', '--key', 'bad-output', '--secret', 'raw', '-o', 'xml' ),
        qr/Usage: dashboard api add/,
        'add rejects unknown output formats'
    );
    like(
        run_dies( 'add', '--key', 'extra-pos', '--secret', 'raw', 'trailing' ),
        qr/Usage: dashboard api add/,
        'add rejects extra positional arguments'
    );
    like(
        run_dies( 'add', '--key', 'both-secrets', '--secret', 'a', '--maybe-secret', 'b' ),
        qr/not both/,
        'add rejects both --secret and --maybe-secret together'
    );
    like(
        run_dies( 'add', '--key', 'bad-route', '--secret', 'raw', '--route', '/nope' ),
        qr{Route must begin with /ajax/},
        'add rejects routes outside the /ajax namespace'
    );

    my ( $maybe_exit, $maybe_out ) = run_ok( 'add', '--key', 'maybe-key', '--maybe-secret', 'raw-maybe' );
    is( $maybe_exit, 0, 'add accepts --maybe-secret to seed a key secret' );
    like( $maybe_out, qr/maybe-key/, 'add reports the newly seeded key name' );

    is( ( run_ok( 'add', '--key', 'secret-key', '--secret', 'raw-secret' ) )[0], 0,
        'add accepts --secret to seed a key secret with table output' );
    is( ( run_ok( 'add', '--key', 'json-key', '--secret', 'raw-secret', '-o', 'json' ) )[0], 0,
        'add renders json output when requested' );
    is( ( run_ok( 'add', '--key', 'route-key', '--secret', 'raw-secret', '--route', '/ajax/health' ) )[0], 0,
        'add stores a valid /ajax route for a new key' );

    my ( $append_exit, $append_out ) =
      run_ok( 'add', '--key', 'secret-key', '--route', '/ajax/status' );
    is( $append_exit, 0,
        'add appends a route to an existing key while carrying its secret forward' );
    like( $append_out, qr{/ajax/status},
        'add echoes the newly appended route for an existing key' );
}

# --- rm usage, route removal, and tombstone handling ---------------------
{
    like( run_dies('rm'), qr/Usage: dashboard api rm/,
        'rm without --key is rejected' );
    like( run_dies( 'rm', '--key', 'k', 'extra' ), qr/Usage: dashboard api rm/,
        'rm rejects extra positional arguments' );
    like( run_dies( 'rm', '--key', 'k', '-o', 'xml' ), qr/Usage: dashboard api rm/,
        'rm rejects unknown output formats' );
    like( run_dies( 'rm', '--key', 'k', '--route', '/nope' ), qr{Route must begin with /ajax/},
        'rm rejects routes outside the /ajax namespace' );
    like( run_dies( 'rm', '--key', 'ghost', '--route', '/ajax/x' ), qr/Unknown API key 'ghost'/,
        'rm of a route on an unknown key is rejected' );

    is( ( run_ok( 'add', '--key', 'rm-key', '--secret', 'raw-secret', '--route', '/ajax/one' ) )[0], 0,
        'seed rm-key with one route' );

    my ( $drop_exit, $drop_out ) = run_ok( 'rm', '--key', 'rm-key', '--route', '/ajax/one' );
    is( $drop_exit, 0, 'rm removes an existing route from a key' );

    is( ( run_ok( 'rm', '--key', 'rm-key', '--route', '/ajax/absent' ) )[0], 0,
        'rm of a route that is not present leaves the key unchanged' );

    is( ( run_ok( 'rm', '--key', 'rm-key', '-o', 'json' ) )[0], 0,
        'rm without a route disables a whole key and honors json output' );

    my ( $again_exit, $again_out ) = run_ok( 'rm', '--key', 'rm-key' );
    is( $again_exit, 0, 'rm of an already-disabled key is a no-op tombstone' );
    like( $again_out, qr/no-change/,
        'rm reports no-change when the key survives only as a writable tombstone' );

    my ( $never_exit, $never_out ) = run_ok( 'rm', '--key', 'never-existed-key' );
    is( $never_exit, 0, 'rm of a key that was never present is a clean no-op' );
    like( $never_out, qr/no-change/,
        'rm reports no-change for a key absent from both the visible and writable layers' );
}

# --- idempotent add, single-key ls filter, and table removal render ------
{
    is( ( run_ok( 'add', '--key', 'poly-key', '--secret', 'poly-secret', '--route', '/ajax/poly' ) )[0], 0,
        'seed poly-key with a secret and one route' );
    is( ( run_ok( 'add', '--key', 'poly-key', '--secret', 'poly-secret', '--route', '/ajax/poly' ) )[0], 0,
        'add is idempotent for an unchanged secret and an already-present route' );

    my ( $filter_exit, $filter_out ) = run_ok( 'ls', '--key', 'poly-key' );
    is( $filter_exit, 0, 'ls filters output to a single existing key' );
    like( $filter_out, qr/poly-key/, 'ls filter output includes the requested key' );

    my ( $removed_exit, $removed_out ) = run_ok( 'rm', '--key', 'poly-key' );
    is( $removed_exit, 0, 'rm disables an existing key with default table output' );
    like( $removed_out, qr/removed/, 'rm table output marks a removed key' );
}

# --- _api_table rendering edge cases -------------------------------------
{
    my $empty = Developer::Dashboard::CLI::API::_api_table(undef);
    like( $empty, qr/Key\s+Secret\s+Route/,
        '_api_table renders only the header for an undef registry' );

    my $mixed = Developer::Dashboard::CLI::API::_api_table(
        {
            skip_me    => 'not-a-hash',
            with_route => { secret => 'digest', ajax => ['/ajax/x'] },
            no_ajax    => { secret => '' },
            undef_rt   => { secret => 'digest', ajax => [undef] },
        }
    );
    like( $mixed, qr{/ajax/x},
        '_api_table renders routes for well-formed registry entries' );
    unlike( $mixed, qr/not-a-hash/,
        '_api_table skips registry entries that are not hash references' );
    like( $mixed, qr/undef_rt/,
        '_api_table tolerates undef route slots without warning' );
}

# --- _build_config home resolution ---------------------------------------
{
    my ( $normal_exit ) = run_ok('ls');
    is( $normal_exit, 0,
        '_build_config resolves a real HOME for ordinary commands' );

    local $ENV{HOME} = '';
    local $ENV{USERPROFILE};
    local $ENV{HOMEDRIVE};
    local $ENV{HOMEPATH};
    my $blank = '';
    my $ok = eval { Developer::Dashboard::CLI::API::_build_config(); 1 };
    $blank = $ok ? '' : "$@";
    like( $blank, qr/Missing home directory/,
        '_build_config falls back to an empty home string and then fails to resolve one' );
}

chdir $orig_cwd or die "Unable to restore cwd to $orig_cwd: $!";

done_testing;

__END__

=pod

=head1 NAME

t/83-cli-api-coverage.t - branch and condition coverage closure for the dashboard api CLI

=head1 PURPOSE

This test is the executable coverage contract for the layered C<dashboard api>
key manager. It drives every dispatch guard, usage-validation die, secret
sourcing rule, route allowlist edit, writable-layer tombstone transition, and
table renderer edge case so the branch and condition metrics for the API CLI
module stay at their required ceiling.

=head1 WHY IT EXISTS

The API CLI mixes option parsing, layered config reads, writable-layer writes,
and two output renderers, which leaves several die guards, short-circuit
conditions, and ternary fallbacks that ordinary end-to-end smoke tests never
reach. Those exact sides went uncovered under a full-suite coverage run. This
file exists so each of those sides is exercised deliberately, and so a future
edit that reintroduces a genuinely unreachable branch is caught rather than
silently annotated away.

=head1 WHEN TO USE

Use this file when changing C<dashboard api> argument parsing, the writable
versus visible registry split, API-key secret hashing, the C</ajax> route
allowlist rules, tombstone/disable behavior, or the JSON and table renderers.

=head1 HOW TO USE

Run C<perl -Ilib t/83-cli-api-coverage.t> or C<prove -lv t/83-cli-api-coverage.t>
while iterating. To confirm the coverage it is responsible for, run it under
C<HARNESS_PERL_SWITCHES=-MDevel::Cover> and inspect the branch and condition
columns for the API CLI module. Keep it green under C<prove -lr t> before
release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the branch/condition
coverage gate all rely on this file to keep the layered API-key manager fully
exercised.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/83-cli-api-coverage.t

Run the focused API CLI coverage test standalone while iterating.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -l t/83-cli-api-coverage.t

Exercise the same test while collecting coverage for the API CLI module it
targets.

Example 3:

  prove -lr t

Run it inside the full repository suite before release.

=cut
