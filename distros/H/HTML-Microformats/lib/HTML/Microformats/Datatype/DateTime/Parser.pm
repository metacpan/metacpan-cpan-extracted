=head1 NAME

HTML::Microformats::Datatype::DateTime::Parser - parse ISO8601 datetimes

=head1 DESCRIPTION

This module is a moderately modified version of L<DateTime::Format::ISO8601>.

It allows datetimes to be expressed with a somewhat looser syntax, especially
support for whitespace between the date and time instead of a "T". It also
calculates the "resolution" of the datetime (e.g. is it specified to year,
month, day, hour, minute, second or nanosecond precision) which it places
in $dt->{'resolution'}.

Other than that, it can be used exactly as DateTime::Format::ISO8601 can.
It parses strings into normal DateTime objects.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Datatype::DateTime>,
L<DateTime>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on DateTime::Format::ISO8601 by Joshua Hoblitt.

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2005 Joshua Hoblitt

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

package HTML::Microformats::Datatype::DateTime::Parser;

use strict qw(subs vars); no warnings;

use Carp qw( croak );
use DateTime;
use DateTime::Format::Builder;
use Params::Validate qw( validate validate_pos BOOLEAN OBJECT SCALAR );

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Datatype::DateTime::Parser::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Datatype::DateTime::Parser::VERSION   = '0.105';
}

{
    my $default_legacy_year;
    sub DefaultLegacyYear {
        my $class = shift;

        ( $default_legacy_year ) = validate_pos( @_,
            {
                type        => BOOLEAN,
                callbacks   => {
                    'is 0, 1, or undef' =>
                        sub { ! defined( $_[0] ) || $_[0] == 0 || $_[0] == 1 },
                },
            }
        ) if @_;

        return $default_legacy_year;
    }
}
__PACKAGE__->DefaultLegacyYear( 1 );

{
    my $default_cut_off_year;
    sub DefaultCutOffYear {
        my $class = shift;

        ( $default_cut_off_year ) = validate_pos( @_,
            {
                type        => SCALAR,
                callbacks   => {
                    'is between 0 and 99' =>
                        sub { $_[0] >= 0 && $_[0] <= 99 },
                },
            }
        ) if @_;

        return $default_cut_off_year;
    }
}
# the same default value as DT::F::Mail
__PACKAGE__->DefaultCutOffYear( 49 );

sub new {
    my( $class ) = shift;

    my %args = validate( @_,
        {
            base_datetime => {
                type        => OBJECT,
                can         => 'utc_rd_values',
                optional    => 1,
            },
            legacy_year => {
                type        => BOOLEAN,
                default     => $class->DefaultLegacyYear,
                callbacks   => {
                    'is 0, 1, or undef' =>
                        sub { ! defined( $_[0] ) || $_[0] == 0 || $_[0] == 1 },
                },
            },
            cut_off_year => {
                type        => SCALAR,
                default     => $class->DefaultCutOffYear,
                callbacks   => {
                    'is between 0 and 99' =>
                        sub { $_[0] >= 0 && $_[0] <= 99 },
                },
            },
        }
    );

    $class = ref( $class ) || $class;

    my $self = bless( \%args, $class );

    if ( $args{ base_datetime } ) {
        $self->set_base_datetime( object => $args{ base_datetime } );
    }

    return( $self );
}

# lifted from DateTime
sub clone { bless { %{ $_[0] } }, ref $_[0] }

sub base_datetime { $_[0]->{ base_datetime } }

sub set_base_datetime {
    my $self = shift;

    my %args = validate( @_,
        {
            object => {
                type        => OBJECT,
                can         => 'utc_rd_values',
            },
        }
    );
       
    # ISO8601 only allows years 0 to 9999
    # this implimentation ignores the needs of expanded formats
    my $dt = DateTime->from_object( object => $args{ object } );
    my $lower_bound = DateTime->new( year => 0 );
    my $upper_bound = DateTime->new( year => 10000 );

    if ( $dt < $lower_bound ) {
        croak "base_datetime must be greater then or equal to ",
            $lower_bound->iso8601;
    }
    if ( $dt >= $upper_bound ) {
        croak "base_datetime must be less then ", $upper_bound->iso8601;
    }

    $self->{ base_datetime } = $dt;

    return $self;
}

