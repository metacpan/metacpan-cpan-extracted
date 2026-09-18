package Developer::Dashboard::IsoTimestamp;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';
use Time::Local qw(timegm);

our @EXPORT_OK = qw(_iso8601_to_epoch);

# _iso8601_to_epoch($text, on_error => 'die'|'zero')
# Converts an ISO-8601 timestamp (bare 'Z' suffix or a numeric timezone
# offset) into UTC epoch seconds.
# Input: timestamp string (or undef); on_error => 'die' or 'zero'
#        (required, no default) naming what to do on unparseable input.
# Output: UTC epoch integer, or dies (on_error=>'die') / returns 0
#         (on_error=>'zero') when $text does not match the expected shape.
sub _iso8601_to_epoch {
    my ( $text, %args ) = @_;
    my $on_error = $args{on_error};
    die "_iso8601_to_epoch requires an explicit on_error => 'die'|'zero' parameter\n"
        if !defined $on_error;
    die "_iso8601_to_epoch: unrecognized on_error value '$on_error' - expected 'die' or 'zero'\n"
        if $on_error ne 'die' && $on_error ne 'zero';

    my ( $year, $month, $day, $hour, $minute, $second, $zone ) =
        defined $text
        ? $text =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-]\d{4}|[+-]\d{2}:\d{2})\z/
        : ();

    if ( !defined $zone ) {
        return 0 if $on_error eq 'zero';
        my $shown = defined $text ? $text : '(undef)';
        die "Unsupported ISO-8601 timestamp $shown\n";
    }

    my $offset_seconds = 0;
    if ( $zone ne 'Z' ) {
        my ( $sign, $offset_hour, $offset_minute ) = $zone =~ /\A([+-])(\d{2}):?(\d{2})\z/;
        $offset_seconds = ( $offset_hour * 3600 ) + ( $offset_minute * 60 );
        $offset_seconds *= -1 if $sign eq '-';
    }

    return timegm( $second, $minute, $hour, $day, $month - 1, $year ) - $offset_seconds;
}

1;

__END__

=head1 NAME

Developer::Dashboard::IsoTimestamp - shared ISO-8601-to-epoch parser

=head1 SYNOPSIS

  use Developer::Dashboard::IsoTimestamp qw(_iso8601_to_epoch);
  my $epoch = _iso8601_to_epoch( '2026-09-16T00:00:00Z', on_error => 'die' );
  my $epoch = _iso8601_to_epoch( $maybe_bad, on_error => 'zero' );

=head1 DESCRIPTION

Provides C<_iso8601_to_epoch>, the single home for a timestamp-parsing
helper that used to be written out twice across
C<Developer::Dashboard::Collector> and C<Developer::Dashboard::SessionStore>
(DD-904) - the same "small helper reimplemented per file instead of
shared" pattern this project already fixed in
C<Developer::Dashboard::DirEntries> (DD-762),
C<Developer::Dashboard::TextUtils> (DD-891),
C<Developer::Dashboard::TimeUtils> (DD-894), and others.

=head1 PURPOSE

Give every module that needs to convert an ISO-8601 timestamp string into
UTC epoch seconds one canonical implementation to call, supporting the
union of both format surfaces this project's timestamps actually use
(bare C<Z> suffix and a numeric timezone offset), rather than each
maintaining its own private copy that can silently drift.

=head1 WHY IT EXISTS

C<Collector.pm> needed the full timezone grammar (C<Z>, compact and
colon-separated offsets) and dies on anything else, because a malformed
timestamp in its own self-generated collector log format indicates real
corruption that should be loud. C<SessionStore.pm> needed only the C<Z>
form and silently returned C<0> on anything else - not a bug, but DD-764's
deliberate, documented fail-closed session-expiry behavior: a missing or
malformed C<expires_at> must be treated as already-expired, never as
"never expires". Both call sites relying on that C<0> (the cookie-based
expiry check and the housekeeper's stale-session cleanup sweep) depend on
it exactly as written.

This is the same "explicit parameter, not a collapsed default" shape as
C<TimeUtils.pm>'s C<tz> parameter, applied to an error-handling contract
rather than an output format: C<on_error> is required with no default, so
every caller states which behavior it needs rather than inheriting
whichever caller's convention got extracted first.

=head1 WHEN TO USE

Any module in this codebase that needs to convert an ISO-8601 timestamp
string to epoch seconds should C<use> this module rather than writing a
private C<_iso8601_to_epoch>, choosing C<on_error => 'die'> when an
unparseable timestamp indicates a real defect worth failing loudly on, or
C<on_error => 'zero'> when the caller specifically wants a fail-closed
"treat as already expired / always in the past" default.

=head1 HOW TO USE

  use Developer::Dashboard::IsoTimestamp qw(_iso8601_to_epoch);
  my $epoch = _iso8601_to_epoch( $text, on_error => 'die' );   # dies on bad input
  my $epoch = _iso8601_to_epoch( $text, on_error => 'zero' );  # returns 0 on bad input

Calling without C<on_error>, or with any value other than
C<'die'>/C<'zero'>, dies naming C<on_error> rather than silently
defaulting - a caller must state which contract it needs.

=head1 WHAT USES IT

C<Developer::Dashboard::Collector> (C<on_error => 'die'>, via its
C<_entry_timestamp_epoch> instance-method wrapper);
C<Developer::Dashboard::SessionStore> (C<on_error => 'zero'>, at its
C<from_cookie> expiry check and its housekeeping cleanup sweep) - the 2
call sites the DD-904 extraction migrated.

=head1 EXAMPLES

  _iso8601_to_epoch( '2026-09-16T00:00:00Z', on_error => 'die' )        # 1789516800
  _iso8601_to_epoch( '2026-09-16T00:00:00+0100', on_error => 'die' )    # 1789513200
  _iso8601_to_epoch( 'garbage', on_error => 'zero' )                    # 0
  _iso8601_to_epoch( 'garbage', on_error => 'die' )                     # dies

=cut
