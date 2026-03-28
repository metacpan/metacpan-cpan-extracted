#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Time::Piece;

use EBook::Ishmael::Time qw(guess_time format_rfc3339_time format_locale_time);

my $TARGET = 1767225600;

my @TEST_TIMES = (
    "2026",
    "2026-01-01",
    "2026-01-01T00:00:00+00:00",
    "Thu Jan  1 00:00:00 2026",
    "01.01.2026",
    "1/1/2026",
    "1/1/26",
    "Thu, 01 Jan 2026 00:00:00 +0000",
    $TARGET,
    "Thu Jan 01 00:00:00 +0000 2026",
);

# Times that only work with Time::Piece's 1.38 timezone fix
my @POST_138 = (
    "Thu Jan  1 00:00:00 2026 GMT",
    "Thu Jan  1 00:00:00 AM GMT 2026",
    "Thu, 01 Jan 2026 00:00:00 GMT",
);

# Times that only work after Time::Piece 1.39 (I do not know why, might have
# something to do with how locale parsing behavior)
my @POST_139 = (
    "Thursday, 01-Jan-26 00:00:00 GMT",
);

for my $tt (@TEST_TIMES) {
    is(guess_time($tt), $TARGET, "guess_time('$tt') == $TARGET");
}

SKIP: {
    unless ($Time::Piece::VERSION ge '1.38') {
        skip '$Time::Piece::VERSION < 1.38', scalar @POST_138;
    }
    for my $tt (@POST_138) {
        is(guess_time($tt), $TARGET, "guess_time('$tt') == $TARGET");
    }
}

SKIP: {
    unless ($Time::Piece::VERSION gt '1.39') {
        skip '$Time::Piece::VERSION <= 1.39', scalar @POST_139;
    }
    for my $tt (@POST_139) {
        is(guess_time($tt), $TARGET, "guess_time('$tt') == $TARGET");
    }
}

my $RFC3339_STRPTIME = '%Y-%m-%dT%T%z';
my $LOCALE_STRPTIME = '%c';

my $RFC3339_RX = qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/;

for my $t (map { 10 ** $_ } (1 .. 10)) {
    my $rfc3339 = format_rfc3339_time($t);
    like($rfc3339, $RFC3339_RX, "format_rfc3339_time($t) ok");
}

done_testing;
