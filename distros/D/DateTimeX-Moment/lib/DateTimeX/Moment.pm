package DateTimeX::Moment;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.06";

use Time::Moment 0.38;
use DateTimeX::Moment::Duration;
use DateTime::Locale;
use DateTime::TimeZone;
use Scalar::Util qw/blessed/;
use Carp ();
use POSIX qw/floor/;
use Class::Inspector;

use overload (
    'fallback' => 1,
    '<=>'      => \&_compare_overload,
    'cmp'      => \&_string_compare_overload,
    '""'       => \&_stringify,
    '-'        => \&_subtract_overload,
    '+'        => \&_add_overload,
    'eq'       => \&_string_equals_overload,
    'ne'       => \&_string_not_equals_overload,
);

use Class::Accessor::Lite ro => [qw/time_zone locale formatter/];

BEGIN {
    local $@;
    if (eval { require Data::Util; 1 }) {
        *is_instance = \&Data::Util::is_instance;
    }
    else {
        *is_instance = sub { blessed($_[0]) && $_[0]->isa($_[1]) };
    }
}

my $_DEFAULT_LOCALE = DateTime::Locale->load('en_US');
my $_FLOATING_TIME_ZONE = DateTime::TimeZone->new(name => 'floating');
my $_UTC_TIME_ZONE = DateTime::TimeZone->new(name => 'UTC');
sub _default_locale { $_DEFAULT_LOCALE }
sub _default_formatter { undef }
sub _default_time_zone { $_FLOATING_TIME_ZONE }

sub _inflate_locale {
    my ($class, $locale) = @_;
    return $class->_default_locale unless defined $locale;
    return $locale if _isa_locale($locale);
    return DateTime::Locale->load($locale);
}

sub _inflate_formatter {
    my ($class, $formatter) = @_;
    return $class->_default_formatter unless defined $formatter;
    return $formatter if _isa_formatter($formatter);
    Carp::croak 'formatter should can format_datetime.';
}

sub _inflate_time_zone {
    my ($class, $time_zone) = @_;
    return $class->_default_time_zone unless defined $time_zone;
    return $time_zone if _isa_time_zone($time_zone);
    return DateTime::TimeZone->new(name => $time_zone);
}

sub isa {
    my ($invocant, $a) = @_;
    return !!1 if $a eq 'DateTime';
    return $invocant->SUPER::isa($a);
}

sub _moment_resolve_instant {
    my ($moment, $time_zone) = @_;
    if ($time_zone->is_floating) {
        return $moment->with_offset_same_local(0);
    }
    else {
        my $offset = $time_zone->offset_for_datetime($moment) / 60;
        return $moment->with_offset_same_instant($offset);
    }
}

sub _moment_resolve_local {
    my ($moment, $time_zone) = @_;
    if ($time_zone->is_floating) {
        return $moment->with_offset_same_local(0);
    }
    else {
        my $offset = $time_zone->offset_for_local_datetime($moment) / 60;
        return $moment->with_offset_same_local($offset);
    }
}

sub new {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    $args{locale} = delete $args{language} if exists $args{language};
    my $locale    = delete $args{locale}    || $class->_default_locale;
    my $formatter = delete $args{formatter} || $class->_default_formatter;
    my $time_zone = delete $args{time_zone} || $class->_default_time_zone;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    my $self = bless {
        _moment   => Time::Moment->new(%args),
        locale    => $class->_inflate_locale($locale),
        formatter => $class->_inflate_formatter($formatter),
        time_zone => $class->_inflate_time_zone($time_zone),
    } => $class;
    return $self->_adjust_to_current_offset();
}

sub now {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    $args{locale} = delete $args{language} if exists $args{language};
    my $locale    = delete $args{locale}    || $class->_default_locale;
    my $formatter = delete $args{formatter} || $class->_default_formatter;
    my $time_zone = exists $args{time_zone} ? $class->_inflate_time_zone(delete $args{time_zone}) : $_UTC_TIME_ZONE;
    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    return bless {
        _moment   => _moment_resolve_instant(Time::Moment->now, $time_zone),
        locale    => $class->_inflate_locale($locale),
        formatter => $class->_inflate_formatter($formatter),
        time_zone => $time_zone,
    } => $class;
}

