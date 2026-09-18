#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use Developer::Dashboard::IsoTimestamp qw(_iso8601_to_epoch);

# --- Z-suffix parses correctly under both on_error modes -----------------------
{
    is( _iso8601_to_epoch( '2026-09-16T00:00:00Z', on_error => 'die' ), 1789516800,
        '_iso8601_to_epoch parses a Z-suffix timestamp under on_error=>die' );
    is( _iso8601_to_epoch( '2026-09-16T00:00:00Z', on_error => 'zero' ), 1789516800,
        '_iso8601_to_epoch parses a Z-suffix timestamp under on_error=>zero' );
}

# --- compact numeric offset (+HHMM) applies correctly ---------------------------
{
    is( _iso8601_to_epoch( '2026-09-16T00:00:00+0100', on_error => 'die' ), 1789513200,
        '_iso8601_to_epoch applies a positive compact offset' );
}

# --- compact negative offset (-HHMM) applies correctly --------------------------
{
    is( _iso8601_to_epoch( '2026-09-16T00:00:00-0500', on_error => 'die' ), 1789534800,
        '_iso8601_to_epoch applies a negative compact offset' );
}

# --- colon-separated offset (+HH:MM / -HH:MM) applies correctly -----------------
{
    is( _iso8601_to_epoch( '2026-09-16T00:00:00+01:00', on_error => 'die' ), 1789513200,
        '_iso8601_to_epoch applies a positive colon-separated offset' );
    is( _iso8601_to_epoch( '2026-09-16T00:00:00-05:00', on_error => 'die' ), 1789534800,
        '_iso8601_to_epoch applies a negative colon-separated offset' );
}

# --- on_error=>'die': malformed input dies with a descriptive message -----------
{
    eval { _iso8601_to_epoch( 'not-a-timestamp', on_error => 'die' ) };
    like( $@, qr/Unsupported.*timestamp.*not-a-timestamp/, 'on_error=>die: malformed input dies naming the bad value' );
}

# --- on_error=>'die': undef input dies -------------------------------------------
{
    eval { _iso8601_to_epoch( undef, on_error => 'die' ) };
    like( $@, qr/Unsupported.*timestamp/, 'on_error=>die: undef input dies' );
}

# --- on_error=>'zero': malformed input returns 0, never dies --------------------
{
    is( _iso8601_to_epoch( 'not-a-timestamp', on_error => 'zero' ), 0,
        'on_error=>zero: malformed input returns 0' );
}

# --- on_error=>'zero': undef input returns 0, never dies ------------------------
{
    is( _iso8601_to_epoch( undef, on_error => 'zero' ), 0,
        'on_error=>zero: undef input returns 0' );
}

# --- on_error is required, with no silent default -------------------------------
{
    eval { _iso8601_to_epoch('2026-09-16T00:00:00Z') };
    like( $@, qr/requires an explicit on_error/, '_iso8601_to_epoch requires an explicit on_error parameter' );
}

# --- an unrecognized on_error value dies naming the bad value -------------------
{
    eval { _iso8601_to_epoch( '2026-09-16T00:00:00Z', on_error => 'bogus' ) };
    like( $@, qr/unrecognized on_error value 'bogus'/, 'an unrecognized on_error value dies naming it' );
}

done_testing();

__END__

=head1 NAME

t/194-isotimestamp-coverage.t - coverage test for Developer::Dashboard::IsoTimestamp

=head1 PURPOSE

Exercises C<_iso8601_to_epoch>'s full behavior: both accepted timestamp
formats (bare C<Z> suffix, compact and colon-separated numeric offsets)
under both C<on_error> modes, and every error path (missing C<on_error>,
an unrecognized C<on_error> value, and malformed/undef input under each
mode).

=head1 WHY IT EXISTS

DD-904 extracted this parser out of C<Collector.pm> and
C<SessionStore.pm>'s own private, silently-diverging copies. This file is
the coverage gate for the extraction itself, so the shared function
carries its own 100% rather than relying on the two callers' coverage to
exercise it indirectly.

=head1 WHEN TO USE

Run whenever C<IsoTimestamp.pm> changes.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/194-isotimestamp-coverage.t

=head1 WHAT USES IT

Nothing else calls this file; it is invoked by C<prove> directly or as
part of the full suite.

=head1 EXAMPLES

Example 1:

  _iso8601_to_epoch( '2026-09-16T00:00:00Z', on_error => 'die' )

Returns C<1789516800>.

Example 2:

  _iso8601_to_epoch( 'garbage', on_error => 'zero' )

Returns C<0>.

=cut
