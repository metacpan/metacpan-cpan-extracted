#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;

# Resolve the module's own path BEFORE the chdir below. %INC holds it as loaded,
# which is relative to the checkout, and the source assertion at the end of this
# file would otherwise look for it inside the temporary home and quietly skip.
my $MODULE_SOURCE = File::Spec->rel2abs( $INC{'Developer/Dashboard/SessionStore.pm'} );

# Hermetic runtime rooted in a throwaway HOME. The session store resolves its
# state root from the deepest .developer-dashboard layer above the working
# directory, so the test chdirs into the temp home before constructing anything.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::SessionStore->new( paths => $paths );

# --- the id must not be a function of predictable inputs ----------------
#
# CVE-2026-13577 describes Dancer2 deriving a session id from built-in rand()
# plus low-entropy material. This application never uses Dancer2's session
# factory, but it had reimplemented exactly that construction for its own helper
# logins: sha256_hex($$, time, rand(), $username, $role). Every term but rand()
# is attacker-observable - the username and role are known, the second is known,
# the pid is a small space - and rand() is drand48 seeded with 32 bits.
#
# Seeding the generator identically is what makes the weakness visible: under
# the old construction two sessions created in the same process, in the same
# second, after the same srand seed came out byte-identical. A CSPRNG does not
# consult the seeded generator at all, so this is the assertion that cannot be
# satisfied by any rand()-derived id.
{
    srand(42);
    my $first = $store->create( username => 'helper', role => 'helper' );
    srand(42);
    my $second = $store->create( username => 'helper', role => 'helper' );

    isnt( $first->{session_id}, $second->{session_id},
        'two sessions created in the same second after the same srand seed have different ids' );
}

# The same property stated the other way round: re-seeding must not make the
# sequence replayable across a batch either.
{
    my @first_run;
    srand(1234);
    push @first_run, $store->create( username => 'helper', role => 'helper' )->{session_id} for 1 .. 3;

    my @second_run;
    srand(1234);
    push @second_run, $store->create( username => 'helper', role => 'helper' )->{session_id} for 1 .. 3;

    my @overlap = grep {
        my $id = $_;
        grep { $_ eq $id } @second_run
    } @first_run;

    is_deeply( \@overlap, [], 'a re-seeded generator does not replay any previously issued session id' );
}

# --- the id must not be derivable from the record's own contents --------
#
# If the id can be recomputed from material that ships inside the session record
# or is visible to any caller, storing it protects nothing.
{
    my $session = $store->create( username => 'helper', role => 'helper' );
    my $id      = $session->{session_id};

    require Digest::SHA;
    for my $guess (
        Digest::SHA::sha256_hex( join ':', $$, time, 'helper', 'helper' ),
        Digest::SHA::sha256_hex( join ':', $$, $session->{created_at}, 'helper', 'helper' ),
        Digest::SHA::sha256_hex( join ':', 'helper', 'helper' ),
      )
    {
        isnt( $id, $guess, 'the session id is not a plain digest of pid, time, username and role' );
    }
}

# --- shape and uniqueness ----------------------------------------------
{
    my %seen;
    my $collisions = 0;
    for ( 1 .. 200 ) {
        my $id = $store->create( username => 'helper', role => 'helper' )->{session_id};
        $collisions++ if $seen{$id}++;
        like( $id, qr/\A[0-9a-f]{64}\z/, 'the session id is 64 lower-case hex characters' ) if $_ == 1;
    }
    is( $collisions, 0, '200 session ids issued back to back contain no collision' );
}

# --- the weak construction must not be reachable from the source --------
#
# The behavioural assertions above would still pass on a build where a fallback
# path existed but was not taken during this run. The advisory is specifically
# about a SILENT fallback, so the source itself is pinned: nothing in the module
# may derive a session id from rand().
{
    # An installed distribution has the module too, so this reads the file that
    # was actually loaded rather than a checkout-relative guess.
    ok( -f $MODULE_SOURCE, 'the loaded session store module can be read back' );

    open my $fh, '<', $MODULE_SOURCE or die "Unable to read $MODULE_SOURCE: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    like( $source, qr/Crypt::URandom/, 'the session store draws its id from a CSPRNG' );

    # Strip comments and POD before asserting. The claim is about what the module
    # EXECUTES, and the explanation of why rand() was removed necessarily names
    # it - a check that cannot tell code from prose fails on its own rationale.
    my $code = $source;
    $code =~ s/^=\w+.*?^=cut\s*$//gmsx;
    $code =~ s/^__END__.*\z//msx;
    $code =~ s/(?<!\$)#.*$//gm;

    unlike( $code, qr/\brand\s*\(/, 'the session store never calls rand()' );
}

done_testing();

__END__

=head1 NAME

143-session-id-entropy.t - pin helper session ids to a CSPRNG

=head1 PURPOSE

Prove that a helper session id cannot be predicted: that it is not a function of
the process id, the wall-clock second, the username, the role, or Perl's built-in
C<rand>, and that the module issuing it draws from a cryptographically secure
source with no fallback.

=head1 WHY IT EXISTS

CVE-2026-13577 describes Dancer2 falling back to a session id derived from the
built-in C<rand> when its CSPRNG modules are absent. Auditing that advisory showed
this application never uses Dancer2's session factory at all - and had
independently reimplemented the same construction for its own helper logins,
hashing the process id, the wall-clock second, C<rand()>, the username and the
role.

Only C<rand()> contributed anything an attacker does not already know, and
C<rand()> is C<drand48> seeded with thirty-two bits. Holding the pid and the second
fixed, two ids generated after the same C<srand> seed came out byte-identical.
These are the sessions that admit a helper to the web interface.

=head1 WHEN TO USE

Run it whenever anything touches session issuance, the session store, or the
project's dependency floors. It is part of the ordinary suite and needs no special
environment.

=head1 HOW TO USE

    prove -lv t/143-session-id-entropy.t

It is hermetic: it roots a throwaway HOME, changes into it, and leaves nothing
behind. The module path is resolved before that chdir, so the structural
assertions read the file that was actually loaded rather than a checkout-relative
guess.

=head1 WHAT USES IT

The full suite via C<prove -lr t>, the all-metric coverage gate, and the CI
workflow that runs both. Nothing else consumes it.

=head1 EXAMPLES

Behavioural, that seeding the built-in generator identically does not make the
issued ids repeat:

    srand(42); my $first  = $store->create( username => 'helper', role => 'helper' );
    srand(42); my $second = $store->create( username => 'helper', role => 'helper' );
    isnt( $first->{session_id}, $second->{session_id}, '...' );

Structural, that the weak path is not merely untaken but absent. Comments and POD
are stripped before the assertion, because a check that cannot tell code from prose
fails on its own rationale - this one did, against the very fix it was written to
protect:

    unlike( $code,   qr/rand/,           'the session store never calls it' );
    like(   $source, qr/Crypt::URandom/, 'the session store draws from a CSPRNG' );

The structural half is not redundant. The advisory is about a I<silent> fallback,
and a behavioural test only ever proves something about the path taken during the
run.

=cut