sub from_object {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    my $object = delete $args{object}
        or Carp::croak 'object is required.';

    $args{locale} = delete $args{language} if exists $args{language};
    my $locale    = delete $args{locale}    || $class->_default_locale;
    my $formatter = delete $args{formatter} || $class->_default_formatter;
    my $time_zone = $object->can('time_zone') ? $object->time_zone : $_FLOATING_TIME_ZONE;
    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    if ($object->isa(__PACKAGE__)) {
        my $self = $object->clone;
        $self->set_locale($locale);
        $self->set_formatter($formatter) if $formatter;
        return $self;
    }

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    my $moment;
    if (_isa_moment_convertable($object)) {
        $moment = Time::Moment->from_object($object);
    }
    else {
        require DateTime; # fallback
        my $object = DateTime->from_object(object => $object);
        if ($object->time_zone->is_floating) {
            $time_zone = $object->time_zone;
            $object->set_time_zone($_UTC_TIME_ZONE);
        }
        $moment = Time::Moment->from_object($object);
    }

    return bless {
        _moment   => _moment_resolve_instant($moment, $time_zone),
        locale    => $class->_inflate_locale($locale),
        formatter => $class->_inflate_formatter($formatter),
        time_zone => $time_zone,
    } => $class;
}

sub from_epoch {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    Carp::croak 'epoch is required.' unless exists $args{epoch};

    my $epoch = delete $args{epoch};

    $args{locale} = delete $args{language} if exists $args{language};
    my $locale    = delete $args{locale}    || $class->_default_locale;
    my $formatter = delete $args{formatter} || $class->_default_formatter;
    my $time_zone = exists $args{time_zone} ? $class->_inflate_time_zone(delete $args{time_zone}) : $_UTC_TIME_ZONE;
    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    my $moment = do {
        local $SIG{__WARN__} = sub { die @_ };
        Time::Moment->from_epoch($epoch);
    };

    return bless {
        _moment   => _moment_resolve_instant($moment, $time_zone),
        locale    => $class->_inflate_locale($locale),
        formatter => $class->_inflate_formatter($formatter),
        time_zone => $time_zone,
    } => $class;
}

sub today { shift->now(@_)->truncate(to => 'day') }

sub last_day_of_month {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    for my $key (qw/year month/) {
        Carp::croak "Parameter: $key is required." unless defined $args{$key};
    }
    Carp::croak q{Parameter 'month' is out of the range [1, 12]} if 0 > $args{month} || $args{month} > 12;

    my ($year, $month) = @args{qw/year month/};
    my $day = _month_length($year, $month);

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    return $class->new(%args, day => $day);
}

my @_MONTH_LENGTH = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
sub _month_length {
    my ($year, $month) = @_;
    my $day = $_MONTH_LENGTH[$month-1];
    $day++ if $month == 2 && _is_leap_year($year);
    return $day;
}

sub _is_leap_year {
    my $year = shift;
    return 0 if $year % 4;
    return 1 if $year % 100;
    return 0 if $year % 400;
    return 1;
}

sub from_day_of_year {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    for my $key (qw/year day_of_year/) {
        Carp::croak "Parameter: $key is required." unless defined $args{$key};
    }

    my $day_of_year = delete $args{day_of_year};

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $self = $class->new(%args);
    $self->{_moment} = $self->{_moment}->with_day_of_year($day_of_year);
    return $self->_adjust_to_current_offset();
}

sub _adjust_to_current_offset {
    my $self = shift;
    return $self if $self->{time_zone}->is_floating;

    my $offset = $self->{time_zone}->offset_for_local_datetime($self->{_moment}) / 60;
    $self->{_moment} = $self->{_moment}->with_offset_same_local($offset);

    return $self;
}

sub clone { bless { %{$_[0]} }, ref $_[0] }

# Date / Calendar
sub year                 { $_[0]->{_moment}->year                             }
sub year_0               { $_[0]->{_moment}->year - 1                         }
sub month_0              { $_[0]->{_moment}->month - 1                        }
sub month                { $_[0]->{_moment}->month                            }
sub day_of_week          { $_[0]->{_moment}->day_of_week                      }
sub day_of_week_0        { $_[0]->{_moment}->day_of_week - 1                  }
sub day_of_month         { $_[0]->{_moment}->day_of_month                     }
sub day_of_month_0       { $_[0]->{_moment}->day_of_month - 1                 }
sub day_of_quarter       { $_[0]->{_moment}->day_of_quarter                   }
sub day_of_quarter_0     { $_[0]->{_moment}->day_of_quarter - 1               }
sub day_of_year          { $_[0]->{_moment}->day_of_year                      }
sub day_of_year_0        { $_[0]->{_moment}->day_of_year - 1                  }
sub quarter              { $_[0]->{_moment}->quarter                          }
sub quarter_0            { $_[0]->{_moment}->quarter - 1                      }
sub weekday_of_month     { int(($_[0]->{_moment}->day_of_month + 6) / 7)      }
sub week_number          { $_[0]->{_moment}->week                             }
sub week_year            { $_[0]->{_moment}->strftime('%G') + 0               }

sub week {
    return ($_[0]->week_year, $_[0]->week_number);
}
sub week_of_month {
    my $moment = shift->{_moment};
    my $thu    = $moment->day_of_month + 4 - $moment->day_of_week;
    return int(($thu + 6) / 7);
}

sub is_leap_year         { $_[0]->{_moment}->is_leap_year + 0                 }

