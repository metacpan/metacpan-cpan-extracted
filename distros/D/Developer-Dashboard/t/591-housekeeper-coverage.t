#!/usr/bin/env perl

use strict;
use warnings;

# CORE::GLOBAL overrides must exist before the module under test is compiled.
# Each one fails only for exact registered paths, so the failure branches run
# for any uid, including root.
our ( %FAIL_OPENDIR, %FAIL_CLOSE, %FAIL_UNLINK, %VANISH_UNLINK );
my %close_handles;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        my $rc = @_ == 2 ? CORE::open( $_[0], $_[1] ) : CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
        if ( $rc && @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_CLOSE{"$_[1]|$_[2]"} ) {
            $close_handles{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $rc;
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $fail = @_ && ref $_[0] && delete $close_handles{ Scalar::Util::refaddr( $_[0] ) };
        my $rc = @_ ? CORE::close( $_[0] ) : CORE::close();
        if ($fail) {
            $! = 5;
            return 0;
        }
        return $rc;
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::unlink = sub (@) {
        my @list = @_;
        if ( @list == 1 && $FAIL_UNLINK{ $list[0] } ) {
            $! = 1;
            return 0;
        }
        if ( @list == 1 && $VANISH_UNLINK{ $list[0] } ) {
            CORE::unlink( $list[0] );
            $! = 2;
            return 0;
        }
        return CORE::unlink(@list);
    };
}

use Test::More;
use Scalar::Util ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Housekeeper;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
my $state = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = $state;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

sub write_file {
    my ( $path, $body ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $body;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# opendir failure on the state base root.
{
    my $base = $paths->state_base_root;
    make_path($base);
    local $FAIL_OPENDIR{$base} = 1;
    my $ok = eval { $keeper->_cleanup_state_roots( min_age_seconds => 0, scanned => {} ); 1 };
    ok( !$ok, 'an unreadable state base root is fatal' );
    like( $@, qr/Unable to read \Q$base\E/, 'the opendir failure names the base root' );
}

# temp-file sweep: unknown kind, failing unlink, vanishing unlink.
{
    my $tmp = tempdir( CLEANUP => 1 );
    my $stranger = write_file( File::Spec->catfile( $tmp, 'unrelated.txt' ), "x\n" );
    my $stuck    = write_file( File::Spec->catfile( $tmp, 'dashboard-result-stuck' ), "x\n" );
    my $gone     = write_file( File::Spec->catfile( $tmp, 'dashboard-result-gone' ), "x\n" );

    no warnings 'redefine';
    local *Developer::Dashboard::Housekeeper::_temp_file_candidates = sub { return ( $stranger, $stuck, $gone ) };
    local $FAIL_UNLINK{$stuck}  = 1;
    local $VANISH_UNLINK{$gone} = 1;

    my $ok = eval { $keeper->_cleanup_temp_files( min_age_seconds => 0, scanned => {} ); 1 };
    ok( !$ok, 'a file that cannot be unlinked and still exists is fatal' );
    like( $@, qr/Unable to remove stale runtime result temp file \Q$stuck\E/, 'the unlink failure names the file' );

    delete $FAIL_UNLINK{$stuck};
    my %scanned;
    my @removed = $keeper->_cleanup_temp_files( min_age_seconds => 0, scanned => \%scanned );
    is( scalar @removed, 1, 'the stuck file is removed once unlink works, and the vanished file is skipped' );
    ok( -e $stranger, 'a file of unknown kind is never touched' );
}

# close failures while reading pid and metadata files.
{
    my $dir = File::Spec->catdir( $state, 'rootx' );
    my $collectors = File::Spec->catdir( $dir, 'collectors' );
    make_path($collectors);
    my $pidfile = write_file( File::Spec->catfile( $collectors, 'probe.pid' ), "99999999\n" );
    local $FAIL_CLOSE{"<|$pidfile"} = 1;
    my $ok = eval { $keeper->_state_root_has_live_collectors($dir); 1 };
    ok( !$ok, 'a close failure while reading a pidfile is fatal' );
    like( $@, qr/Unable to close \Q$pidfile\E/, 'the pidfile close failure names the file' );

    my $meta = write_file( File::Spec->catfile( $dir, 'runtime.json' ), "{}\n" );
    local $FAIL_CLOSE{"<|$meta"} = 1;
    $ok = eval { $keeper->_read_state_metadata($dir); 1 };
    ok( !$ok, 'a close failure while reading runtime metadata is fatal' );
    like( $@, qr/Unable to close \Q$meta\E/, 'the metadata close failure names the file' );
}

# lazy helpers build once and are then reused.
{
    my $fresh = Developer::Dashboard::Housekeeper->new( paths => $paths );
    is( $fresh->_collector_store, $fresh->_collector_store, 'the collector store is built once' );
    is( $fresh->_collector_runner, $fresh->_collector_runner, 'the collector runner is built once' );
    is( $fresh->_config, $fresh->_config, 'the config is built once' );
}

done_testing;

__END__

=pod

=head1 NAME

t/591-housekeeper-coverage.t - covers the I/O failure and lazy-helper branches of Developer::Dashboard::Housekeeper

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces opendir, unlink and close failures through CORE::GLOBAL overrides.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate must be met without any C<# uncoverable> annotation, and these paths can only be reached by injecting failures that work for any uid, including root.

=head1 WHEN TO USE

Use this file when you change Developer::Dashboard::Housekeeper, or when a coverage run reports one of these paths as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/591-housekeeper-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/591-housekeeper-coverage.t

Run this coverage-gap test by itself while editing Developer::Dashboard::Housekeeper.

=cut
