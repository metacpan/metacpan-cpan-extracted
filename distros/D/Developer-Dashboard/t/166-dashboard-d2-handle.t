#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec ();
use Cwd qw(abs_path getcwd);
use Scalar::Util qw(refaddr);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard;
use Developer::Dashboard::Handle;
use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::PathRegistry;

# Warnings are fatal in this repository: collect any that escape and assert
# the whole run stayed clean.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home. The config root resolves from the
# deepest .developer-dashboard layer above the cwd, so chdir into the temp
# home before building any registry or exercising d2().
my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
my $starting_cwd = getcwd();
chdir $home or die "Unable to chdir to $home: $!";

# AC-1: a built-in alias (one PathRegistry answers with a method of the same
# name) resolves the same way through d2->paths as through resolve_dir
# directly.
{
    my $direct = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    is( d2->paths->{home}, $direct->home, 'AC-1: d2->paths->{home} matches PathRegistry->home directly' );
}

# AC-2: a custom alias added the same way `dashboard path add` does (through
# the real CLI dispatch, so it is genuinely persisted, not a stub) is
# resolvable through d2->paths too.
{
    my ($stdout) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'add', 'reports', '/var/reports-example' ],
        );
    };

    # A fresh handle for a fresh cwd (still $home) must see the alias just
    # persisted - proves d2->paths reads real configured aliases, not a
    # frozen snapshot from before the alias existed.
    my $fresh = Developer::Dashboard::Handle->new( cwd => $home );
    is( $fresh->paths->{reports}, '/var/reports-example',
        'AC-2: a custom alias added via the real path-add command resolves through Handle->paths' );
}

# AC-3: d2() memoizes one handle per working directory - repeated calls from
# the same cwd return the identical object, not a rebuilt one.
{
    my $first  = d2();
    my $second = d2();
    is( refaddr($first), refaddr($second), 'AC-3: d2() returns the same handle object for the same cwd' );
}

# AC-4: accessing a missing alias is a normal hash miss - undef, never a die.
{
    my $missing = eval { d2->paths->{'this-alias-does-not-exist'} };
    is( $@, '', 'AC-4: looking up a missing alias does not die' );
    is( $missing, undef, 'AC-4: and it is undef, exactly like a normal hash miss' );
}

# AC-5/AC-8: a bareword single-word method (AUTOLOAD) shells to the real
# `dashboard <name>` and a nonzero exit dies with stderr attached, rather
# than silently returning as if it had succeeded.
{
    # REWRITTEN FOR Q-101. This used to assert that a bareword call shells out
    # IMMEDIATELY and dies on a nonzero exit. The owner superseded that - "a bare
    # d2->doctor becomes lazy like any other chain ... a shipped one-word form
    # changes meaning" - so building the chain no longer executes and no longer
    # dies. The die-on-nonzero-exit contract is UNCHANGED; it moves to the
    # terminator, which is what is asserted here.
    my $handle = Developer::Dashboard::Handle->new( cwd => $home );
    my $built = eval { $handle->doesnotexistasarealdashboardsubcommand; 1 };
    ok( $built, 'Q-101: building a chain for an unknown subcommand does NOT die - nothing has run yet' );

    my $ran = eval { $handle->doesnotexistasarealdashboardsubcommand->(); 1 };
    ok( !$ran, 'AC-5/AC-8: TERMINATING it fails rather than silently succeeding' );
    like( $@, qr/failed \(exit \d+\)/, 'and the die message names the exit code' );
}

# AC-6/AC-7: Handle->run() drives an arbitrary "dashboard"-named executable
# on PATH (stubbed here so the test does not depend on the real CLI's own
# subcommand set), decoding JSON-shaped stdout and passing through plain
# text, to isolate the run()/AUTOLOAD contract from the real CLI's behavior.
{
    my $bin_dir = tempdir( CLEANUP => 1 );
    my $stub    = File::Spec->catfile( $bin_dir, 'dashboard' );
    open my $fh, '>', $stub or die $!;
    print {$fh} <<'STUB';
#!/bin/sh
case "$1" in
  json-thing) echo '{"alpha":"beta"}' ;;
  text-thing) echo 'plain text output' ;;
  silent-thing) ;;
  fail-thing) echo 'stub failure detail' 1>&2; exit 7 ;;