# Time of Day
sub hour                 { $_[0]->{_moment}->hour                             }
sub hour_1               { $_[0]->{_moment}->hour || 24                       }
sub hour_12              { $_[0]->hour_12_0 || 12                             }
sub hour_12_0            { $_[0]->{_moment}->hour % 12                        }
sub minute               { $_[0]->{_moment}->minute                           }
sub second               { $_[0]->{_moment}->second                           }
sub nanosecond           { $_[0]->{_moment}->nanosecond                       }
sub millisecond          { $_[0]->{_moment}->millisecond                      }
sub microsecond          { $_[0]->{_moment}->microsecond                      }

sub fractional_second {
    my $moment = $_[0]->{_moment};
    return $moment->second + $moment->nanosecond / 1_000_000_000;
}

sub leap_seconds         { 0                                                  }
sub is_finite            { 1                                                  }
sub is_infinite          { 0                                                  }

# Absolute values
sub epoch                { $_[0]->{_moment}->epoch                            }

sub hires_epoch {
    my $moment = $_[0]->{_moment};
    return $moment->epoch + $moment->nanosecond / 1_000_000_000;
}

sub mjd                  { $_[0]->{_moment}->mjd                              }
sub jd                   { $_[0]->{_moment}->jd                               }
sub rd                   { $_[0]->{_moment}->rd                               }
sub utc_rd_values        { $_[0]->{_moment}->utc_rd_values                    }
sub local_rd_values      { $_[0]->{_moment}->local_rd_values                  }
sub utc_rd_as_seconds    { $_[0]->{_moment}->utc_rd_as_seconds                }
sub local_rd_as_seconds  { $_[0]->{_moment}->local_rd_as_seconds              }

# Time zone
sub offset               { $_[0]->{_moment}->offset * 60                      }
sub is_dst               { $_[0]->{time_zone}->is_dst_for_datetime($_[0])     }
sub time_zone_long_name  { $_[0]->{time_zone}->name                           }
sub time_zone_short_name { $_[0]->{time_zone}->short_name_for_datetime($_[0]) }

sub utc_year             { $_[0]->{_moment}->utc_year                         }

# Locale
sub ce_year              { $_[0]->{_moment}->year                             }
sub era_name             { $_[0]->{locale}->era_wide->[1]                     }
sub era_abbr             { $_[0]->{locale}->era_abbreviated->[1]              }
sub christian_era        { 'AD'                                               }
sub secular_era          { 'CE'                                               }

sub year_with_era {
    $_[0]->ce_year . $_[0]->era_abbr;
}

sub year_with_christian_era {
    $_[0]->ce_year . $_[0]->christian_era;
}

sub year_with_secular_era {
    $_[0]->ce_year . $_[0]->secular_era;
}

sub month_name {
    $_[0]->{locale}->month_format_wide->[ $_[0]->month_0 ];
}
sub month_abbr {
    $_[0]->{locale}->month_format_abbreviated->[ $_[0]->month_0 ];
}
sub day_name {
    $_[0]->{locale}->day_format_wide->[ $_[0]->day_of_week_0];
}
sub day_abbr {
    $_[0]->{locale}->day_format_abbreviated->[ $_[0]->day_of_week_0 ];
}
sub am_or_pm {
    $_[0]->{locale}->am_pm_abbreviated->[ $_[0]->{_moment}->hour < 12 ? 0 : 1 ];
}
sub quarter_name {
    $_[0]->{locale}->quarter_format_wide->[ $_[0]->quarter_0 ];
}
sub quarter_abbr {
    $_[0]->{locale}->quarter_format_abbreviated->[ $_[0]->quarter_0 ];
}

sub local_day_of_week {
    my $moment = $_[0]->{_moment};
    return 1 + ($moment->day_of_week - $_[0]->{locale}->first_day_of_week) % 7;
}

sub _escape_pct {
    (my $string = $_[0]) =~ s/%/%%/g; $string;
}

sub ymd {
    my $moment = shift->{_moment};
    my $hyphen = !defined $_[0] || $_[0] eq '-';
    my $format = $hyphen ? '%Y-%m-%d' : join(_escape_pct($_[0]), qw(%Y %m %d));
    return $moment->strftime($format);
}

sub mdy {
    my $moment = shift->{_moment};
    my $hyphen = !defined $_[0] || $_[0] eq '-';
    my $format = $hyphen ? '%m-%d-%Y' : join(_escape_pct($_[0]), qw(%m %d %Y));
    return $moment->strftime($format);
}

sub dmy {
    my $moment = shift->{_moment};
    my $hyphen = !defined $_[0] || $_[0] eq '-';
    my $format = $hyphen ? '%d-%m-%Y' : join(_escape_pct($_[0]), qw(%d %m %Y));
    return $moment->strftime($format);
}

