#!perl

use strict;
use warnings;

use Test::More;
use HTTP::Date qw(str2time parse_date);

# Regression test: date parsing must accept ASCII digits only.
#
# Perl's \d matches any Unicode digit, so a date written with non-ASCII
# digits (e.g. Arabic-Indic U+0660..U+0669) used to match the parsing
# regexes.  Those Unicode digits then coerced to 0 numerically, so the
# string was "parsed" into a bogus date instead of being rejected.
#
# After hardening the regexes to [0-9], such strings must not parse.

# Map ASCII 0-9 to the corresponding Arabic-Indic digit U+0660..U+0669.
sub to_unicode_digits {
    my ($str) = @_;
    $str =~ s/([0-9])/chr( 0x0660 + $1 )/ge;
    return $str;
}

my @ascii_dates = (
    'Thu, 03 Feb 1994 00:00:00 GMT',         # fast-path RFC 1123 format
    '03/Feb/1994:00:00:00 0000',             # common logfile format
    '03-Feb-1994 00:00:00 GMT',              # rfc850 (no weekday)
    '1994-02-03 00:00:00',                   # ISO 8601
);

for my $ascii (@ascii_dates) {
    my $unicode = to_unicode_digits($ascii);

    # Sanity: the ASCII form still parses, the Unicode form differs from it.
    ok( defined str2time($ascii), "ASCII date still parses: $ascii" );
    isnt( $unicode, $ascii, 'Unicode-digit string differs from ASCII' );

    is( str2time($unicode), undef,
        'str2time rejects Unicode-digit date (not parsed as 0)' );

    is( scalar parse_date($unicode), undef,
        'parse_date rejects Unicode-digit date' );
}

done_testing;