sub legacy_year { $_[0]->{ legacy_year } }

sub set_legacy_year {
    my $self = shift;

    my @args = validate_pos( @_,
        {
            type        => BOOLEAN,
            callbacks   => {
                'is 0, 1, or undef' =>
                    sub { ! defined( $_[0] ) || $_[0] == 0 || $_[0] == 1 },
            },
        }
    );

    $self->{ legacy_year } = $args[0];

    return $self;
}

sub cut_off_year { $_[0]->{ cut_off_year } }

sub set_cut_off_year {
    my $self = shift;

    my @args = validate_pos( @_,
        {
            type        => SCALAR,
            callbacks   => {
                'is between 0 and 99' =>
                    sub { $_[0] >= 0 && $_[0] <= 99 },
            },
        }
    );

    $self->{ cut_off_year } = $args[0];

    return $self;
}

DateTime::Format::Builder->create_class(
    parsers => {
        parse_datetime => [
            [ preprocess => \&_do_whitespace ],
            {
                #YYYYMMDD 19850412
                length => [qw(8 9)],
                regex  => qr/^ (-?\d{4}) ([01]\d) ([0-3]\d) $/x,
                params => [ qw( year month day ) ],
                postprocess => \&_do_resolution,
            },
            {
                # uncombined with above because 
                #regex => qr/^ (\d{4}) -??  (\d\d) -?? (\d\d) $/x,
                # was matching 152746-05

                #YYYY-MM-DD 1985-04-12
                length => [qw(10 11)],
                regex  => qr/^ (-?\d{4}) - ([01]\d) - ([0-3]\d) $/x,
                params => [ qw( year month day ) ],
                postprocess => \&_do_resolution,
            },
            {
                #YYYY-MM 1985-04
                length => [qw(7 8)],
                regex  => qr/^ (-?\d{4}) - ([01]\d) $/x,
                params => [ qw( year month ) ],
                postprocess => \&_do_resolution,
            },
            {
                #YYYY 1985
                length => [qw(4 5)],
                regex  => qr/^ (-?\d{4}) $/x,
                params => [ qw( year ) ],
                postprocess => \&_do_resolution,
            },
            {
                #YY 19 (century)
                length => 2,
                regex  => qr/^ (\d\d) $/x,
                params => [ qw( year ) ],
                postprocess => [\&_normalize_century, \&_do_resolution],
            },
            {
                #YYMMDD 850412
                #YY-MM-DD 85-04-12
                length => [ qw( 6 8 ) ],
                regex  => qr/^ (\d\d) -??  ([01]\d) -?? ([0-3]\d) $/x,
                params => [ qw( year month day ) ],
                postprocess => [\&_fix_2_digit_year, \&_do_resolution],
            },
            {
                #-YYMM -8504
                #-YY-MM -85-04
                length => [ qw( 5 6 ) ],
                regex  => qr/^ - (\d\d) -??  ([01]\d) $/x,
                params => [ qw( year month ) ],
                postprocess => [\&_fix_2_digit_year, \&_do_resolution],
            },
            {
                #-YY -85
                length   => 3,
                regex    => qr/^ - (\d\d) $/x,
                params   => [ qw( year ) ],
                postprocess => [\&_fix_2_digit_year, \&_do_resolution],
            },
            {
                #--MMDD --0412
                #--MM-DD --04-12
                length => [ qw( 6 7 ) ],
                regex  => qr/^ -- ([01]\d) -??  ([0-3]\d) $/x,
                params => [ qw( month day ) ],
                postprocess => [\&_add_year, \&_do_resolution],
            },
            {
                #--MM --04
                length => 4,
                regex  => qr/^ -- ([01]\d) $/x,
                params => [ qw( month ) ],
                postprocess => [\&_add_year, \&_do_resolution],
            },
            {
                #---DD ---12
                length => 5,
                regex  => qr/^ --- ([0-3]\d) $/x,
                params => [ qw( day ) ],
                postprocess => [ \&_add_year, \&_add_month, \&_do_resolution],
            },
            {
                #+[YY]YYYYMMDD +0019850412
                #+[YY]YYYY-MM-DD +001985-04-12
                length => [ qw( 11 13 ) ],
                regex  => qr/^ \+ (\d{6}) -?? ([01]\d) -?? ([0-3]\d)  $/x,
                params => [ qw( year month day ) ],
                postprocess => \&_do_resolution,
            },
            {
                #+[YY]YYYY-MM +001985-04
                length => 10,
                regex  => qr/^ \+ (\d{6}) - (\d\d)  $/x,
                params => [ qw( year month ) ],
                postprocess => \&_do_resolution,
            },
            {
                #+[YY]YYYY +001985
                length => 7,
                regex  => qr/^ \+ (\d{6}) $/x,
                params => [ qw( year ) ],
                postprocess => \&_do_resolution,
            },
            {
                #+[YY]YY +0019 (century)
                length => 5,
                regex  => qr/^ \+ (\d{4}) $/x,
                params => [ qw( year ) ],
                postprocess => [\&_normalize_century, \&_do_resolution],
            },
            {
                #YYYYDDD 1985102
                #YYYY-DDD 1985-102
                length => [ qw( 7 8 9 ) ],
                regex  => qr/^ (-?\d{4}) -?? (\d{3}) $/x,
                params => [ qw( year day_of_year ) ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
                postprocess => \&_do_resolution,
            },
            {
                #YYDDD 85102
                #YY-DDD 85-102
                length => [ qw( 5 6 7 ) ],
                regex  => qr/^ (-?\d\d) -?? (\d{3}) $/x,
                params => [ qw( year day_of_year ) ],
                postprocess => [ \&_fix_2_digit_year, \&_do_resolution],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-DDD -102
                length => 4,
                regex  => qr/^ - (\d{3}) $/x,
                params => [ qw( day_of_year ) ],
                postprocess => [ \&_add_year, \&_do_resolution],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #+[YY]YYYYDDD +001985102
                #+[YY]YYYY-DDD +001985-102
                length => [ qw( 10 11 ) ],
                regex  => qr/^ \+ (\d{6}) -?? (\d{3}) $/x,
                params => [ qw( year day_of_year ) ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
                postprocess => \&_do_resolution,
            },
            {
                #YYYYWwwD 1985W155
                #YYYY-Www-D 1985-W15-5
                length => [ qw( 8 9 10 11 ) ],
                regex  => qr/^ (-?\d{4}) -?? W (\d\d) -?? (\d) $/x,
                params => [ qw( year week day_of_year ) ],
                postprocess => [ \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYYYWww 1985W15
                #YYYY-Www 1985-W15
                length => [ qw( 7 8 9 ) ],
                regex  => qr/^ (-?\d{4}) -?? W (\d\d) $/x,
                params => [ qw( year week ) ],
                postprocess => [ \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYWwwD 85W155
                #YY-Www-D 85-W15-5
                length => [ qw( 6 7 8 9 ) ],
                regex  => qr/^ (-?\d\d) -?? W (\d\d) -?? (\d) $/x,
                params => [ qw( year week day_of_year ) ],
                postprocess => [ \&_fix_2_digit_year, \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #YYWww 85W15
                #YY-Www 85-W15
                length => [ qw( 5 6 7 ) ],
                regex  => qr/^ (-?\d\d) -?? W (\d\d) $/x,
                params => [ qw( year week ) ],
                postprocess => [ \&_fix_2_digit_year, \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-YWwwD -5W155
                #-Y-Www-D -5-W15-5
                length => [ qw( 6 8 ) ],
                regex  => qr/^ - (\d) -?? W (\d\d) -?? (\d) $/x,
                params => [ qw( year week day_of_year ) ],
                postprocess => [ \&_fix_1_digit_year, \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-YWww -5W15
                #-Y-Www -5-W15
                length => [ qw( 5 6 ) ],
                regex  => qr/^ - (\d) -?? W (\d\d) $/x,
                params => [ qw( year week ) ],
                postprocess => [ \&_fix_1_digit_year, \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-WwwD -W155
                #-Www-D -W15-5
                length => [ qw( 5 6 ) ],
                regex  => qr/^ - W (\d\d) -?? (\d) $/x,
                params => [ qw( week day_of_year ) ],
                postprocess => [ \&_add_year, \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-Www -W15
                length => 4,
                regex  => qr/^ - W (\d\d) $/x,
                params => [ qw( week ) ],
                postprocess => [ \&_add_year, \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #-W-D -W-5
                length => 4,
                regex  => qr/^ - W - (\d) $/x,
                params => [ qw( day_of_year ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_week,
                    \&_normalize_week,
                    \&_do_resolution
                ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #+[YY]YYYYWwwD +001985W155
                #+[YY]YYYY-Www-D +001985-W15-5
                length => [ qw( 11 13 ) ],
                regex  => qr/^ \+ (\d{6}) -?? W (\d\d) -?? (\d) $/x,
                params => [ qw( year week day_of_year ) ],
                postprocess => [ \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #+[YY]YYYYWww +001985W15
                #+[YY]YYYY-Www +001985-W15
                length => [ qw( 10 11 ) ],
                regex  => qr/^ \+ (\d{6}) -?? W (\d\d) $/x,
                params => [ qw( year week ) ],
                postprocess => [ \&_normalize_week, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
            {
                #hhmmss 232050 - skipped
                #hh:mm:ss 23:20:50
                length => [ qw( 8 9 ) ],
                regex  => qr/^ T?? (\d\d) : (\d\d) : (\d\d) $/x,
                params => [ qw( hour minute second) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },
                #hhmm 2320 - skipped
                #hh 23 -skipped
            {
                #hh:mm 23:20
                length => [ qw( 4 5 6 ) ],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) $/x,
                params => [ qw( hour minute ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },
            {
                #hhmmss,ss 232050,5
                #hh:mm:ss,ss 23:20:50,5
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params => [ qw( hour minute second nanosecond) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_second,
                    \&_do_resolution
                ],
            },
            {
                #hhmm,mm 2320,8
                #hh:mm,mm 23:20,8
                regex  => qr/^ T?? (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params => [ qw( hour minute second ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_minute,
                    \&_do_resolution
                ],
            },
            {
                #hh,hh 23,3
                regex  => qr/^ T?? (\d\d) [\.,] (\d+) $/x,
                params => [ qw( hour minute ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_hour,
                    \&_do_resolution
                ],
            },
            {
                #-mmss -2050 - skipped
                #-mm:ss -20:50
                length => 6,
                regex  => qr/^ - (\d\d) : (\d\d) $/x,
                params => [ qw( minute second ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_do_resolution
                ],
            },
                #-mm -20 - skipped
                #--ss --50 - skipped
            {
                #-mmss,s -2050,5
                #-mm:ss,s -20:50,5
                regex  => qr/^ - (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params => [ qw( minute second nanosecond ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_fractional_second,
                    \&_do_resolution
                ],
            },
            {
                #-mm,m -20,8
                regex  => qr/^ - (\d\d) [\.,] (\d+) $/x,
                params => [ qw( minute second ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_fractional_minute,
                    \&_do_resolution
                ],
            },
            {
                #--ss,s --50,5
                regex  => qr/^ -- (\d\d) [\.,] (\d+) $/x,
                params => [ qw( second nanosecond) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_add_minute,
                    \&_fractional_second,
                    \&_do_resolution
                ],
            },
            {
                #hhmmssZ 232030Z
                #hh:mm:ssZ 23:20:30Z
                length => [ qw( 7 8 9 10 ) ],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) Z $/x,
                params => [ qw( hour minute second ) ],
                extra  => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },

            {
                #hhmmss.ssZ 232030.5Z
                #hh:mm:ss.ssZ 23:20:30.5Z
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+) Z $/x,
                params => [ qw( hour minute second nanosecond) ],
                extra  => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_second,
                    \&_do_resolution
                ],
            },

            {
                #hhmmZ 2320Z
                #hh:mmZ 23:20Z
                length => [ qw( 5 6 7 ) ],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) Z $/x,
                params => [ qw( hour minute ) ],
                extra  => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },
            {
                #hhZ 23Z
                length => [ qw( 3 4 ) ],
                regex  => qr/^ T?? (\d\d) Z $/x,
                params => [ qw( hour ) ],
                extra  => { time_zone => 'UTC' },
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },
            {
                # TOBY - modified
                #hhmmss[+-]hhmm 152746+0100 152746-0500
                #hh:mm:ss[+-]hh:mm 15:27:46+01:00 15:27:46-05:00
                length => [ qw( 11 12 14 15 ) ],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d)
                            ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( hour minute second time_zone ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_normalize_offset,
                    \&_do_resolution
                ],
            },
            {
                # TOBY - modified
                #hhmmss.ss[+-]hhmm 152746.5+0100 152746.5-0500
                #hh:mm:ss.ss[+-]hh:mm 15:27:46.5+01:00 15:27:46.5-05:00
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+)
                            ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( hour minute second nanosecond time_zone ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_fractional_second,
                    \&_normalize_offset,
                    \&_do_resolution
                ],
            },

            {
                #hhmmss[+-]hh 152746+01 152746-05
                #hh:mm:ss[+-]hh 15:27:46+01 15:27:46-05
                length => [ qw( 9 10 11 12 ) ],
                regex  => qr/^ T?? (\d\d) :?? (\d\d) :?? (\d\d)
                            ([+-] \d\d) $/x,
                params => [ qw( hour minute second time_zone ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_normalize_offset,
                    \&_do_resolution
                ],
            },
            {
                #YYYYMMDDThhmmss 19850412T101530
                #YYYY-MM-DDThh:mm:ss 1985-04-12T10:15:30
#                length => [ qw( 15 19 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) $/x,
                params => [ qw( year month day hour minute second ) ],
                extra  => { time_zone => 'floating' },
                postprocess => \&_do_resolution
            },
            {
                #YYYYMMDDThhmmss.ss 19850412T101530.123
                #YYYY-MM-DDThh:mm:ss.ss 1985-04-12T10:15:30.123
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+) $/x,
                params => [ qw( year month day hour minute second nanosecond ) ],
                extra  => { time_zone => 'floating' },
                postprocess => [
                    \&_fractional_second,
                    \&_do_resolution
                ],
            },
            {
                #YYYYMMDDThhmmssZ 19850412T101530Z
                #YYYY-MM-DDThh:mm:ssZ 1985-04-12T10:15:30Z
#                length => [ qw( 16 20 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) Z $/x,
                params => [ qw( year month day hour minute second ) ],
                extra  => { time_zone => 'UTC' },
                postprocess => \&_do_resolution
            },
            {
                #YYYYMMDDThhmmss.ssZ 19850412T101530.5Z 20041020T101530.5Z
                #YYYY-MM-DDThh:mm:ss.ssZ 1985-04-12T10:15:30.5Z 1985-04-12T10:15:30.5Z
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+)
                            Z$/x,
                params => [ qw( year month day hour minute second nanosecond ) ],
                extra  => { time_zone => 'UTC' },
                postprocess => [
                    \&_fractional_second,
                    \&_do_resolution
                ],
            },

            {
                # TOBY - added
                #YYYYMMDDThh[+-]hhmm 19850412T10+0100 20041020T10-0500
                #YYYY-MM-DDThh[+-]hh:mm 1985-04-12T10+01:00 1985-04-12T10-05:00
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T?? (\d\d)
                            ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( year month day hour time_zone ) ],
                postprocess => [
                    \&_normalize_offset,
                    \&_do_resolution
                ],
            },
            {
                # TOBY - added
                #YYYYMMDDThhmm[+-]hhmm 19850412T1015+0100 20041020T1015-0500
                #YYYY-MM-DDThh:mm[+-]hh:mm 1985-04-12T10:15+01:00 1985-04-12T10:15-05:00
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T?? (\d\d) :?? (\d\d)
                            ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( year month day hour minute time_zone ) ],
                postprocess => [
                    \&_normalize_offset,
                    \&_do_resolution
                ],
            },
            {
                # TOBY - modified
                #YYYYMMDDThhmmss[+-]hhmm 19850412T101530+0400
                #YYYY-MM-DDThh:mm:ss[+-]hh:mm 1985-04-12T10:15:30+04:00
#                length => [ qw( 20 25 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( year month day hour minute second time_zone ) ],
                postprocess => [\&_normalize_offset,\&_do_resolution]
            },
            {
                # TOBY - modified
                #YYYYMMDDThhmmss.ss[+-]hhmm 19850412T101530.5+0100 20041020T101530.5-0500
                #YYYY-MM-DDThh:mm:ss.ss[+-]hh:mm 1985-04-12T10:15:30.5+01:00 1985-04-12T10:15:30.5-05:00
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T?? (\d\d) :?? (\d\d) :?? (\d\d) [\.,] (\d+)
                            ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( year month day hour minute second nanosecond time_zone ) ],
                postprocess => [
                    \&_fractional_second,
                    \&_normalize_offset,
                    \&_do_resolution
                ],
            },

            {
                #YYYYMMDDThhmmss[+-]hh 19850412T101530+04
                #YYYY-MM-DDThh:mm:ss[+-]hh 1985-04-12T10:15:30+04
#                length => [ qw( 18 22 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) :?? (\d\d) ([+-] \d\d) $/x,
                params => [ qw( year month day hour minute second time_zone ) ],
                postprocess => [\&_normalize_offset, \&_do_resolution]
            },
            {
                #YYYYMMDDThhmm 19850412T1015
                #YYYY-MM-DDThh:mm 1985-04-12T10:15
#                length => [ qw( 13 16 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d\d) -?? (\d\d)
                            T (\d\d) :?? (\d\d) $/x,
                params => [ qw( year month day hour minute ) ],
                extra  => { time_zone => 'floating' },
                postprocess => [\&_normalize_offset, \&_do_resolution]
            },
            {
                #YYYYDDDThhmmZ 1985102T1015Z
                #YYYY-DDDThh:mmZ 1985-102T10:15Z
#                length => [ qw( 13 15 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -??  (\d{3}) T
                            (\d\d) :?? (\d\d) Z $/x,
                params => [ qw( year day_of_year hour minute ) ],
                extra  => { time_zone => 'UTC' },
                constructor => [ 'DateTime', 'from_day_of_year' ],
                postprocess => [\&_normalize_offset, \&_do_resolution]
            },
            {
                # TOBY - modified
                #YYYYWwwDThhmm[+-]hhmm 1985W155T1015+0400
                #YYYY-Www-DThh:mm[+-]hh 1985-W15-5T10:15+04
#                length => [ qw( 18 19 ) ],
                regex  => qr/^ ((?:\-|\+\d+)?\d{4}) -?? W (\d\d) -?? (\d)
                            T (\d\d) :?? (\d\d) ([+-] \d\d (?: :?? \d\d)?) $/x,
                params => [ qw( year week day_of_year hour minute time_zone) ],
                postprocess => [ \&_normalize_week, \&_normalize_offset, \&_do_resolution ],
                constructor => [ 'DateTime', 'from_day_of_year' ],
            },
        ],
        parse_time => [
            {
                #hhmmss 232050
                length => [ qw( 6 7 ) ],
                regex => qr/^ T?? (\d\d) (\d\d) (\d\d) $/x,
                params => [ qw( hour minute second ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day, 
                    \&_do_resolution
                ],
            },
            {
                #hhmm 2320
                length => [ qw( 4 5 ) ],
                regex  => qr/^ T?? (\d\d) (\d\d) $/x,
                params => [ qw( hour minute ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },
            {
                #hh 23
                length => [ qw( 2 3 ) ],
                regex  => qr/^ T?? (\d\d) $/x,
                params => [ qw( hour ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_do_resolution
                ],
            },
            {
                #-mmss -2050
                length => 5,
                regex  => qr/^ - (\d\d) (\d\d) $/x,
                params => [ qw( minute second ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_do_resolution
                ],
            },
            {
                #-mm -20
                length => 3,
                regex  => qr/^ - (\d\d) $/x,
                params => [ qw( minute ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_do_resolution
                ],
            },
            {
                #--ss --50
                length => 4,
                regex  => qr/^ -- (\d\d) $/x,
                params => [ qw( second ) ],
                postprocess => [
                    \&_add_year,
                    \&_add_month,
                    \&_add_day,
                    \&_add_hour,
                    \&_add_minute,
                    \&_do_resolution
                ],
            },
        ],
    }
);

sub _fix_1_digit_year {
    my %p = @_;
     
    no strict 'refs';
    my $year = ( $p{ self }{ base_datetime } || DateTime->now )->year;
    use strict qw(subs vars); no warnings;

    $year =~ s/.$//;
    $p{ parsed }{ year } =  $year . $p{ parsed }{ year };

    return 1;
}

sub _fix_2_digit_year {
    my %p = @_;
     
    # this is a mess because of the need to support parse_* being called
    # as a class method
    no strict 'refs';
    if ( exists $p{ self }{ legacy_year } ) {
        if ( $p{ self }{ legacy_year } ) {
            my $cutoff = exists $p{ self }{ cut_off_year }
                ? $p{ self }{ cut_off_year } : $p{ self }->DefaultCutOffYear;
            $p{ parsed }{ year } += $p{ parsed }{ year } > $cutoff ? 1900 : 2000;
        } else {
            my $century = ( $p{ self }{ base_datetime } || DateTime->now )->strftime( '%C' );
            $p{ parsed }{ year } += $century * 100;
        }
    } else {
        my $cutoff = exists $p{ self }{ cut_off_year }
            ? $p{ self }{ cut_off_year } : $p{ self }->DefaultCutOffYear;
        $p{ parsed }{ year } += $p{ parsed }{ year } > $cutoff ? 1900 : 2000;
    }
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _add_minute {
    my %p = @_;

    no strict 'refs';
    $p{ parsed }{ minute } = ( $p{ self }{ base_datetime } || DateTime->now )->minute;
    $p{ self }{ missing_details }{ minute } = 1;
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _add_hour {
    my %p = @_;

    no strict 'refs';
    $p{ parsed }{ hour } = ( $p{ self }{ base_datetime } || DateTime->now )->hour;
    $p{ self }{ missing_details }{ hour } = 1;
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _add_day {
    my %p = @_;

    no strict 'refs';
    $p{ parsed }{ day } = ( $p{ self }{ base_datetime } || DateTime->now )->day;
    $p{ self }{ missing_details }{ day } = 1;
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _add_week {
    my %p = @_;

    no strict 'refs';
    $p{ parsed }{ week } = ( $p{ self }{ base_datetime } || DateTime->now )->week;
    $p{ self }{ missing_details }{ week } = 1;
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _add_month {
    my %p = @_;

    no strict 'refs';
    $p{ parsed }{ month } = ( $p{ self }{ base_datetime } || DateTime->now )->month;
    $p{ self }{ missing_details }{ month } = 1;
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _add_year {
    my %p = @_;

    no strict 'refs';
    $p{ parsed }{ year } = ( $p{ self }{ base_datetime } || DateTime->now )->year;
    $p{ self }{ missing_details }{ year } = 1;
    use strict qw(subs vars); no warnings;

    return 1;
}

sub _fractional_second {
    my %p = @_;

    $p{ parsed }{ nanosecond } = ".$p{ parsed }{ nanosecond }" * 10**9; 

    return 1;
}

sub _fractional_minute {
    my %p = @_;

    $p{ parsed }{ second } = ".$p{ parsed }{ second }" * 60; 

    return 1;
}

sub _fractional_hour {
    my %p = @_;

    $p{ parsed }{ minute } = ".$p{ parsed }{ minute }" * 60; 

    return 1;
}

sub _normalize_offset {
    my %p = @_;

    return 1 unless (defined $p{ parsed }{ time_zone });
    
    $p{ parsed }{ time_zone } =~ s/://;
    
    if( length $p{ parsed }{ time_zone } == 3 ) {
        $p{ parsed }{ time_zone }  .= '00';
    }
    
    elsif( length $p{ parsed }{ time_zone } == 2 ) {
        $p{ parsed }{ time_zone }  .= '000';
    }

    return 1;
}

sub _normalize_week {
    my %p = @_;

    # from section 4.3.2.2
    # "A calendar week is identified within a calendar year by the calendar
    # week number. This is its ordinal position within the year, applying the
    # rule that the first calendar week of a year is the one that includes the
    # first Thursday of that year and that the last calendar week of a
    # calendar year is the week immediately preceding the first calendar week
    # of the next calendar year."

    # this make it oh so fun to covert an ISO week number to a count of days

    my $dt = DateTime->new(
                year => $p{ parsed }{ year },
             );
                                                                                
    if ( $dt->week_number == 1 ) {
        $p{ parsed }{ week } -= 1;
    }

    $p{ parsed }{ week } *= 7;

    if( defined $p{ parsed }{ day_of_year } ) {
        $p{ parsed }{ week } -= $dt->day_of_week -1;
    }

    $p{ parsed }{ day_of_year } += $p{ parsed }{ week };

    delete $p{ parsed }{ week };

    return 1;
}

sub _normalize_century {
    my %p = @_;

    $p{ parsed }{ year } .= '01';

    return 1;
}

# TOBY - new preprocessing function, primarily to handle HTML5 date formats.
sub _do_whitespace {
    my %args = @_;
    my ($date, $p) = @args{qw( input parsed )};
    
    # Normalise white space.
    $date =~ s/(^\s+|\s+$)//g;
    $date =~ s/\s+/ /g;
    
    # HTML 5 split date with whitespace between Date and Time
    $date =~ s/\-(\d\d?)\s(\d\d?)\:/sprintf("\-%02dT%02d\:", $1, $2)/ex;
    
    # Also white space before the timezone
    if ($date =~ / ([Z\+\-])([0-9\:]*)$/i)
    {
        # And the time zone may be weird and need reformatting
        my $sign = $1;
        my $nums = $2;
        my $tz = '';
        
        if (uc($sign) eq 'Z')
          { $tz = 'Z'; }
        elsif ($nums =~ /^(\d{0,2})$/)
          { $tz = sprintf('%s%02d00', $sign, $1); }
        elsif ($nums =~ /^(\d{1,2})(\d{2})?$/)
          { $tz = sprintf('%s%02d%02d', $sign, $1, $2); } 
        elsif ($nums =~ /^(\d{0,2})\:(\d{0,2})?$/)
          { $tz = sprintf('%s%02d%02d', $sign, $1, $2); }
          
        $date =~ s/ ([Z\+\-])([0-9\:]*)$/$tz/;
    }
    
    return $date;
}

# TOBY - postprocessing function for *all* datetime formats, recording resolution
sub _do_resolution {
    my %p = @_;

    my $res;
    if (defined $p{ parsed }{ nanosecond })
        { $res = 'nanosecond'; }
    elsif (defined $p{ parsed }{ second })
        { $res = 'second'; }
    elsif (defined $p{ parsed }{ minute })
        { $res = 'minute'; }
    elsif (defined $p{ parsed }{ hour })
        { $res = 'hour'; }
    elsif (defined $p{ parsed }{ day })
        { $res = 'day'; }
    elsif (defined $p{ parsed }{ month })
        { $res = 'month'; }
    elsif (defined $p{ parsed }{ year })
        { $res = 'year'; }
    else
        { $res = 'second'; }
        
    if (defined $p{ parsed }{ hour } && ($p{ parsed }{ hour }==24))
    {
        $res = 'end';
        foreach my $x (qw(nanosecond second minute hour))
        {
            $p{ parsed }{ $x } = 0;
        }
    }

    $p{ self }{ resolution } = $res;
    $p{ self }{ time_zone } 
        = (defined $p{ parsed }{ time_zone }) 
        ? 'time_zone' 
        : undef;

    return 1;
}

1;