sub hms {
    my $moment = shift->{_moment};
    my $colon  = !defined $_[0] || $_[0] eq ':';
    my $format = $colon ? '%H:%M:%S' : join(_escape_pct($_[0]), qw(%H %M %S));
    return $moment->strftime($format);
}

sub iso8601 {
    return $_[0]->{_moment}->strftime('%Y-%m-%dT%H:%M:%S');
}

sub subtract_datetime {
    my ($lhs, $rhs) = @_;
    my $class = ref $lhs;

    # normalize
    $rhs = $class->from_object(object => $rhs) unless $rhs->isa($class);
    $rhs = $rhs->clone->set_time_zone($lhs->time_zone) unless $lhs->time_zone->name eq $rhs->time_zone->name;

    my ($lhs_moment, $rhs_moment) = map { $_->{_moment} } ($lhs, $rhs);

    my $sign = $lhs_moment < $rhs_moment ? -1 : 1;
    ($lhs_moment, $rhs_moment) = ($rhs_moment, $lhs_moment) if $sign == -1;

    my $months      = $rhs_moment->delta_months($lhs_moment);
    my $days        = $lhs_moment->day_of_month - $rhs_moment->day_of_month;
    my $minutes     = $lhs_moment->minute_of_day - $rhs_moment->minute_of_day;
    my $seconds     = $lhs_moment->second - $rhs_moment->second;
    my $nanoseconds = $lhs_moment->nanosecond - $rhs_moment->nanosecond;

    my $time_zone = $lhs->{time_zone};
    if ($time_zone->has_dst_changes) {
        my $lhs_dst = $time_zone->is_dst_for_datetime($lhs_moment);
        my $rhs_dst = $time_zone->is_dst_for_datetime($rhs_moment);

        if ($lhs_dst != $rhs_dst) {
            my $previous = eval {
                _moment_resolve_local($lhs_moment->minus_days(1), $time_zone);
            };

            if (defined $previous) {
                my $previous_dst = $time_zone->is_dst_for_datetime($previous);
                if ($lhs_dst) {
                    $minutes -= 60 if !$previous_dst;
                }
                else {
                    $minutes += 60 if $previous_dst;
                }
            }
        }
    }

    if ($nanoseconds < 0) {
        $nanoseconds += 1_000_000_000;
        $seconds--;
    }
    if ($seconds < 0) {
        $seconds += 60;
        $minutes--;
    }
    if ($minutes < 0) {
        $minutes += 24 * 60;
        $days--;
    }
    if ($days < 0) {
        $days   += $rhs_moment->length_of_month;
        $months -= $lhs_moment->day_of_month > $rhs_moment->day_of_month;
    }

    return DateTimeX::Moment::Duration->new(
        months      => $sign * $months,
        days        => $sign * $days,
        minutes     => $sign * $minutes,
        seconds     => $sign * $seconds,
        nanoseconds => $sign * $nanoseconds,
    );
}

sub subtract_datetime_absolute {
    my ($lhs, $rhs) = @_;
    my $class = ref $lhs;

    $rhs = $class->from_object(object => $rhs)
      unless $rhs->isa($class);

    my ($lhs_moment, $rhs_moment) = ($lhs->{_moment}, $rhs->{_moment});

    my $seconds     = $rhs_moment->delta_seconds($lhs_moment);
    my $nanoseconds = $rhs_moment->plus_seconds($seconds)
                                 ->delta_nanoseconds($lhs_moment);

    return DateTimeX::Moment::Duration->new(
        seconds     => $seconds,
        nanoseconds => $nanoseconds,
    );
}

sub _stringify {
    my $self = shift;
    return $self->iso8601 unless defined $self->{formatter};
    return $self->{formatter}->format_datetime($self);
}

sub _compare_overload {
    my ($lhs, $rhs, $flip) = @_;
    return undef unless defined $rhs;
    return $flip ? -$lhs->compare($rhs) : $lhs->compare($rhs);
}

sub _string_compare_overload {
    my ($lhs, $rhs, $flip) = @_;
    return undef unless defined $rhs;
    goto \&_compare_overload if _isa_datetime_compareble($rhs);

    # One is a DateTimeX::Moment object, one isn't. Just stringify and compare.
    my $sign = $flip ? -1 : 1;
    return $sign * ("$lhs" cmp "$rhs");
}

sub _string_not_equals_overload { !_string_equals_overload(@_) }
sub _string_equals_overload {
    my ($class, $lhs, $rhs) = ref $_[0] ? (ref $_[0], @_) : @_;
    return undef unless defined $rhs;
    return !$class->compare($lhs, $rhs) if _isa_datetime_compareble($rhs);
    return "$lhs" eq "$rhs";
}

