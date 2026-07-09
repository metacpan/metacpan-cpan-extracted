#!perl

use strict;
use warnings;

use Test::More;
use Time::HiRes qw(time);
use HTTP::Date  qw(str2time parse_date);

# Regression test: parse_date must not exhibit catastrophic (quadratic)
# backtracking on hostile input.  A valid-looking date prefix followed by a
# long interior run of digits, letters, or whitespace and a trailing junk
# character used to force the parsing regex to explore O(N^2) states, so a
# ~40 KB string burned tens of seconds of CPU -- a denial of service.
# parse_date now rejects input longer than the cap below, up front, so such
# strings are handled instantly.

# The length cap parse_date enforces.  It is hardcoded in HTTP::Date (a
# security limit, not a knob), so mirror the value here; keep the two in sync.
my $LIMIT = 64;

subtest 'length guard rejects over-long input' => sub {
    my $good = 'Wed, 09 Feb 1994 22:23:32 GMT';
    ok( defined parse_date($good), 'a normal date parses' );

    # Padding a date that parses fine on its own pushes it past the limit and
    # it is rejected -- a deterministic proof the guard fires, no timing needed.
    my $padded = $good . ( q{ } x $LIMIT );
    cmp_ok(
        length $padded, '>', $LIMIT,
        'padded string exceeds the length limit'
    );
    is( parse_date($padded), undef, 'parse_date rejects over-length input' );
    is( str2time($padded), undef, 'str2time rejects over-length input too' );
};

subtest 'length guard boundary is exactly the cap' => sub {

    # The check is "> $LIMIT", so a string of exactly the limit is still
    # considered and one character longer is rejected.  Guards against a future
    # off-by-one turning the cap into >= (which would reject a legal boundary).
    my $limit = $LIMIT;

    my $at_limit = 'Wed, 09 Feb 1994 22:23:32 GMT';
    $at_limit .= q{ } x ( $limit - length $at_limit );   # pad up to the limit
    is( length $at_limit, $limit, "test string is exactly $limit bytes" );
    ok( defined parse_date($at_limit), 'input at the limit is still parsed' );

    my $over_limit = $at_limit . q{ };                   # one byte too long
    is( length $over_limit, $limit + 1, "test string is $limit + 1 bytes" );
    is( parse_date($over_limit), undef, 'input past the limit is rejected' );
};

subtest 'hostile input is rejected promptly' => sub {

    # Unguarded these scale as O(N^2) and take many seconds; guarded they
    # return immediately.  The 1-second threshold is deliberately generous so
    # the test is not flaky on a loaded machine.  Each case targets a distinct
    # ambiguous seam in the parsing regex.
    my %evil = (
        'letter run' => '01 Jan 2000 ' . ( 'a' x 10000 ) . '!',
        'digit run'  => '01 Jan ' . ( '1' x 10000 ) . '!',
        'space run'  => '01 Jan 2000' . ( ' ' x 10000 ) . '!',
    );

    for my $branch ( sort keys %evil ) {
        my $str = $evil{$branch};

        my $t0      = time;
        my $got     = parse_date($str);
        my $elapsed = time - $t0;

        is( $got, undef, "hostile input ($branch) is rejected" );
        cmp_ok(
            $elapsed, '<', 1,
            sprintf '%s: %d-byte input handled promptly (%.3fs)',
            $branch, length $str, $elapsed
        );
    }
};

done_testing;
