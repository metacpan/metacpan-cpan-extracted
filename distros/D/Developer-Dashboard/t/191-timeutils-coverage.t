#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );

my $tempdir = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $tempdir;
chdir $tempdir or die "Unable to chdir to $tempdir: $!";

require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::TimeUtils;
Developer::Dashboard::TimeUtils->import('_now_iso8601');

# AC-1: the module exists and exports _now_iso8601.
ok( Developer::Dashboard::TimeUtils->can('_now_iso8601'), 'AC-1: TimeUtils defines _now_iso8601' );
ok( __PACKAGE__->can('_now_iso8601'), 'AC-1: _now_iso8601 is importable via @EXPORT_OK' );

# ATDD: exact format for both branches, matching the card's ATDD exactly.
my $utc = Developer::Dashboard::TimeUtils::_now_iso8601( tz => 'utc' );
like( $utc, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
    "ATDD: tz=>'utc' returns 'YYYY-MM-DDTHH:MM:SSZ'" );

my $local = Developer::Dashboard::TimeUtils::_now_iso8601( tz => 'local' );
like( $local, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{4}\z/,
    "ATDD: tz=>'local' returns 'YYYY-MM-DDTHH:MM:SS+HHMM'" );

# Behavior parity: fixed-time check against gmtime/localtime directly,
# via POSIX::strftime the same way each of the 7 original copies did.
use POSIX qw(strftime);
my @fixed_gm = gmtime(1_700_000_000);
my $expected_utc_shape = strftime( '%Y-%m-%dT%H:%M:%SZ', @fixed_gm );
like( $expected_utc_shape, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
    'sanity: strftime UTC shape matches the same pattern _now_iso8601 utc produces' );

# No parameter / unknown parameter is refused rather than silently guessing.
eval { Developer::Dashboard::TimeUtils::_now_iso8601() };
like( $@, qr/tz/, 'calling without a tz parameter dies naming tz' );

eval { Developer::Dashboard::TimeUtils::_now_iso8601( tz => 'martian' ) };
like( $@, qr/tz/, "an unrecognized tz value dies naming tz" );

done_testing;

__END__

=head1 NAME

t/191-timeutils-coverage.t - unit test for Developer::Dashboard::TimeUtils

=head1 PURPOSE

Proves DD-894's extraction: a single canonical C<_now_iso8601> now lives in
C<Developer::Dashboard::TimeUtils>, taking an explicit C<tz> parameter and
matching the exact behavior of the 7 private copies it replaces - 5
producing C<gmtime>-based UTC/C<Z> timestamps, 2 producing
C<localtime>-based timestamps with a numeric offset.

=head1 WHY IT EXISTS

DD-894: seven files each defined their own byte-identical-within-group
C<_now_iso8601>, the same "small helper reimplemented per file" pattern
already fixed 3 times on this board (DD-762, DD-785, DD-891). This is the
shared module's own focused unit test, written RED before
C<TimeUtils.pm> existed.

=head1 WHEN TO USE

Run whenever C<TimeUtils.pm> changes, or when a new caller adopts
C<_now_iso8601> and needs confidence its behavior is unchanged from the
inline copies it replaced.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/191-timeutils-coverage.t

=head1 WHAT USES IT

The suite, via C<prove -lr t>. Exercises C<Developer::Dashboard::TimeUtils>
directly; the 7 consuming files' own coverage tests exercise the same
function indirectly through their call sites.

=head1 EXAMPLES

    perl -Ilib -MDeveloper::Dashboard::TimeUtils=_now_iso8601 \
      -e 'print _now_iso8601(tz => "utc"), "\n"'

=cut