esac
STUB
    close $fh;
    chmod 0755, $stub;
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $handle = Developer::Dashboard::Handle->new( cwd => $home );

    my $decoded = $handle->run('json-thing');
    is_deeply( $decoded, { alpha => 'beta' }, 'AC-6/AC-7: JSON-shaped stdout decodes to a Perl structure' );

    my $text = $handle->run('text-thing');
    is( $text, 'plain text output', 'AC-7: non-JSON stdout passes through as trimmed text' );

    # Also exercised via the AUTOLOAD path, per AC-5's "single-word method"
    # contract - same stub, different call shape.
    # REWRITTEN FOR Q-107, which reversed what Q-101 left here. This used to
    # assert the method name reached the CLI VERBATIM - underscore, not hyphen -
    # and the owner chose translation instead, because a Perl method name cannot
    # contain a hyphen and hyphenated executables are the normal shell naming.
    #
    # The assertion inverts into something strictly stronger. The stub answers
    # only to `text-thing`, so REACHING it from ->text_thing is positive evidence
    # that the rewrite happened; the old spelling asserted an empty result, which
    # is what you also get when nothing runs at all.
    my $via_autoload = $handle->text_thing->();    # AUTOLOAD -> proxy -> run('text-thing')
    is( $via_autoload, 'plain text output',
        'Q-107: the proxy rewrites _ to - per segment, so ->text_thing reaches the CLI command `text-thing`' );

    # RESTORES A BRANCH THIS CARD ITSELF ORPHANED. run() has an early
    # `return $stdout if $stdout eq ''`, and before Q-107 it was exercised by
    # accident: ->text_thing missed every stub case and produced empty output.
    # Translating _ to - made that call MATCH `text-thing`, so the empty-stdout
    # branch stopped being reached and Devel::Cover reported line 66 at 50%.
    # A case that produces nothing is now named explicitly rather than relying
    # on a miss, which is what made the coverage accidental in the first place.
    my $silent = $handle->run('silent-thing');
    is( $silent, '', 'run() returns empty string when the command prints nothing' );

    my $failed = eval { $handle->run('fail-thing'); 1 };
    ok( !$failed, 'AC-8: a nonzero exit dies' );
    like( $@, qr/stub failure detail/, 'AC-8: and stderr is attached to the die message' );
}

# Coverage: new() with no explicit cwd falls back to Cwd::cwd() - exercises
# the "defined-or fell through" leg that every other test in this file
# avoids by always passing cwd explicitly.
{
    my $handle = Developer::Dashboard::Handle->new;
    is( $handle->{cwd}, getcwd(), 'new() with no cwd falls back to Cwd::cwd()' );
}

# Coverage: run() validates its own subcommand argument - both the "missing
# entirely" and "present but empty" shapes of the guard.
{
    my $handle = Developer::Dashboard::Handle->new( cwd => $home );

    my $ok_undef = eval { $handle->run(undef); 1 };
    ok( !$ok_undef, 'run() with no subcommand dies' );
    like( $@, qr/Missing subcommand/, 'and names the reason' );

    my $ok_empty = eval { $handle->run(''); 1 };
    ok( !$ok_empty, 'run() with an empty-string subcommand dies the same way' );
    like( $@, qr/Missing subcommand/, 'and names the reason' );
}

# Coverage: calling ->paths (and so ->_registry) twice on the SAME handle
# exercises the memoization hit inside _registry's own cache, not just
# paths()'s cache above it.
{
    my $handle = Developer::Dashboard::Handle->new( cwd => $home );
    my $first  = $handle->_registry;
    my $second = $handle->_registry;
    is( refaddr($first), refaddr($second), '_registry() memoizes per handle, not just paths()' );
}

# Coverage: JSON-shaped stdout that decodes successfully but to a non-
# reference scalar (a bare JSON number) must still pass through as text,
# not be mistaken for the decoded-structure case.
{
    my $bin_dir = tempdir( CLEANUP => 1 );
    my $stub    = File::Spec->catfile( $bin_dir, 'dashboard' );
    open my $fh, '>', $stub or die $!;
    print {$fh} <<'STUB';
#!/bin/sh
case "$1" in
  number-thing) echo '42' ;;
esac
STUB
    close $fh;
    chmod 0755, $stub;
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    my $handle = Developer::Dashboard::Handle->new( cwd => $home );
    my $result = $handle->run('number-thing');
    is( $result, '42', 'a JSON number decodes successfully but is not a ref, so it passes through as text' );
}

