#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Housekeeper;

# Hermetic runtime.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );

my $paths    = Developer::Dashboard::PathRegistry->new( home => $home );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );

# One already-expired session and one still-valid session.
$sessions->create( username => 'expired-user', ttl_seconds => -1 );
$sessions->create( username => 'valid-user',   ttl_seconds => 3600 );

my $root = $paths->sessions_root;
my @before = glob( File::Spec->catfile( $root, '*.json' ) );
is( scalar @before, 2, 'both session files exist before housekeeping' );

# Regression: the housekeeper must actually reclaim expired session files, not
# leave them to accumulate unbounded between logins.
my $housekeeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
my $result = $housekeeper->run( min_age_seconds => 0 );

is( $result->{scanned}{expired_sessions}, 1, 'housekeeper run sweeps exactly the one expired session' );

my @after = glob( File::Spec->catfile( $root, '*.json' ) );
is( scalar @after, 1, 'only the still-valid session file remains after housekeeping' );

done_testing;

__END__

=pod

=head1 NAME

t/58-hunt-housekeeper-session.t - regression that the housekeeper reclaims expired sessions

=head1 PURPOSE

This test is the executable regression contract for wiring the session store's
expired-session sweep into the housekeeper. It confirms that a housekeeper run
removes expired helper-session files and reports the count, while leaving valid
sessions untouched.

=head1 WHY IT EXISTS

The automated bug-hunt found that expired session files were never garbage
collected: create() writes one file per login and expiry-deletion only happened
if that exact cookie was presented again. A standalone sweep method was added,
but until it is invoked by the housekeeper the leak persists. This test exists so
the sweep stays wired into the periodic housekeeper run and cannot silently
regress back to unbounded growth.

=head1 WHEN TO USE

Use this file when changing the housekeeper's run cycle, the session store's
expiry/sweep behavior, or the session file layout.

=head1 HOW TO USE

Run C<prove -lv t/58-hunt-housekeeper-session.t> while iterating on housekeeper
or session-store changes. Keep it green under C<prove -lr t> before release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate use this
file to keep expired-session reclamation working end to end.

=head1 EXAMPLES

Example 1:

  prove -lv t/58-hunt-housekeeper-session.t

Run the dedicated housekeeper-session-sweep regression check by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