sub _add_overload {
    my ($dt, $dur, $flip) = @_;
    ($dur, $dt) = ($dt, $dur) if $flip;

    unless (_isa_duration($dur)) {
        my $class = ref $dt;
        Carp::croak("Cannot add $dur to a $class object ($dt).\n"
                    . ' Only a DateTime::Duration object can '
                    . " be added to a $class object.");
    }

    return $dt->clone->add_duration($dur);
}

sub _subtract_overload {
    my ($date1, $date2, $flip) = @_;
    ($date2, $date1) = ($date1, $date2) if $flip;

    if (_isa_duration($date2)) {
        my $new = $date1->clone;
        $new->add_duration($date2->inverse);
        return $new;
    }
    elsif (_isa_datetime($date2)) {
        return $date1->subtract_datetime($date2);
    }

    my $class = ref $date1;
    Carp::croak(
        "Cannot subtract $date2 from a $class object ($date1).\n"
        . ' Only a DateTime::Duration or DateTimeX::Moment object can '
        . " be subtracted from a $class object." );
}

sub compare { shift->_compare(@_, 0) }
sub compare_ignore_floating { shift->_compare(@_, 1) }

sub _compare {
    my ($class, $lhs, $rhs, $consistent) = ref $_[0] ? (__PACKAGE__, @_) : @_;
    return undef unless defined $rhs;

    if (!_isa_datetime_compareble($lhs) || !_isa_datetime_compareble($rhs)) {
        Carp::croak("A DateTimeX::Moment object can only be compared to another DateTimeX::Moment object ($lhs, $rhs).");
    }

    if (!$consistent && $lhs->can('time_zone') && $rhs->can('time_zone')) {
        my $is_floating1 = $lhs->time_zone->is_floating;
        my $is_floating2 = $rhs->time_zone->is_floating;

        if ($is_floating1 && !$is_floating2) {
            $lhs = $lhs->clone->set_time_zone($rhs->time_zone);
        }
        elsif ($is_floating2 && !$is_floating1) {
            $rhs = $rhs->clone->set_time_zone($lhs->time_zone);
        }
    }

    if ($lhs->isa(__PACKAGE__) && $rhs->isa(__PACKAGE__)) {
        return $lhs->{_moment}->compare($rhs->{_moment});
    }

    my @lhs_components = $lhs->utc_rd_values;
    my @rhs_components = $rhs->utc_rd_values;

    for my $i (0 .. 2) {
        return $lhs_components[$i] <=> $rhs_components[$i] if $lhs_components[$i] != $rhs_components[$i];
    }

    return 0;
}

sub set {
    my $self = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    my $moment = $self->{_moment};
    my %params = (
        year       => $moment->year,
        month      => $moment->month,
        day        => $moment->day_of_month,
        hour       => $moment->hour,
        minute     => $moment->minute,
        second     => $moment->second,
        nanosecond => $moment->nanosecond,
    );
    for my $component (keys %args) {
        next unless exists $params{$component};
        $params{$component} = delete $args{$component};
    }
    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    my $result = Time::Moment->new(%params, offset => $moment->offset);
    if (!$moment->is_equal($result)) {
        $self->{_moment} = _moment_resolve_local($result, $self->{time_zone});
    }
    return $self;
}

sub set_year       { $_[0]->set(year       => $_[1]) }
sub set_month      { $_[0]->set(month      => $_[1]) }
sub set_day        { $_[0]->set(day        => $_[1]) }
sub set_hour       { $_[0]->set(hour       => $_[1]) }
sub set_minute     { $_[0]->set(minute     => $_[1]) }
sub set_second     { $_[0]->set(second     => $_[1]) }
sub set_nanosecond { $_[0]->set(nanosecond => $_[1]) }

sub set_time_zone {
    my ($self, $time_zone) = @_;
    Carp::croak 'required time_zone' if @_ != 2;

    $time_zone = $self->_inflate_time_zone($time_zone);
    return $self if $time_zone == $self->{time_zone};
    return $self if $time_zone->name eq $self->{time_zone}->name;

    $self->{_moment} = do {
        if ($self->{time_zone}->is_floating) {
            _moment_resolve_local($self->{_moment}, $time_zone)
        }
        else {
            _moment_resolve_instant($self->{_moment}, $time_zone);
        }
    };
    $self->{time_zone} = $time_zone;
    return $self;
}

sub set_locale {
    my ($self, $locale) = @_;
    Carp::croak 'required locale' if @_ != 2;
    $self->{locale} = $self->_inflate_locale($locale);
    return $self;
}

sub set_formatter {
    my ($self, $formatter) = @_;
    $self->{formatter} = $self->_inflate_formatter($formatter);
    return $self;
}

sub add      { shift->_calc_date(plus  => @_) }
sub subtract { shift->_calc_date(minus => @_) }

