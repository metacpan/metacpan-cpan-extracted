#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# The CORE::GLOBAL overrides must exist before the modules under test are
# compiled, so the modules' own open/opendir/unlink calls resolve through them.
# Failures are injected only for exact paths registered in %FAIL, which lets the
# I/O error branches run deterministically even when the suite runs as root
# (where chmod-based unreadable files do not actually fail).
our ( %FAIL, %FAIL_UNLINK );

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::unlink = sub (@) {
        my @keep = grep { !$FAIL_UNLINK{$_} } @_;
        return 0 if @keep != @_ && @_ == 1;
        return CORE::unlink(@keep);
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::SeedSync;
use Developer::Dashboard::SessionStore;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

sub write_file {
    my ( $file, $text ) = @_;
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh;
    return $file;
}

# --- SeedSync -------------------------------------------------------------
{
    my $file = write_file( File::Spec->catfile( $home, 'seed.txt' ), "hello\n" );
    local $FAIL{$file} = 1;
    like( eval { Developer::Dashboard::SeedSync::file_matches_content_md5( $file, "hello\n" ); 1 } ? '' : $@,
        qr/Unable to read/, 'file_matches_content_md5 dies when the file cannot be opened' );
}

# --- SessionStore ---------------------------------------------------------
{
    my $store = Developer::Dashboard::SessionStore->new( paths => $paths );
    my $session = $store->create( username => 'alice', role => 'helper' );
    my $id   = $session->{session_id};
    my $file = $store->_session_file($id);
    ok( -f $file, 'session file exists' );
    {
        local $FAIL{$file} = 1;
        ok( !eval { $store->get($id); 1 }, 'get dies when the session file cannot be opened' );
        like( $@, qr/Unable to read/, 'get reports the read failure' );
    }

    my $root = $paths->sessions_root;
    my $expired = File::Spec->catfile( $root, 'expired-one.json' );
    write_file( $expired, json_encode( { session_id => 'expired-one', expires_at => '2000-01-01T00:00:00Z' } ) );
    {
        local $FAIL{$expired} = 1;
        my $removed = $store->sweep_expired;
        ok( -f $expired, 'sweep_expired skips a record it cannot open' );
        is( $removed, 0, 'unreadable record is not counted' );
    }
    {
        local $FAIL_UNLINK{$expired} = 1;
        is( $store->sweep_expired, 0, 'sweep_expired does not count a record whose unlink failed' );
        ok( -f $expired, 'the record is still present' );
    }
    is( $store->sweep_expired( dry_run => 1 ), 1, 'dry_run counts the expired record without unlinking' );
    is( $store->sweep_expired, 1, 'a real sweep removes and counts the expired record' );
}

# --- IndicatorStore -------------------------------------------------------
{
    {
        package Local::Paths;
        sub new { my ( $c, @r ) = @_; return bless { roots => \@r }, $c }
        sub indicators_roots { return @{ $_[0]{roots} } }
    }
    my $missing = File::Spec->catdir( $home, 'no-such-indicators' );
    my $store = Developer::Dashboard::IndicatorStore->new( paths => Local::Paths->new($missing) );
    is_deeply( [ $store->list_indicators ], [], 'list_indicators skips a root that is not a directory' );

    my $real = File::Spec->catdir( $home, 'ind-real' );
    make_path($real);
    $store = Developer::Dashboard::IndicatorStore->new( paths => Local::Paths->new($real) );
    {
        local $FAIL{$real} = 1;
        is_deeply( [ $store->list_indicators ], [], 'list_indicators skips a root whose opendir fails' );
    }

    my $ifile = write_file( File::Spec->catfile( $real, 'x' ), '{}' );
    {
        local $FAIL{$ifile} = 1;
        ok( !eval { $store->_read_indicator_file($ifile); 1 }, '_read_indicator_file dies when open fails' );
        like( $@, qr/Unable to read/, 'read failure message' );
    }

    is(
        $store->_indicator_sort_cmp(
            { name => 'a', managed_by_collector => 1 },
            { name => 'b' },
        ),
        -1,
        'a collector-managed indicator versus a non-collector one falls back to name order',
    );
}

# --- RuntimeManager -------------------------------------------------------
{
    {
        package Local::Runner;
        sub new           { return bless {}, shift }
        sub running_loops { return () }
        sub loop_state    { return {} }
    }
    my $rhome = tempdir( CLEANUP => 1 );
    my $rpaths  = Developer::Dashboard::PathRegistry->new( home => $rhome );
    my $files   = Developer::Dashboard::FileRegistry->new( paths => $rpaths );
    my $config  = Developer::Dashboard::Config->new( files => $files, paths => $rpaths );
    my $manager = Developer::Dashboard::RuntimeManager->new(
        app_builder => sub { return bless {}, 'Local::Server' },
        config      => $config,
        files       => $files,
        paths       => $rpaths,
        runner      => Local::Runner->new,
    );
    make_path( $rpaths->state_root );
    make_path( $rpaths->collectors_root );

    my $pidfile = write_file( File::Spec->catfile( $rpaths->collectors_root, 'foo.pid' ), "123\n" );
    {
        local $FAIL{$pidfile} = 1;
        ok( !eval { $manager->_collector_stop_targets( {} ); 1 }, 'stop targets die on an unreadable collector pidfile' );
        like( $@, qr/Unable to read/, 'pidfile read failure reported' );
    }
    {
        local $FAIL{ $rpaths->collectors_root } = 1;
        ok( !eval { $manager->_collector_stop_fallback_names( {} ); 1 }, 'fallback names die when the collectors root cannot be opened' );
        like( $@, qr/Unable to read/, 'opendir failure reported' );
    }

    my $sup_pid = write_file( $manager->_collector_supervisor_pidfile, "123\n" );
    {
        local $FAIL{$sup_pid} = 1;
        ok( !eval { $manager->_collector_supervisor_running; 1 }, 'supervisor_running dies when pidfile unreadable' );
    }
    my $sup_state = write_file( $manager->_collector_supervisor_statefile, '{}' );
    {
        local $FAIL{$sup_state} = 1;
        ok( !eval { $manager->_collector_supervisor_state; 1 }, 'supervisor_state dies when state file unreadable' );
    }
    my $web_state = write_file( $files->web_state, '{}' );
    {
        local $FAIL{$web_state} = 1;
        ok( !eval { $manager->web_state; 1 }, 'web_state dies when the state file is unreadable' );
    }
    my $log = write_file( $files->resolve_file('dashboard_log'), "line\n" );
    {
        local $FAIL{$log} = 1;
        ok( !eval { $manager->web_log; 1 }, 'web_log dies when the log is unreadable' );
    }
}

done_testing;

__END__

=head1 NAME

t/450-io-failure-paths-coverage.t - I/O failure branches of four stores

=head1 DESCRIPTION

Covers the open, opendir and unlink failure branches of
Developer::Dashboard::SeedSync, SessionStore, IndicatorStore and
RuntimeManager by injecting failures through CORE::GLOBAL overrides for exact
paths, plus the IndicatorStore sort path where only the left indicator is
collector managed and the list_indicators roots that are missing or
unreadable.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: I/O failure branches of four stores.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/450-io-failure-paths-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/450-io-failure-paths-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/450-io-failure-paths-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