# Coverage: with no home directory resolvable at all (HOME and every
# Windows-style fallback var absent), _registry's own PathRegistry
# construction has nothing to fall back to and dies - exercising the
# $ENV{HOME} empty leg inside _registry.
{
    local $ENV{HOME} = '';
    local $ENV{USERPROFILE};
    local $ENV{HOMEDRIVE};
    local $ENV{HOMEPATH};
    delete $ENV{USERPROFILE};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};

    my $handle = Developer::Dashboard::Handle->new( cwd => $home );
    my $ok = eval { $handle->paths; 1 };
    ok( !$ok, 'with no resolvable home directory anywhere, paths() dies rather than silently using a wrong root' );
}

chdir $starting_cwd or die "Unable to chdir back to $starting_cwd: $!";

is( scalar(@warnings), 0, 'no warnings escaped: ' . join( '; ', @warnings ) );


# ---------------------------------------------------------------------------
# DD-738: d2() chaining. RED until the proxy exists.
#
# Design settled by the owner across four questions, and the spec asserts the
# SETTLED shape rather than the one this card was filed with:
#   Q-096  proxy-object chaining, arbitrary depth, mirroring dotted CLI dispatch
#   Q-100  ONLY an explicit terminator executes; boolean, numeric and
#          interpolated context are all inert; an un-terminated proxy
#          stringifies to something obviously non-executing
#   Q-101  supersedes the original AC-3: a bare single-word call is a proxy too,
#          with no depth-1 special case
#   Q-104  the terminator is a CALL - d2()->collector->list->() - overloading
#          &{}, chosen because it reserves no word and so cannot collide with a
#          subcommand, which matters when the CLI dispatches arbitrary dotted
#          names including installed skills.
#
# The stub RECORDS ITS ARGV to a file. Inertness is then asserted by an EMPTY
# LOG rather than by the absence of output - a test that checks "nothing was
# printed" passes just as well when the command ran and printed nothing.
# ---------------------------------------------------------------------------
{
    my $bin_dir = tempdir( CLEANUP => 1 );
    my $log     = File::Spec->catfile( $bin_dir, 'invocations' );
    my $stub    = File::Spec->catfile( $bin_dir, 'dashboard' );
    open my $sfh, '>', $stub or die "Unable to write $stub: $!";
    print {$sfh} <<"STUB";
#!/bin/sh
printf '%s\\n' "\$*" >> '$log'
echo 'stub-ran'
STUB
    close $sfh or die "Unable to close $stub: $!";
    chmod 0755, $stub or die "Unable to chmod $stub: $!";
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";

    # purpose: report every argv the stub has been invoked with since the last reset.
    # input: none. output: list of argv strings, oldest first.
    my $invocations = sub {
        return () if !-e $log;
        open my $lfh, '<', $log or die "Unable to read $log: $!";
        my @lines = <$lfh>;
        close $lfh or die "Unable to close $log: $!";
        chomp @lines;
        return @lines;
    };
    # purpose: forget every recorded invocation, so the next assertion speaks
    #          only about what happened after it. input/output: none.
    my $reset = sub { unlink $log if -e $log; return; };

    my $handle = Developer::Dashboard::Handle->new( cwd => $home );

    # AC-1 ARBITRARY DEPTH. Depths 2, 3 and 4 - a fix handling one extra word
    # is a special case, and the owner asked for the general form.
    for my $case ( [ [qw(collector list)], 'collector.list' ],
                   [ [qw(foo bar zzz)],   'foo.bar.zzz' ],
                   [ [qw(foo bar zzz yyy)], 'foo.bar.zzz.yyy' ] ) {
        my ( $words, $dotted ) = @{$case};
        $reset->();
        # eval so a die at the first chained call does not hide the eight
        # assertions after it - a RED spec that stops at its first failure
        # tells you one thing when it could tell you the whole shape.
        eval {
            my $proxy = $handle;
            $proxy = $proxy->$_ for @{$words};
            $proxy->();
            1;
        };
        is_deeply( [ $invocations->() ], [$dotted],
            "AC-1: d2()->" . join( '->', @{$words} ) . "->() invokes exactly `dashboard $dotted`" );
    }

    # Q-107 TRANSLATION, AT EVERY SEGMENT AND EVERY DEPTH. A Perl method name
    # cannot contain a hyphen, so without this the whole hyphenated half of the
    # CLI is unreachable from the chained form. Depth 1 and depth 3 are both
    # exercised because translating only the terminal segment would pass a
    # single-word test and still fail the owner's own example.
    for my $case ( [ [qw(soemthing_executable)],           'soemthing-executable' ],
                   [ [qw(foo bar soemthing_executable)],   'foo.bar.soemthing-executable' ],
                   [ [qw(a_b_c)],                          'a-b-c' ] ) {
        my ( $words, $dotted ) = @{$case};
        $reset->();
        eval {
            my $proxy = $handle;
            $proxy = $proxy->$_ for @{$words};
            $proxy->();
            1;
        };
        is_deeply( [ $invocations->() ], [$dotted],
            "Q-107: d2()->" . join( '->', @{$words} ) . "->() invokes exactly `dashboard $dotted`" );
    }

    # DD-739 NAMED-ARGUMENT TRANSLATION. d2()->somecmd(arg1 => 1) is
    # translation, not execution - hooks already reach the CLI through
    # run()'s own verbatim shell-out; this is purely a nicer way to spell an
    # argument list Perl cannot itself tell apart from two positional
    # strings ('arg1' => 1 and 'arg1', 1 are the same list at runtime, the
    # fat comma is pure syntax). So the only line that CAN be drawn is arity:
    # an EVEN-length arg list is treated as complete key/value pairs and
    # each pair becomes "--$key", $value; an ODD-length list can never be
    # complete pairs and is passed through verbatim as positional args. Zero
    # existing callers use the chained/proxy form with any arguments at all
    # (confirmed: grepped this whole test file and lib/), so this choice
    # breaks nothing that already exists - run() itself is untouched and
    # remains the escape hatch for a command that genuinely needs 2+
    # positional args (its own AC-6/AC-7 block above already covers it).
    for my $case (
        [ [ 'somecmd', [ arg1 => 1 ] ],                    'somecmd --arg1 1' ],
        [ [ 'somecmd', [ arg1 => 1, arg2 => 'x' ] ],        'somecmd --arg1 1 --arg2 x' ],
    ) {
        my ( $spec, $expect ) = @{$case};
        my ( $word, $args ) = @{$spec};
        $reset->();
        eval { $handle->$word(@$args)->(); 1 };
        is_deeply( [ $invocations->() ], [$expect],
            "DD-739: d2()->$word(" . join( ', ', @$args ) . ")->() invokes `dashboard $expect`" );
    }

    # THE TERMINATOR'S OWN ARGS ARE TRANSLATED TOO, not just ones supplied at
    # the bareword call - _execute joins both sources into one list before
    # translating, so d2()->somecmd->(arg1 => 1) is exactly as valid a way
    # to write it as d2()->somecmd(arg1 => 1)->().
    {
        $reset->();
        eval { $handle->somecmd->( arg1 => 1 ); 1 };
        is_deeply( [ $invocations->() ], ['somecmd --arg1 1'],
            'DD-739: named args supplied at the terminator call are translated too' );
    }

    # A SINGLE POSITIONAL ARG (odd length) IS NEVER TOUCHED - it cannot be a
    # complete set of pairs, so it must be a genuine positional argument.
    {
        $reset->();
        eval { $handle->somecmd('onlyone')->(); 1 };
        is_deeply( [ $invocations->() ], ['somecmd onlyone'],
            'DD-739: a lone (odd-count) argument is passed through as positional, never translated' );
    }

    # The inert stringification shows what WOULD run, not what was typed. A
    # proxy printed while debugging is worse than useless if it names a command
    # that does not exist - the reader would go looking for soemthing_executable.
    {
        $reset->();
        my $translated = eval { $handle->foo->soemthing_executable };
        is( ( defined $translated ? "$translated" : '(the chain died)' ),
            'd2 proxy: foo.soemthing-executable',
            'Q-107: an un-terminated proxy stringifies with the TRANSLATED segments' );
        is_deeply( [ $invocations->() ], [],
            'Q-107: and stringifying the translated proxy still executes nothing' );
    }

    # AC-2 NO ACCIDENTAL EXECUTION. Each context is exercised against a proxy
    # that is never terminated, and the log must stay EMPTY.
    {
        $reset->();
        eval { my $proxy = $handle->collector->list; my $t = $proxy ? 1 : 0; 1 };
        is_deeply( [ $invocations->() ], [], 'AC-2: boolean context does not execute' );

        $reset->();
        eval { my $p2 = $handle->collector->list; my $n = 0 + $p2; 1 };
        is_deeply( [ $invocations->() ], [], 'AC-2: numeric context does not execute' );

        $reset->();
        my $p3 = eval { $handle->collector->list };
        eval { my $str = "interpolated: $p3"; 1 };
        is_deeply( [ $invocations->() ], [], 'AC-2: interpolation does not execute' );

        # AC-7 (Q-100): and the string it interpolates to must be obviously
        # non-executing. Asserted as TEXT, not merely as "did not execute" -
        # Perl autogenerates a missing stringify from numify, so a silently
        # generated form would satisfy a weaker assertion.
        is( ( defined $p3 ? "$p3" : '(the chain died)' ), 'd2 proxy: collector.list',
            'AC-7: an un-terminated proxy stringifies to "d2 proxy: collector.list"' );
    }

    # AC-3 SUPERSEDED BY Q-101: a bare single-word call is a proxy like any
    # other chain, with no depth-1 special case.
    {
        $reset->();
        my $one = eval { $handle->doctor };
        is_deeply( [ $invocations->() ], [], 'Q-101: a bare single-word call does NOT execute' );
        is( ( defined $one ? "$one" : '(undef)' ), 'd2 proxy: doctor',
            'Q-101: and stringifies as a proxy at depth 1 too' );
        $reset->();
        eval { $one->(); 1 };
        is_deeply( [ $invocations->() ], ['doctor'], 'Q-101: terminating it invokes `dashboard doctor`' );
    }

    # AC-4 run() UNCHANGED - the documented bypass other code depends on.
    {
        $reset->();
        my $out = $handle->run( 'collector', 'list' );
        is_deeply( [ $invocations->() ], ['collector list'],
            'AC-4: run() still passes its words as SEPARATE argv, not dotted' );
        is( $out, 'stub-ran', 'AC-4: and still returns the trimmed stdout' );
    }

    # AC-6 HOOKS STILL RUN. Asserted here by its MECHANISM, which is the thing a
    # refactor could actually lose (the main-gate block near the end of this file
    # asserts the consequence directly, with a real layered runtime). Layered pre-run hooks execute because
    # Handle::run shells out through the real `dashboard` entrypoint; anything
    # that reaches the CLI that way gets them for free. So what has to hold is
    # that the proxy terminator goes through run() and inherits its WHOLE
    # contract, rather than growing its own system() call that would bypass the
    # entrypoint and silently lose hooks with every test still green.
    #
    # Two properties only run() provides are asserted here. If a refactor made
    # _execute shell out directly, both would break loudly.
    {
        my $json_dir = tempdir( CLEANUP => 1 );
        my $js = File::Spec->catfile( $json_dir, 'dashboard' );
        open my $jfh, '>', $js or die "Unable to write $js: $!";
        print {$jfh} <<'JSTUB';
#!/bin/sh
case "$1" in
  deep.json) echo '{"via":"proxy"}' ;;
  deep.fail) echo 'proxy failure detail' 1>&2; exit 9 ;;