sub _calc_date {
    my $self = shift;
    my $type = shift;
    return $self->_calc_duration($type => @_) if @_ == 1 && _isa_duration($_[0]);

    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    my $moment = $self->{_moment};

    {
        if (exists $args{years} && exists $args{months}) {
            my $factor = ($type eq 'plus') ? 12 : -12;
            $args{months} += delete($args{years}) * $factor;
        }

        my $result = $moment;
        for my $unit (qw/weeks days months years/) {
            next unless exists $args{$unit};
            my $method = $type.'_'.$unit;
            $result = $result->$method(delete $args{$unit});
        }

        if (!$moment->is_equal($result)) {
            $moment = _moment_resolve_local($result, $self->{time_zone});
        }
    }

    {
        my $result = $moment;
        for my $unit (qw/nanoseconds seconds minutes hours/) {
            next unless exists $args{$unit};
            my $method = $type.'_'.$unit;
            $result = $result->$method(delete $args{$unit});
        }

        if (!$moment->is_equal($result)) {
            $moment = _moment_resolve_instant($result, $self->{time_zone});
        }
    }

    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    $self->{_moment} = $moment;
    return $self;
}

sub delta_md {
    my ($lhs, $rhs) = @_;
    my $class = ref $lhs;

    $rhs = $class->from_object(object => $rhs)
      unless $rhs->isa($class);

    my ($lhs_moment, $rhs_moment) = ($lhs->{_moment}, $rhs->{_moment});

    if ($lhs_moment->rd < $rhs_moment->rd) {
        ($lhs_moment, $rhs_moment) = ($rhs_moment, $lhs_moment);
    }

    my $months = $rhs_moment->delta_months($lhs_moment);
    my $days   = $lhs_moment->day_of_month - $rhs_moment->day_of_month;

    if ($days < 0) {
        $days   += $rhs_moment->length_of_month;
        $months -= $lhs_moment->day_of_month > $rhs_moment->day_of_month;
    }

    return DateTimeX::Moment::Duration->new(
        months => $months,
        days   => $days,
    );
}

sub delta_days {
    my ($lhs, $rhs) = @_;
    my $class = ref $lhs;

    $rhs = $class->from_object(object => $rhs)
      unless $rhs->isa($class);

    return DateTimeX::Moment::Duration->new(
        days => abs($lhs->{_moment}->delta_days($rhs->{_moment}))
    );
}

sub delta_ms {
    my ($lhs, $rhs) = reverse sort { $a <=> $b } @_;
    my $days = floor($lhs->{_moment}->jd - $rhs->{_moment}->jd);
    my $duration = $lhs->subtract_datetime($rhs);
    return DateTimeX::Moment::Duration->new(
        hours   => $duration->hours + ($days * 24),
        minutes => $duration->minutes,
        seconds => $duration->seconds,
    );
}

sub delta_years        { shift->_delta(years        => @_) }
sub delta_months       { shift->_delta(months       => @_) }
sub delta_weeks        { shift->_delta(weeks        => @_) }
#sub delta_days         { shift->_delta(days         => @_) }
sub delta_hours        { shift->_delta(hours        => @_) }
sub delta_minutes      { shift->_delta(minutes      => @_) }
sub delta_seconds      { shift->_delta(seconds      => @_) }
sub delta_milliseconds { shift->_delta(milliseconds => @_) }
sub delta_microseconds { shift->_delta(microseconds => @_) }
sub delta_nanoseconds  { shift->_delta(nanoseconds  => @_) }

sub _delta {
    my ($self, $unit, $another) = @_;
    my $lhs = $self->{_moment};
    my $rhs = $another->isa(__PACKAGE__) ? $another->{_moment} : Time::Moment->from_object($another);
       $rhs = Time::Moment->from_object($rhs) unless _isa_moment($rhs);

    my $method = "delta_$unit";
    my $diff = $lhs > $rhs ? $rhs->$method($lhs) : $lhs->$method($rhs);

    # normalize
    if ($unit eq 'milliseconds') {
        $unit = 'nanoseconds';
        $diff *= 1_000_000;
    }
    elsif ($unit eq 'microseconds') {
        $unit = 'nanoseconds';
        $diff *= 1_000;
    }

    return DateTimeX::Moment::Duration->new($unit => $diff);
}

