#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# The CORE::GLOBAL overrides must exist before the modules under test are
# compiled so their own open/opendir/unlink calls resolve through them.
# Failures are injected only for exact registered paths, which keeps the I/O
# error branches deterministic even when the suite runs as root.
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

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Collector;
use Developer::Dashboard::Housekeeper;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

sub write_file {
    my ( $file, $text ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($file);
    make_path($dir);
    CORE::open( my $fh, '>', $file ) or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh;
    return $file;
}

# --- Collector ------------------------------------------------------------
my $collector = Developer::Dashboard::Collector->new( paths => $paths );

{
    my ($job_file) = $collector->_collector_file_candidates( 'iofail', 'job.json' );
    write_file( $job_file, '{"name":"iofail"}' );
    local $FAIL{$job_file} = 1;
    my $ok = eval { $collector->read_job('iofail'); 1 };
    ok( !$ok && $@ =~ qr/Unable to read/, 'read_job dies when an existing job file cannot be opened' );
}

{
    my ($status_file) = $collector->_collector_file_candidates( 'iofail', 'status.json' );
    write_file( $status_file, '{"name":"iofail"}' );
    local $FAIL{$status_file} = 1;
    my $ok = eval { $collector->_read_status_file($status_file); 1 };
    ok( !$ok && $@ =~ qr/Unable to read/, '_read_status_file dies when an existing status file cannot be opened' );
}

{
    $collector->write_result( 'lister', exit_code => 0, stdout => "x\n" );
    my ($root) = $paths->collectors_roots;
    local $FAIL{$root} = 1;
    my @items = eval { $collector->list_collectors };
    is( $@, '', 'list_collectors skips a collectors root that cannot be opened' );
}

# --- Housekeeper ----------------------------------------------------------
my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

{
    my $tmp = tempdir( CLEANUP => 1 );
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $tmp };

        local $FAIL{$tmp} = 1;
        my $ok = eval { $keeper->_temp_file_candidates; 1 };
        ok( !$ok && $@ =~ qr/Unable to read temp directory/, '_temp_file_candidates dies when the temp directory cannot be opened' );
    }

    for my $spec ( [ 'developer-dashboard-ajax-iofail', 'Ajax temp file' ], [ 'dashboard-result-iofail', 'runtime result temp file' ] ) {
        my ( $name, $label ) = @$spec;
        my $file = write_file( File::Spec->catfile( $tmp, $name ), 'stale' );
        utime time - 7200, time - 7200, $file or die "Unable to age $file: $!";
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $tmp };
        local $FAIL_UNLINK{$file} = 1;
        my $ok = eval { $keeper->_cleanup_temp_files( min_age_seconds => 0, scanned => {} ); 1 };
        ok( !$ok && $@ =~ qr/Unable to remove stale \Q$label\E/, "_cleanup_temp_files dies with the $label label when unlink fails" );
        unlink $file;
    }
}

{
    my $state = tempdir( CLEANUP => 1 );
    my $collectors = File::Spec->catdir( $state, 'collectors' );
    make_path($collectors);

    {
        local $FAIL{$collectors} = 1;
        my $ok = eval { $keeper->_state_root_has_live_collectors($state); 1 };
        ok( !$ok && $@ =~ qr/Unable to read/, '_state_root_has_live_collectors dies when the collectors directory cannot be opened' );
    }

    my $pidfile = write_file( File::Spec->catfile( $collectors, 'x.pid' ), "1\n" );
    {
        local $FAIL{$pidfile} = 1;
        my $ok = eval { $keeper->_state_root_has_live_collectors($state); 1 };
        ok( !$ok && $@ =~ qr/Unable to read/, '_state_root_has_live_collectors dies when a pidfile cannot be opened' );
    }

    my $meta = write_file( File::Spec->catfile( $state, 'runtime.json' ), '{}' );
    local $FAIL{$meta} = 1;
    my $ok = eval { $keeper->_read_state_metadata($state); 1 };
    ok( !$ok && $@ =~ qr/Unable to read/, '_read_state_metadata dies when runtime.json cannot be opened' );
}

done_testing;

__END__

=head1 NAME

t/360-collector-housekeeper-coverage.t - I/O failure coverage for Collector and Housekeeper

=head1 DESCRIPTION

Uses CORE::GLOBAL open/opendir/unlink overrides to inject deterministic I/O
failures into Developer::Dashboard::Collector (read_job, _read_status_file,
list_collectors) and Developer::Dashboard::Housekeeper (temp directory scan,
stale temp-file removal, collector pidfile scan, state metadata read).

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: I/O failure coverage for Collector and Housekeeper.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/360-collector-housekeeper-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/360-collector-housekeeper-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/360-collector-housekeeper-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