esac
JSTUB
        close $jfh or die "Unable to close $js: $!";
        chmod 0755, $js or die "Unable to chmod $js: $!";
        local $ENV{PATH} = "$json_dir:$ENV{PATH}";
        my $h = Developer::Dashboard::Handle->new( cwd => $home );

        is_deeply( $h->deep->json->(), { via => 'proxy' },
            'AC-6: the terminator inherits run() JSON decoding - so it reaches the real entrypoint, which is what makes layered hooks run' );

        my $died = eval { $h->deep->fail->(); 1 };
        ok( !$died, 'AC-6: and inherits run() die-on-nonzero-exit' );
        like( $@, qr/proxy failure detail/, 'AC-6: with stderr attached, exactly as run() does' );
    }

    # AC-5 DESTROY STILL GUARDED: a proxy that goes out of scope un-terminated
    # invokes nothing. Without the guard, DESTROY is just another bareword.
    {
        $reset->();
        eval { my $doomed = $handle->collector->list; 1 };
        is_deeply( [ $invocations->() ], [],
            'AC-5: a proxy going out of scope un-terminated invokes nothing' );
    }
}

# DESTROY IS EXERCISED WITH TIMELY DESTRUCTION, not by waiting for the
# interpreter to shut down. A proxy left to global destruction did run DESTROY,
# but Devel::Cover recorded the sub at count 0 - so the suite claimed AC-5 while
# the line it depends on was never measured as executed. Dropping the last
# reference inside a scope calls DESTROY immediately, where it is both observable
# and countable.
#
# The assertion here is deliberately about the SIDE EFFECT, not the return value:
# DESTROY returns nothing by design, so the only thing worth proving is that
# destruction invokes no command. The proof that the line RAN is the coverage
# count, which the gate checks separately.
{
    my $home   = tempdir( CLEANUP => 1 );
    my $handle = Developer::Dashboard::Handle->new( cwd => $home );

    my $proxy = $handle->collector->list;
    ok( ref($proxy), 'a chain builds a proxy before destruction' );

    undef $proxy;    # last reference dropped -> DESTROY runs HERE, not at exit
    is( $proxy, undef, 'AC-5: dropping the last reference destroys the proxy in scope' );
}