# strftime
{
    my %CUSTOM_HANDLER = (
        a => sub { $_[0]->day_abbr },
        A => sub { $_[0]->day_name },
        b => sub { $_[0]->month_abbr },
        B => sub { $_[0]->month_name },
        c => sub { $_[0]->format_cldr($_[0]->{locale}->datetime_format_default()) },
        p => sub { $_[0]->am_or_pm },
        P => sub { lc $_[0]->am_or_pm },
        r => sub { $_[0]->strftime('%I:%M:%S %p') },
        x => sub { $_[0]->format_cldr($_[0]->{locale}->date_format_default()) },
        X => sub { $_[0]->format_cldr($_[0]->{locale}->time_format_default()) },
        Z => sub { $_[0]->{time_zone}->short_name_for_datetime($_[0]) },
    );

    my $CUSTOM_HANDLER_REGEXP = '(?:(?<=[^%])((?:%%)*)|\A)%(['.(join '', keys %CUSTOM_HANDLER).'])';

    sub strftime {
        my ($self, @formats) = @_;
        my $moment = $self->{_moment};

        my @ret;
        for my $format (@formats) {
            # XXX: follow locale/time_zone
            $format =~ s/$CUSTOM_HANDLER_REGEXP/($1||'').$CUSTOM_HANDLER{$2}->($self)/omsge;
            $format =~ s/(?:(?<=[^%])((?:%%)*)|\A)%\{(\w+)\}/($1||'').($self->can($2) ? $self->$2 : "%{$2}")/omsge;

            my $ret = $moment->strftime($format);
            return $ret unless wantarray;

            push @ret => $ret;
        }

        return @ret;
    }
}

sub format_cldr {
    my $self = shift;

    # fallback
    require DateTime;
    return DateTime->from_object(
        object => $self,
        locale => $self->{locale},
    )->format_cldr(@_);
}

sub truncate :method {
    my $self = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    my $to = delete $args{to}
        or Carp::croak "Parameter: to is required.";
    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    my $moment = $self->{_moment};
    my $result = do {
        if ($to eq 'year') {
            $moment->with_day_of_year(1)
                   ->at_midnight;
        }
        elsif ($to eq 'month') {
            $moment->with_day_of_month(1)
                   ->at_midnight;
        }
        elsif ($to eq 'week')   {
            $moment->with_day_of_week(1)
                   ->at_midnight;
        }
        elsif ($to eq 'local_week') {
            my $dow = $self->{locale}->first_day_of_week;
            $moment->minus_days(($moment->day_of_week - $dow) % 7)
                   ->at_midnight;
        }
        elsif ($to eq 'day') {
            $moment->at_midnight;
        }
        elsif ($to eq 'hour') {
            $moment->with_precision(-2);
        }
        elsif ($to eq 'minute') {
            $moment->with_precision(-1);
        }
        elsif ($to eq 'second') {
            $moment->with_precision(0);
        }
        else {
            Carp::croak "The 'to' parameter '$to' is unsupported.";
        }
    };

    if (!$moment->is_equal($result)) {
        $self->{_moment} = _moment_resolve_local($result, $self->{time_zone});
    }
    return $self;
}

my %CALC_DURATION_METHOD = (plus => 'add_duration', minus => 'subtract_duration');
sub _calc_duration {
    my ($self, $type, $duration) = @_;
    my $method = $CALC_DURATION_METHOD{$type};
    return $self->$method($duration);
}

sub subtract_duration { $_[0]->add_duration($_[1]->inverse) }
sub add_duration {
    my ($self, $duration) = @_;
    Carp::croak 'required duration object' unless _isa_duration($duration);

    # simple optimization
    return $self if $duration->is_zero;

    if (!$duration->is_limit_mode) {
        Carp::croak 'DateTimeX::Moment supports limit mode only.';
    }

    return $self->add($duration->deltas);
}

# internal utilities
sub _isa_locale { is_instance($_[0] => 'DateTime::Locale::FromData') || is_instance($_[0] => 'DateTime::Locale::Base') }
sub _isa_formatter { _isa_invocant($_[0]) && $_[0]->can('format_datetime') }
sub _isa_time_zone { is_instance($_[0] => 'DateTime::TimeZone') }
sub _isa_datetime { is_instance($_[0] => 'DateTime') }
sub _isa_datetime_compareble { blessed($_[0]) && $_[0]->can('utc_rd_values') }
sub _isa_duration { is_instance($_[0] => 'DateTime::Duration') }
sub _isa_moment { is_instance($_[0] => 'Time::Moment') }
sub _isa_moment_convertable { blessed($_[0]) && $_[0]->can('__as_Time_Moment') }
sub _isa_invocant { blessed $_[0] || Class::Inspector->loaded("$_[0]") }

