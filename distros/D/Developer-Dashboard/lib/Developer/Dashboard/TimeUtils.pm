package Developer::Dashboard::TimeUtils;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';
use POSIX qw(strftime);

our @EXPORT_OK = qw(_now_iso8601);

# _now_iso8601(tz => 'utc'|'local')
# Returns the current timestamp in ISO-8601 form, in either UTC ('Z'
# suffix) or the machine's local time with a numeric timezone offset.
# Input: tz => 'utc' or 'local' (required, no default).
# Output: ISO-8601 timestamp string.
sub _now_iso8601 {
    my (%args) = @_;
    my $tz = $args{tz};
    die "_now_iso8601 requires an explicit tz => 'utc'|'local' parameter\n"
        if !defined $tz;

    if ( $tz eq 'utc' ) {
        return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime() );
    }
    elsif ( $tz eq 'local' ) {
        return strftime( '%Y-%m-%dT%H:%M:%S%z', localtime() );
    }

    die "_now_iso8601: unrecognized tz value '$tz' - expected 'utc' or 'local'\n";
}

1;

__END__

=head1 NAME

Developer::Dashboard::TimeUtils - shared ISO-8601 timestamp helper

=head1 SYNOPSIS

  use Developer::Dashboard::TimeUtils qw(_now_iso8601);
  my $utc_stamp   = _now_iso8601( tz => 'utc' );    # '2026-09-15T16:14:00Z'
  my $local_stamp = _now_iso8601( tz => 'local' );  # '2026-09-15T17:14:00+0100'

=head1 DESCRIPTION

Provides C<_now_iso8601>, the single home for a timestamp helper that used
to be written out seven separate times across
C<Developer::Dashboard::ActionRunner>, C<SessionStore>, C<Housekeeper>,
C<RuntimeManager>, C<Auth>, C<Collector>, and C<CollectorRunner> (DD-894) -
the same "small helper reimplemented per file instead of shared" pattern
this project already fixed in C<Developer::Dashboard::DirEntries> (DD-762)
and C<Developer::Dashboard::TextUtils> (DD-891).

=head1 PURPOSE

Give every module that needs the current timestamp in ISO-8601 form one
canonical implementation to call, in either of the two formats this
project intentionally uses, rather than each maintaining its own private
copy of one or the other that can silently drift.

=head1 WHY IT EXISTS

Five modules (ActionRunner, SessionStore, Housekeeper, RuntimeManager,
Auth) needed a UTC/C<Z>-suffixed timestamp; two (Collector,
CollectorRunner) needed the machine's local time with a numeric offset, so
that collector-status timestamps and log headers line up with cron
scheduling on the same machine across daylight-saving transitions
(documented in C<Developer::Dashboard>'s own POD). The two formats are a
deliberate, permanent split - not a bug (an earlier card, DD-642, wrongly
claimed it was a bug and was correctly discarded) - so this extraction
takes an explicit C<tz> parameter rather than merging the two into one
format.

=head1 WHEN TO USE

Any module in this codebase that needs the current timestamp in ISO-8601
form should C<use> this module rather than writing a private
C<_now_iso8601>, choosing C<tz => 'utc'> or C<tz => 'local'> to match
whichever of the two formats its own output already needs.

=head1 HOW TO USE

  use Developer::Dashboard::TimeUtils qw(_now_iso8601);
  my $stamp = _now_iso8601( tz => 'utc' );      # gmtime, 'Z' suffix
  my $stamp = _now_iso8601( tz => 'local' );    # localtime, numeric offset

Calling without C<tz>, or with any value other than C<'utc'>/C<'local'>,
dies naming C<tz> rather than silently defaulting - a caller must state
which format it needs.

=head1 WHAT USES IT

C<Developer::Dashboard::ActionRunner>, C<SessionStore>, C<Housekeeper>,
C<RuntimeManager>, and C<Auth> (all C<tz => 'utc'>); C<Collector> and
C<CollectorRunner> (both C<tz => 'local'>) - the 7 call sites the DD-894
extraction migrated.

=head1 EXAMPLES

  _now_iso8601( tz => 'utc' )     # '2026-09-15T16:14:00Z'
  _now_iso8601( tz => 'local' )   # '2026-09-15T17:14:00+0100'

=cut
