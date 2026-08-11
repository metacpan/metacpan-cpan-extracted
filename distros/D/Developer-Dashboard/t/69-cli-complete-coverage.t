#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::Complete;

# Hermetic runtime: everything under a private HOME + isolated state root, and
# chdir into HOME so the DD-OOP-LAYERS config root resolves from this tree only.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

# A real workspace root so the workspace/project -d filter in _collector_names
# takes its true side for at least one candidate directory and its false side
# for the others.
make_path( File::Spec->catdir( $home, 'projects' ) );

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector = Developer::Dashboard::Collector->new( paths => $paths );

# Seed layered config collectors so the config->collectors loop inside
# _collector_names sees a nameless job (undef name), an explicitly empty name,
# a name shared with a persisted collector, and a normal named job.
$config->save_global(
    {
        collectors => [
            { command => 'echo unnamed' },
            { name    => '', command => 'echo blank' },
            { name    => 'shared', command => 'echo shared-config' },
            { name    => 'realcol', command => 'echo real' },
        ],
    }
);

# Seed persisted collector status files. The status JSON name field is what the
# list_collectors loop reads, so write the desired names directly.
for my $spec ( [ 'p_empty', '' ], [ 'p_shared', 'shared' ], [ 'p_valid', 'pvalid' ] ) {
    my ( $dir_name, $status_name ) = @{$spec};
    my $status_file = $collector->collector_paths($dir_name)->{status};
    open my $fh, '>:raw', $status_file or die "Unable to write $status_file: $!";
    print {$fh} qq({"name":"$status_name"});
    close $fh;
}

# Stub the tmux-backed ticket-session provider so the ticket completion branch is
# deterministic and never shells out to tmux during coverage.
{
    no warnings 'redefine';
    *Developer::Dashboard::CLI::Complete::_ticket_sessions = sub { return ('stub-session') };
}

sub complete { return Developer::Dashboard::CLI::Complete::complete(@_) }

# --- Top-level completion (index <= 1) ------------------------------------

{
    my @candidates = complete( words => ['dashboard'], index => 1 );
    ok( ( grep { $_ eq 'collector' } @candidates ), 'index 1 with an empty current word lists built-in top-level commands' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'sk' ], index => 1 );
    ok( ( grep { index( $_, 'sk' ) == 0 } @candidates ),
        'index 1 filters top-level candidates by the current prefix' );
    ok( !( grep { index( $_, 'sk' ) != 0 } @candidates ),
        'index 1 drops candidates that do not share the current prefix' );
}

# --- workspace/ticket second word (index 2) -------------------------------

{
    my @candidates = complete( words => [ 'dashboard', 'workspace' ], index => 2 );
    is_deeply(
        \@candidates,
        ['stub-session'],
        'workspace at index 2 falls back to the stubbed ticket-session provider',
    );
}

{
    my @candidates = complete(
        words           => [ 'dashboard', 'ticket' ],
        index           => 2,
        ticket_sessions => sub { return ( 'ta', 'tb' ) },
    );
    is_deeply( \@candidates, [ 'ta', 'tb' ], 'ticket at index 2 uses an injected session provider' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'ticket', 'x' ], index => 3 );
    is_deeply( \@candidates, [], 'ticket regex match with index != 2 falls through to subcommands' );
}

# --- restart/stop collector (index 3) -------------------------------------

{
    my @candidates = complete( words => [ 'dashboard', 'restart', 'collector' ], index => 3 );
    ok( ( grep { $_ eq 'realcol' } @candidates ),
        'restart collector at index 3 lists configured collector names via the real provider' );
    ok( ( grep { $_ eq 'housekeeper' } @candidates ),
        'restart collector completion includes built-in collectors' );
    ok( ( grep { $_ eq 'pvalid' } @candidates ),
        'restart collector completion includes persisted collector names' );
}

{
    my @candidates = complete(
        words           => [ 'dashboard', 'stop', 'collector' ],
        index           => 3,
        collector_names => sub { return ('injected') },
    );
    is_deeply( \@candidates, ['injected'], 'stop collector at index 3 honours an injected collector provider' );
}

{
    my @candidates = complete(
        words           => [ 'dashboard', 'restart', 'collector' ],
        index           => 3,
        collector_names => sub { return ( 'dup', 'dup' ) },
    );
    is_deeply( \@candidates, ['dup'], 'duplicate collector candidates are de-duplicated in the final result' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'restart', 'web' ], index => 2 );
    ok( ( grep { $_ eq 'web' } @candidates ),
        'restart with a non-collector third word and index 2 falls back to restart subcommands' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'stop', 'collector' ], index => 2 );
    ok( ( grep { $_ eq 'collector' } @candidates ),
        'stop collector at index 2 (not 3) falls back to stop subcommands' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'restart' ], index => 2 );
    ok( ( grep { $_ eq 'web' } @candidates ),
        'restart with a missing third word still resolves restart subcommands' );
}

# --- log/logs collector (index 3) -----------------------------------------

{
    my @candidates = complete( words => [ 'dashboard', 'log', 'collector' ], index => 3 );
    ok( ( grep { $_ eq 'realcol' } @candidates ),
        'log collector at index 3 lists configured collector names via the real provider' );
}