# define aliases
{
    my %aliases = (
        month            => [qw/mon/],
        day_of_month     => [qw/day mday/],
        day_of_month_0   => [qw/day_0 mday_0/],
        day_of_week      => [qw/wday dow/],
        day_of_week_0    => [qw/wday_0 dow_0/],
        day_of_quarter   => [qw/doq/],
        day_of_quarter_0 => [qw/doq_0/],
        day_of_year      => [qw/doy/],
        day_of_year_0    => [qw/doy_0/],
        ymd              => [qw/date/],
        hms              => [qw/time/],
        iso8601          => [qw/datetime/],
        minute           => [qw/min/],
        second           => [qw/sec/],
        locale           => [qw/language/],
        era_abbr         => [qw/era/],
    );

    for my $src (keys %aliases) {
        my $code = do {
            no strict qw/refs/;
            \&{$src};
        };

        for my $dst (@{ $aliases{$src} }) {
            no strict qw/refs/;
            *{$dst} = $code;
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

DateTimeX::Moment - EXPERIMENTAL DateTime like interface for Time::Moment

=head1 SYNOPSIS

  use DateTimeX::Moment;

  $dt = DateTimeX::Moment->new(
      year       => 1964,
      month      => 10,
      day        => 16,
      hour       => 16,
      minute     => 12,
      second     => 47,
      nanosecond => 500000000,
      time_zone  => 'Asia/Taipei',
  );

  $dt = DateTimeX::Moment->from_epoch( epoch => $epoch );
  $dt = DateTimeX::Moment->now; # same as ( epoch => time() )

  $year   = $dt->year;
  $month  = $dt->month;          # 1-12

  $day    = $dt->day;            # 1-31

  $dow    = $dt->day_of_week;    # 1-7 (Monday is 1)

  $hour   = $dt->hour;           # 0-23
  $minute = $dt->minute;         # 0-59

  $second = $dt->second;         # 0-61 (leap seconds!)

  $doy    = $dt->day_of_year;    # 1-366 (leap years)

  $doq    = $dt->day_of_quarter; # 1..

  $qtr    = $dt->quarter;        # 1-4

  # all of the start-at-1 methods above have corresponding start-at-0
  # methods, such as $dt->day_of_month_0, $dt->month_0 and so on

  $ymd    = $dt->ymd;           # 2002-12-06
  $ymd    = $dt->ymd('/');      # 2002/12/06

  $mdy    = $dt->mdy;           # 12-06-2002
  $mdy    = $dt->mdy('/');      # 12/06/2002

  $dmy    = $dt->dmy;           # 06-12-2002
  $dmy    = $dt->dmy('/');      # 06/12/2002

  $hms    = $dt->hms;           # 14:02:29
  $hms    = $dt->hms('!');      # 14!02!29

  $is_leap  = $dt->is_leap_year;

  # these are localizable, see Locales section
  $month_name  = $dt->month_name; # January, February, ...
  $month_abbr  = $dt->month_abbr; # Jan, Feb, ...
  $day_name    = $dt->day_name;   # Monday, Tuesday, ...
  $day_abbr    = $dt->day_abbr;   # Mon, Tue, ...

  # May not work for all possible datetime, see the docs on this
  # method for more details.
  $epoch_time  = $dt->epoch;

  $rhs = $dt + $duration_object;

  $dt3 = $dt - $duration_object;

  $duration_object = $dt - $rhs;

  $dt->set( year => 1882 );

  $dt->set_time_zone( 'America/Chicago' );

  $dt->set_formatter( $formatter );

=head1 BENCHMARK

C<author/benchmark.pl>:

  new()
  Benchmark: timing 100000 iterations of datetime, moment...
    datetime:  4 wallclock secs ( 4.06 usr +  0.01 sys =  4.07 CPU) @ 24570.02/s (n=100000)
      moment:  1 wallclock secs ( 0.62 usr +  0.01 sys =  0.63 CPU) @ 158730.16/s (n=100000)
               Rate datetime   moment
  datetime  24570/s       --     -85%
  moment   158730/s     546%       --
  ----------------------------------------
  now()
  Benchmark: timing 100000 iterations of datetime, moment...
    datetime:  4 wallclock secs ( 4.38 usr +  0.01 sys =  4.39 CPU) @ 22779.04/s (n=100000)
      moment:  1 wallclock secs ( 0.59 usr +  0.00 sys =  0.59 CPU) @ 169491.53/s (n=100000)
               Rate datetime   moment
  datetime  22779/s       --     -87%
  moment   169492/s     644%       --
  ----------------------------------------
  from_epoch()
  Benchmark: timing 100000 iterations of datetime, moment...
    datetime:  4 wallclock secs ( 4.27 usr +  0.01 sys =  4.28 CPU) @ 23364.49/s (n=100000)
      moment:  1 wallclock secs ( 0.63 usr +  0.00 sys =  0.63 CPU) @ 158730.16/s (n=100000)
               Rate datetime   moment
  datetime  23364/s       --     -85%
  moment   158730/s     579%       --
  ----------------------------------------
  calculate()
  Benchmark: timing 100000 iterations of datetime, moment...
    datetime: 20 wallclock secs (20.30 usr +  0.04 sys = 20.34 CPU) @ 4916.42/s (n=100000)
      moment:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 93457.94/s (n=100000)
              Rate datetime   moment
  datetime  4916/s       --     -95%
  moment   93458/s    1801%       --
  ----------------------------------------

=head1 DESCRIPTION

TODO: write it

=head1 METHODS

TODO: write it

=head1 LICENSE

Copyright (C) karupanerura.

This is free software, licensed under:
  The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