# DD-810 AC-2/AC-6 - THE MAIN GATE IS INHERITED THROUGH THE HANDLE, asserted
# DIRECTLY this time. The AC-6 block above proves the mechanism (run() reaches
# the real entrypoint); this block proves the consequence with a real layered
# runtime: a `dashboard` on PATH that execs the checkout's own bin/dashboard, a
# main-gate hook under <home>/.developer-dashboard/hooks/, and a marker file the
# hook appends its argv to. Handle::run('version') must fire that hook exactly
# once, with the full command argv, and the command must still answer.
#
# The marker is a FILE, not stdout: main-gate hook output is streamed through the
# entrypoint's own stdout, which run() captures and returns, so asserting on it
# would couple this test to the streaming plumbing rather than to the gate.
{
    my $marker = File::Spec->catfile( $home, 'main-gate-handle.log' );
    my $hooks  = File::Spec->catdir( $home, '.developer-dashboard', 'hooks' );
    require File::Path;
    File::Path::make_path($hooks);
    my $hook = File::Spec->catfile( $hooks, '10-handle-marker' );
    open my $hfh, '>', $hook or die "Unable to write $hook: $!";
    print {$hfh} "#!/bin/sh\nprintf '%s\\n' \"\$*\" >> '$marker'\n";
    close $hfh or die "Unable to close $hook: $!";
    chmod 0755, $hook or die "Unable to chmod $hook: $!";

    my $real_dir   = tempdir( CLEANUP => 1 );
    my $real       = File::Spec->catfile( $real_dir, 'dashboard' );
    my $entrypoint = File::Spec->catfile( $starting_cwd, 'bin', 'dashboard' );
    my $lib        = File::Spec->catdir( $starting_cwd, 'lib' );
    open my $rfh, '>', $real or die "Unable to write $real: $!";
    print {$rfh} "#!/bin/sh\nexec '$^X' -I'$lib' '$entrypoint' \"\$@\"\n";
    close $rfh or die "Unable to close $real: $!";
    chmod 0755, $real or die "Unable to chmod $real: $!";
    local $ENV{PATH} = "$real_dir:$ENV{PATH}";

    my $h   = Developer::Dashboard::Handle->new( cwd => $home );
    my $out = $h->run('version');
    like( $out, qr/\d+\.\d+/, 'DD-810: the command still answers after the main gate ran' );

    my @marker_lines;
    if ( open my $mfh, '<', $marker ) {
        chomp( @marker_lines = <$mfh> );
        close $mfh;
    }
    # DD-835 (reverses DD-832): the hook's argv is the full command line as
    # typed - "version" is prepended, not stripped.
    is_deeply( \@marker_lines, ['version'],
        'DD-810 AC-2/AC-6: Handle::run inherits the main gate through the real entrypoint - the hook fired exactly once with argv matching what the user typed' );
}