{
    my @candidates = complete(
        words           => [ 'dashboard', 'logs', 'collector' ],
        index           => 3,
        collector_names => sub { return ('injected') },
    );
    is_deeply( \@candidates, ['injected'], 'logs collector at index 3 honours an injected collector provider' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'log', 'web' ], index => 2 );
    ok( ( grep { $_ eq 'web' } @candidates ),
        'log with a non-collector third word and index 2 falls back to log subcommands' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'logs', 'collector' ], index => 2 );
    ok( ( grep { $_ eq 'collector' } @candidates ),
        'logs collector at index 2 (not 3) falls back to logs subcommands' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'log' ], index => 2 );
    ok( ( grep { $_ eq 'web' } @candidates ),
        'log with a missing third word still resolves log subcommands' );
}

# --- else branch / static subcommands -------------------------------------

{
    my @candidates = complete( words => [ 'dashboard', 'skills' ], index => 2 );
    ok( ( grep { $_ eq 'install' } @candidates ), 'skills resolves static second-level subcommands' );
}

{
    my @candidates = complete( words => ['dashboard'], index => 2 );
    is_deeply( \@candidates, [], 'a missing second word at index 2 yields no static subcommands' );
}

{
    my @candidates = complete( words => [ 'dashboard', 'zzz' ], index => 2 );
    is_deeply( \@candidates, [], 'an unknown second word yields no static subcommands' );
}

# --- current-word filtering edge cases ------------------------------------

{
    my @candidates = complete( words => [ 'dashboard', 'restart' ], index => 5 );
    ok( ( grep { $_ eq 'collector' } @candidates ),
        'an out-of-range current index leaves every subcommand candidate unfiltered' );
}

# --- persisted status that is not a hash (list_collectors non-hash path) ---

{
    my $arr_home = tempdir( CLEANUP => 1 );
    my $arr_paths = Developer::Dashboard::PathRegistry->new( home => $arr_home );
    my $arr_collector = Developer::Dashboard::Collector->new( paths => $arr_paths );
    my $status_file = $arr_collector->collector_paths('arrentry')->{status};
    open my $fh, '>:raw', $status_file or die "Unable to write $status_file: $!";
    print {$fh} '[1]';
    close $fh;

    local $ENV{HOME} = $arr_home;
    my @candidates = complete( words => [ 'dashboard', 'log', 'collector' ], index => 3 );
    ok( !( grep { ref $_ } @candidates ),
        'a non-hash persisted status is skipped instead of leaking a reference candidate' );
    ok( ( grep { $_ eq 'housekeeper' } @candidates ),
        'the non-hash status path still returns the built-in collector names' );
}

# --- empty HOME fallback (line 101 short-circuit false side) ---------------

{
    my $profile_home = tempdir( CLEANUP => 1 );
    local $ENV{HOME}        = '';
    local $ENV{USERPROFILE} = $profile_home;
    my @candidates = complete( words => [ 'dashboard', 'restart', 'collector' ], index => 3 );
    ok( ( grep { $_ eq 'housekeeper' } @candidates ),
        'an empty HOME falls back through the resolved-home path without dying' );
}

done_testing;

__END__

=pod

=head1 NAME

t/69-cli-complete-coverage.t - branch and condition coverage for the shell-completion candidate builder

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::CLI::Complete>. It drives every dispatch arm of
C<complete()> - top-level candidates, the workspace/ticket session branch, the
restart/stop and log/logs collector branches, the static subcommand fallback,
and the current-word prefix filter - together with the collector-name provider
so both sides of each branch and short-circuit condition actually execute.

=head1 WHY IT EXISTS

It exists because completion dispatch is a dense chain of C<if>/C<elsif>
guards and C<||> default fallbacks whose untaken sides are invisible to the
higher-level CLI smoke tests. The provider fallbacks reach real config and
persisted collector state, including a non-hash status record and an empty-HOME
resolution path, which only a hermetic fixture can exercise safely. Pinning
those paths here keeps the module at full branch and condition coverage and
stops a future edit from silently dropping a dispatch arm.

=head1 WHEN TO USE

Use this file when changing completion dispatch, the exposed second-level
subcommand lists, the collector/ticket provider wiring, or the candidate
de-duplication and prefix-filter behavior.

=head1 HOW TO USE

Run C<prove -lv t/69-cli-complete-coverage.t> while iterating on completion
behavior, and keep it green under C<prove -lr t> and the coverage gate before
release. The fixture sets a private HOME, an isolated state root, and a chdir
into the temp tree so config and collector lookups never touch the developer's
real runtime.

=head1 WHAT USES IT

Developers during TDD, the full repository test suite, and the Devel::Cover
branch/condition gate all rely on this file to keep completion dispatch fully
exercised.

=head1 EXAMPLES

Example 1:

  prove -lv t/69-cli-complete-coverage.t

Run this focused completion coverage test by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/69-cli-complete-coverage.t

Exercise the same test while collecting coverage for the completion module.

Example 3:

  prove -lr t

Put the completion behavior back through the whole repository suite before
release.

=cut
