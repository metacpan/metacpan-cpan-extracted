use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::SessionStore;

# Warnings are errors for this repository, so surface any warning as a
# hard failure instead of letting it slip past the harness silently.
$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

# FakePaths is a minimal stand-in for Developer::Dashboard::PathRegistry that
# exposes only the two lookups SessionStore consumes. It lets each test point
# the session store at an isolated temp directory without the full runtime.
# Input: root (write-target session dir) and roots (lookup order array ref).
# Output: object answering sessions_root and sessions_roots.
{
    package FakePaths;
    sub new { my ( $class, %args ) = @_; return bless {%args}, $class; }
    sub sessions_root  { return $_[0]->{root}; }
    sub sessions_roots { return @{ $_[0]->{roots} }; }
}

# write_file($path, $content)
# Writes a fixture file verbatim for the session-store tests.
# Input: absolute file path and byte string content.
# Output: nothing meaningful (dies on failure).
sub write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>:raw', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return;
}

# ---------------------------------------------------------------------------
# Finding 1: the cookie-supplied session id is interpolated into the on-disk
# path with no charset sanitization, so "../secret" escapes the session store.
# ---------------------------------------------------------------------------
{
    my $base = tempdir( CLEANUP => 1 );
    my $root = File::Spec->catdir( $base, 'sessions' );
    make_path($root);

    # A sensitive record that lives OUTSIDE the session store root.
    my $secret = File::Spec->catfile( $base, 'secret.json' );
    write_file( $secret,
        '{"session_id":"secret","username":"root","role":"admin","expires_at":"2099-01-01T00:00:00Z"}'
    );

    my $store = Developer::Dashboard::SessionStore->new(
        paths => FakePaths->new( root => $root, roots => [$root] ) );

    ok( !defined $store->get('../secret'),
        'get() refuses a traversal session id and does not read files outside the store' );
    ok( !defined $store->get('..\\secret'),
        'get() also neutralizes a backslash traversal session id' );

    # delete() must not be able to unlink a file outside the store either.
    my $victim = File::Spec->catfile( $base, 'victim.json' );
    write_file( $victim, '{"session_id":"victim"}' );
    $store->delete('../victim');
    ok( -f $victim,
        'delete() refuses a traversal session id and leaves outside files intact' );
}

# The sanitizer helper itself must tolerate an undef id without warning.
is( Developer::Dashboard::SessionStore::_safe_session_id(undef), '',
    '_safe_session_id maps undef to the empty string' );
is( Developer::Dashboard::SessionStore::_safe_session_id('../../etc/passwd'),
    '.._.._etc_passwd',
    '_safe_session_id strips path separators to a safe single-component name' );

# ---------------------------------------------------------------------------
# Positive control: real sessions (including legacy hyphenated ids) still work.
# ---------------------------------------------------------------------------
{
    my $base = tempdir( CLEANUP => 1 );
    my $root = File::Spec->catdir( $base, 'sessions' );
    make_path($root);
    my $store = Developer::Dashboard::SessionStore->new(
        paths => FakePaths->new( root => $root, roots => [$root] ) );

    my $record = $store->create( username => 'localhelper', role => 'helper' );
    my $loaded = $store->get( $record->{session_id} );
    is( $loaded->{username}, 'localhelper',
        'a freshly created session round-trips through get() after sanitization' );

    # A legacy, non-hex id made only of safe characters must survive unchanged.
    write_file( File::Spec->catfile( $root, 'fallback-session.json' ),
        '{"session_id":"fallback-session","username":"fb","expires_at":"2099-01-01T00:00:00Z"}'
    );
    ok( $store->get('fallback-session'),
        'a legacy hyphenated session id is preserved by the sanitizer' );

    $store->delete( $record->{session_id} );
    ok( !defined $store->get( $record->{session_id} ),
        'delete() removes a legitimately created session' );
}

# ---------------------------------------------------------------------------
# Finding 2: expired session files accumulate forever because create() writes
# one file per login and only from_cookie deletes (and only for the exact
# cookie presented again). sweep_expired() is the reclaim path Housekeeper can
# call.
# ---------------------------------------------------------------------------
{
    my $base = tempdir( CLEANUP => 1 );
    my $root = File::Spec->catdir( $base, 'sessions' );
    make_path($root);
    my $store = Developer::Dashboard::SessionStore->new(
        paths => FakePaths->new( root => $root, roots => [$root] ) );

    my $expired = File::Spec->catfile( $root, 'expired.json' );
    my $valid   = File::Spec->catfile( $root, 'valid.json' );
    my $noexp   = File::Spec->catfile( $root, 'noexpiry.json' );
    my $broken  = File::Spec->catfile( $root, 'broken.json' );
    my $array   = File::Spec->catfile( $root, 'array.json' );
    my $notjson = File::Spec->catfile( $root, 'notes.txt' );

    write_file( $expired,
        '{"session_id":"expired","expires_at":"2000-01-01T00:00:00Z"}' );
    write_file( $valid,
        '{"session_id":"valid","expires_at":"2099-01-01T00:00:00Z"}' );
    write_file( $noexp, '{"session_id":"noexpiry"}' );
    write_file( $broken, '{ this is not json' );
    write_file( $array,  '[1,2,3]' );
    write_file( $notjson, 'not a session file' );

    my $removed = $store->sweep_expired;
    is( $removed, 1, 'sweep_expired removes exactly the one expired session' );
    ok( !-f $expired, 'sweep_expired deleted the expired session file' );
    ok( -f $valid,    'sweep_expired kept the still-valid session file' );
    ok( -f $noexp,    'sweep_expired left a record with no expiry untouched' );
    ok( -f $broken,   'sweep_expired left an unparseable file untouched' );
    ok( -f $array,    'sweep_expired left a non-object json file untouched' );
    ok( -f $notjson,  'sweep_expired ignored a non-json file' );
}

done_testing;

__END__

=head1 NAME

51-hunt-sessionstore.t - security and garbage-collection regression tests for the file-backed session store

=head1 DESCRIPTION

This test pins two defects in Developer::Dashboard::SessionStore: a path
traversal via the cookie-supplied session id, and the unbounded growth of
expired session files on disk.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for two SessionStore defects: an unsanitized session id that let a crafted cookie read or unlink files outside the session store, and the absence of any sweep for expired session files that create() keeps writing one-per-login. It fixes the expected behavior of the sanitizer and of the sweep so a code-only reading cannot regress either guarantee.

=head1 WHY IT EXISTS

It exists because both defects are silent: traversal produces a normal-looking undef-or-not answer, and leaked session files never surface in ordinary flows. Encoding the safe-charset and sweep expectations in a dedicated file makes the TDD loop, the coverage loop, and the release gate concrete instead of relying on manual reasoning about path strings.

=head1 WHEN TO USE

Use this file when changing how SessionStore resolves session file paths, when changing session expiry handling, or when a focused coverage failure points at the sanitizer or the expired-session sweep.

=head1 HOW TO USE

Run it directly with C<prove -lv t/51-hunt-sessionstore.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep the SessionStore path-safety and expiry-sweep behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/51-hunt-sessionstore.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/51-hunt-sessionstore.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
