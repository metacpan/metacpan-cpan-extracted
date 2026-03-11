package EBook::Ishmael::Time;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(guess_time format_locale_time format_rfc3339_time);

use Time::Piece;

my $WEEKDAY_RX = qr/(?<a>
    (Sun | Mon | Tue | Wed | Thu | Fri | Sat) |
    (Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday)
)/x;
my $MONTH_NAME_RX = qr/(?<b>
    (
        Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec
    ) |
    (
        January | Febuary | March | April | May | June | July | August |
        September | October | November | December
    )
)/x;
my $CENTURY_NUM_RX  = qr/(?<C>[0-9]?[0-9])/;
my $MONTH_DAY_RX    = qr/(?<d>0?[1-9]|[12][0-9]|3[01])/;
my $HOUR_24_RX      = qr/(?<H>[01]?[0-9]|2[0-3])/;
my $HOUR_12_RX      = qr/(?<I>0?[1-9]|1[0-2])/;
my $YEAR_DAY_RX     = qr/(?<j>0?(0?[1-9]|[1-9]{2})|[1-2][1-9]{2}|3[0-6]{2})/;
my $MONTH_NUM_RX    = qr/(?<m>0?[1-9]|1[0-2])/;
my $MINUTE_RX       = qr/(?<M>[0-5]?[0-9])/;
my $AM_PM_RX        = qr/(?<p>AM|PM>)/i;
my $SECONDS_RX      = qr/(?<S>[0-5]?[0-9]|6[01])/;
my $WEEK_NUM_RX     = qr/(?<U>[0-4]?[0-9]|5[0-3])/;
my $ORD_WEEK_DAY_RX = qr/(?<w>[0-6])/;
my $CENTURY_YEAR_RX = qr/(?<y>[0-9]?[0-9])/;
my $YEAR_RX         = qr/(?<Y>[0-9]{1,4})/;
my $TZ_SPEC_RX      = qr/(?<z>Z|[+\-][0-9]{2}:?[0-9]{2})/;
my $TZ_NAME_RX      = qr/(?<Z>[A-Z]{3})/;
my $EPOCH_RX        = qr/(?<s>-?[0-9]+)/;
my $HHMMSS_RX       = qr/$HOUR_24_RX:$MINUTE_RX:$SECONDS_RX/;

my @DATE_RXS = (
    # strftime '%c' + '%Z'
    qr/$WEEKDAY_RX\s+$MONTH_NAME_RX\s+$MONTH_DAY_RX\s+$HHMMSS_RX\s+$YEAR_RX\s+$TZ_NAME_RX/,
    # strftime '%c' on my system (en_US.UTF-8)
    qr/$WEEKDAY_RX\s+$MONTH_NAME_RX\s+$MONTH_DAY_RX\s+$HHMMSS_RX\s+$YEAR_RX/,
    # RFC3339
    qr/$YEAR_RX-$MONTH_NUM_RX-$MONTH_DAY_RX\x54$HHMMSS_RX$TZ_SPEC_RX/,
    # RFC822
    qr/$MONTH_DAY_RX\s+$MONTH_NAME_RX\s+$CENTURY_YEAR_RX\s+$HOUR_24_RX:$MINUTE_RX\s+$TZ_NAME_RX/,
    qr/$MONTH_DAY_RX\s+$MONTH_NAME_RX\s+$CENTURY_YEAR_RX\s+$HOUR_24_RX:$MINUTE_RX\s+$TZ_SPEC_RX/,
    # RFC1123
    qr/$WEEKDAY_RX,\s+$MONTH_DAY_RX\s+$MONTH_NAME_RX\s+$YEAR_RX\s+$HHMMSS_RX\s+$TZ_NAME_RX/,
    qr/$WEEKDAY_RX,\s+$MONTH_DAY_RX\s+$MONTH_NAME_RX\s+$YEAR_RX\s+$HHMMSS_RX\s+$TZ_SPEC_RX/,
    # RFC850
    qr/$WEEKDAY_RX,\s+$MONTH_DAY_RX-$MONTH_NAME_RX-$CENTURY_YEAR_RX\s+$HHMMSS_RX\s+$TZ_NAME_RX/,
    # output of my date(1)
    qr/$WEEKDAY_RX\s+$MONTH_NAME_RX\s+$MONTH_DAY_RX\s+$HHMMSS_RX\s+$AM_PM_RX\s+$TZ_NAME_RX\s+$YEAR_RX/,
    # pdfinfo time format
    qr/$WEEKDAY_RX\s+$MONTH_NAME_RX\s+$MONTH_DAY_RX\s+$HHMMSS_RX\s+$YEAR_RX\s+$TZ_NAME_RX/,
    # Ruby date
    qr/$WEEKDAY_RX\s+$MONTH_NAME_RX\s+$MONTH_DAY_RX\s+$HHMMSS_RX\s+$TZ_SPEC_RX\s+$YEAR_RX/,
    # misc. date formats
    qr/$MONTH_DAY_RX\.$MONTH_NUM_RX\.$CENTURY_YEAR_RX/,
    qr/$MONTH_NUM_RX\.$MONTH_DAY_RX\.$CENTURY_YEAR_RX/,
    qr/$MONTH_DAY_RX\/$MONTH_NUM_RX\/$CENTURY_YEAR_RX/,
    qr/$MONTH_NUM_RX\/$MONTH_DAY_RX\/$CENTURY_YEAR_RX/,
    qr/$MONTH_DAY_RX\.$MONTH_NUM_RX\.$YEAR_RX/,
    qr/$MONTH_NUM_RX\.$MONTH_DAY_RX\.$YEAR_RX/,
    qr/$MONTH_DAY_RX\/$MONTH_NUM_RX\/$YEAR_RX/,
    qr/$MONTH_NUM_RX\/$MONTH_DAY_RX\/$YEAR_RX/,
    qr/$YEAR_RX-$MONTH_NUM_RX-$MONTH_DAY_RX/,
    qr/$YEAR_RX/,
    qr/$EPOCH_RX/,
);

