package LibUI::Time 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use Config;
    use Time::Local 1.30 qw[timelocal_posix];
    use Time::Piece;
    #
    our $COERCE = 1;    # Set to false to get the raw LibUI::Time structures in pickers

    #
    typedef 'LibUI::Time' => Struct [
        tm_sec   => Int,
        tm_min   => Int,
        tm_hour  => Int,
        tm_mday  => Int,
        tm_mon   => Int,
        tm_year  => Int,
        tm_wday  => Int,
        tm_yday  => Int,
        tm_isdst => Int,

        # BSD and GNU extension; not defined in a strict ISO C env
        ( $Config{d_tm_tm_gmtoff} ? ( tm_gmtoff => Long, ) : () ),
        ( $Config{d_tm_tm_zone}   ? ( tm_zone   => Str )   : () )
    ];

    sub to_obj($) {
        my $s = shift;
        if ($COERCE) {
            my $t = Time::Piece->_mktime(
                timelocal_posix(
                    $s->{tm_sec},  $s->{tm_min}, $s->{tm_hour},
                    $s->{tm_mday}, $s->{tm_mon}, $s->{tm_year}
                )
            );
            return $t;
        }
        return $s;
    }

    sub to_hash($) {
        my $s = shift;
        if ( ref $s eq 'Time::Piece' ) {
            return {
                tm_sec   => $s->sec,
                tm_min   => $s->min,
                tm_hour  => $s->hour,
                tm_mday  => $s->mday,
                tm_mon   => $s->_mon,
                tm_year  => $s->_year,
                tm_wday  => $s->_wday,
                tm_yday  => $s->yday,
                tm_isdst => $s->isdst,

                # BSD and GNU extension; not defined in a strict ISO C env
                ( $Config{d_tm_tm_gmtoff} ? ( tm_gmtoff => int $s->tzoffset, ) : () ),
                ( $Config{d_tm_tm_zone}   ? ( tm_zone   => 'GMT' )             : () )
            };
        }
        $s;
    }
}
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Time - Internal Wrapper for C<struct tm> in C<time.h>

=head1 SYNOPSIS

    # You'll probably not ever use this directly

=head1 DESCRIPTION

Simple calendar times represent absolute times as elapsed times since an epoch.
This is convenient for computation, but has no relation to the way people
normally think of calendar time. By contrast, broken-down time is a binary
representation of calendar time separated into year, month, day, and so on.
Broken-down time values are not useful for calculations, but they are useful
for printing human readable time information.

A broken-down time value is always relative to a choice of time zone, and it
also indicates which time zone that is.

The symbols in this section are declared in the header file C<time.h>.

=head1 Structure Members

Depending on your platform, there may be more but here are the basics:

=over

=item C<tm_sec>

This is the number of full seconds since the top of the minute (normally in the
range 0 through 59, but the actual upper limit is 60, to allow for leap seconds
if leap second support is available).

=item C<tm_min>

This is the number of full minutes since the top of the hour (in the range 0
through 59).

=item C<tm_hour>

This is the number of full hours past midnight (in the range 0 through 23).

=item C<tm_mday>

This is the ordinal day of the month (in the range 1 through 31). Watch out for
this one! As the only ordinal number in the structure, it is inconsistent with
the rest of the structure.

=item C<tm_mon>

This is the number of full calendar months since the beginning of the year (in
the range 0 through 11). Watch out for this one! People usually use ordinal
numbers for month-of-year (where January = 1).

=item C<tm_year>

This is the number of full calendar years since 1900.

=item C<tm_wday>

This is the number of full days since Sunday (in the range 0 through 6).

=item C<tm_yday>

This is the number of full days since the beginning of the year (in the range 0
through 365).

=item C<tm_isdst>

This is a flag that indicates whether Daylight Saving Time is (or was, or will
be) in effect at the time described. The value is positive if Daylight Saving
Time is in effect, zero if it is not, and negative if the information is not
available.

=item C<tm_gmtoff>

This field describes the time zone that was used to compute this broken-down
time value, including any adjustment for daylight saving; it is the number of
seconds that you must add to UTC to get local time. You can also think of this
as the number of seconds east of UTC. For example, for U.S. Eastern Standard
Time, the value is -5*60*60.

The C<tm_gmtoff> field is derived from BSD and is a GNU library extension; it
is not visible in a strict ISO C environment.

=item C<tm_zone>

This field is the name for the time zone that was used to compute this
broken-down time value.

Like C<tm_gmtoff>, this field is a BSD and GNU extension, and is not visible in
a strict ISO C environment.

=back

=head1 See Also

L<LibUI::DateTimePicker> - Select a date and time of day

L<LibUI::TimePicker> - Select a time of day

L<LibUI::DatePicker> - Select a calendar date

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