done_testing;

__END__

=head1 NAME

t/166-dashboard-d2-handle.t - spec for the exported d2() Perl-code proxy

=head1 PURPOSE

Assert that C<d2()>, exported by L<Developer::Dashboard>, gives Perl code a
one-line equivalent of the C<dashboard>/C<d2> command line, both for the
fast in-process path-alias case and for the general subcommand proxy.

=head1 WHY IT EXISTS

DD-726: the project owner asked directly (over the project's Telegram
bridge) for C<< d2->paths->{foo} >> instead of hand-building a
PathRegistry/FileRegistry/Config, then widened the request to "anything I
can run with d2 on bash" - so both the fast path-alias accessor and the
general subcommand proxy (C<run()>/C<AUTOLOAD>) need their own coverage.

=head1 WHEN TO USE

Whenever C<Developer::Dashboard::d2>, C<Developer::Dashboard::Handle::paths>,
or C<Developer::Dashboard::Handle::run>/C<AUTOLOAD> changes.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/166-dashboard-d2-handle.t

=head1 WHAT USES IT

Nothing in the shipped CLI itself uses C<d2()> - it is a convenience
entrypoint for external Perl code embedding this distribution.

=head1 EXAMPLES

The assertion that matters reads as the property it protects:

    d2->paths->{name} matches what `dashboard path resolve name` prints

=cut