my @FULL_MATCH_DATE_RXS = map { qr/^\s*$_\s*$/ } @DATE_RXS;

my %POST_PROCS = (
    # Some versions of Time::Piece can't handle colons in time zone specs
    'z' => sub { $_[0] eq 'Z' ? '+0000' : $_[0] =~ s/://r },
);

sub guess_time {

    my ($str) = @_;

    my %matches;
    my $found_match = 0;
    for my $rx (@FULL_MATCH_DATE_RXS) {
        if ($str =~ $rx) {
            $found_match = 1;
            %matches = %+;
            last;
        }
    }
    if (!$found_match) {
        die "'$str' does not match any recognized date layout\n";
    }

    my @codes;
    my @parts;
    for my $k (keys %matches) {
        push @codes, "%$k";
        if (exists $POST_PROCS{ $k }) {
            push @parts, $POST_PROCS{ $k }->($matches{ $k });
        } else {
            push @parts, $matches{ $k };
        }
    }

    my $tp = eval { Time::Piece->strptime(join(' ', @parts), join(' ', @codes)) };
    if ($@ ne '') {
        die "Failed to parse '$str'\n";
    }
    return $tp->epoch;

}

sub format_locale_time {

    my $time = shift;

    return gmtime($time)->strftime("%c");

}

sub format_rfc3339_time {

    my $time = shift;

    return gmtime($time)->strftime("%Y-%m-%dT%H:%M:%S%z");

}

1;

=head1 NAME

EBook::Ishmael::Time - Time-handling subroutines for ishmael

=head1 SYNOPSIS

  use EBook::Ishmael::Time qw(guess_time);

  my $t = guess_time("01.14.2025");

=head1 DESCRIPTION

B<EBook::Ishmael::Time> is a module that provides various time-handling
subroutines for L<ishmael>. This is a private module, please consult the
L<ishmael> manual for user documentation.

=head1 SUBROUTINES

=over 4

=item $epoch = guess_time($str)

C<guess_time()> guesses the timestamp format of C<$str> and returns the number
seconds since the Unix epoch, or C<undef> if it could not identify the
timestamp format.

=item $locale = format_locale_time($epoch)

Formats the given time in the preferred format of the current locale.

=item $rfc3339 = format_rfc3339_time($epoch)

Formats the given time as an RFC3339 timestamp.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
