package DateTimeX::Moment::Duration;
use strict;
use warnings;

use Carp;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;

use constant ALL_UNITS => qw/months days minutes seconds nanoseconds/;

use overload (
    fallback => 1,
    '+'      => '_add_overload',
    '-'      => '_subtract_overload',
    '*'      => '_multiply_overload',
    '<=>'    => '_compare_overload',
    'cmp'    => '_compare_overload',
);

sub isa {
    my ($invocant, $a) = @_;
    return !!1 if $a eq 'DateTime::Duration';
    return $invocant->SUPER::isa($a);
}

sub new {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    my %params;
    for my $key (qw/years months weeks days hours minutes seconds nanoseconds/) {
        $params{$key} = exists $args{$key} ? delete $args{$key} : 0;
    }
    if (%args) {
        my $msg = 'Invalid args: '.join ',', keys %args;
        Carp::croak $msg;
    }

    my $self = bless {
        months      => $params{months} + $params{years} * 12,
        days        => $params{days} + $params{weeks} * 7,
        minutes     => $params{minutes} + $params{hours} * 60,
        seconds     => $params{seconds},
        nanoseconds => $params{nanoseconds},
    } => $class;
    return $self->_normalize_nanoseconds();
}

# make the signs of seconds, nanos the same; 0 < abs(nanos) < MAX_NANOS
# NB this requires nanoseconds != 0 (callers check this already)
sub _normalize_nanoseconds {
    my $self = shift;
    return $self unless $self->{nanoseconds};

    my $seconds = $self->{seconds} + $self->{nanoseconds} / 1_000_000_000;
    $self->{seconds}     = int($seconds);
    $self->{nanoseconds} = $self->{nanoseconds} % 1_000_000_000;
    $self->{nanoseconds} -= 1_000_000_000 if $seconds < 0;

    return $self;
}

sub clone { bless {%{$_[0]}} => ref $_[0] }

sub years       { abs(shift->in_units(qw/years/))               }
sub months      { abs(shift->in_units(qw/months years/))        }
sub weeks       { abs(shift->in_units(qw/weeks/))               }
sub days        { abs(shift->in_units(qw/days weeks/))          }
sub hours       { abs(shift->in_units(qw/hours/))               }
sub minutes     { abs(shift->in_units(qw/minutes hours/) )      }
sub seconds     { abs(shift->in_units(qw/seconds/))             }
sub nanoseconds { abs(shift->in_units(qw/nanoseconds seconds/)) }

sub is_positive   { $_[0]->_has_positive  && !$_[0]->_has_negative }
sub is_negative   { !$_[0]->_has_positive && $_[0]->_has_negative }
sub _has_positive { (first { $_ > 0 } values %{$_[0]}) ? 1 : 0 }
sub _has_negative { (first { $_ < 0 } values %{$_[0]}) ? 1 : 0 }

sub is_zero {
    my $self = shift;
    return 0 if first { $_ != 0 } values %$self;
    return 1;
}

sub deltas { %{$_[0]} }

sub delta_months      { shift->{months}      }
sub delta_days        { shift->{days}        }
sub delta_minutes     { shift->{minutes}     }
sub delta_seconds     { shift->{seconds}     }
sub delta_nanoseconds { shift->{nanoseconds} }

sub in_units {
    my $self  = shift;
    my @units = @_;

    my %units = map { $_ => 1 } @units;

    my %ret;

    my ($months, $days, $minutes, $seconds) = @$self{qw/months days minutes seconds/};
    if ($units{years}) {
        $ret{years} = int($months / 12);
        $months -= $ret{years} * 12;
    }

    if ($units{months}) {
        $ret{months} = $months;
    }

    if ($units{weeks}) {
        $ret{weeks} = int($days / 7);
        $days -= $ret{weeks} * 7;
    }

    if ($units{days}) {
        $ret{days} = $days;
    }

    if ($units{hours}) {
        $ret{hours} = int($minutes / 60);
        $minutes -= $ret{hours} * 60;
    }

    if ($units{minutes}) {
        $ret{minutes} = $minutes;
    }

    if ($units{seconds}) {
        $ret{seconds} = $seconds;
        $seconds = 0;
    }

    if ($units{nanoseconds}) {
        $ret{nanoseconds} = $seconds * 1_000_000_000 + $self->{nanoseconds};
    }

    return wantarray ? @ret{@units} : $ret{$units[0]};
}

# XXX: limit mode only
sub is_wrap_mode      { 0 }
sub is_limit_mode     { 1 }
sub is_preserve_mode  { 0 }
sub end_of_month_mode { 'limit' }

sub calendar_duration {
    my $self = shift;
    my $clone = $self->clone;
    $clone->{$_} = 0 for qw/minutes seconds nanoseconds/;
    return $clone;
}

sub clock_duration {
    my $self = shift;
    my $clone = $self->clone;
    $clone->{$_} = 0 for qw/months days/;
    return $clone;
}

sub inverse {
    my $self = shift;
    my $clone = $self->clone;
    $clone->{$_} *= -1 for keys %$clone;
    return $clone;
}

sub add_duration {
    my ($lhs, $rhs) = @_;
    $lhs->{$_} += $rhs->{$_} for ALL_UNITS;
    return $lhs->_normalize_nanoseconds();
}

sub add {
    my $self = shift;
    my $class = ref $self;

    my $lhs = $self;
    my $rhs = $class->new(@_);
    return $lhs->add_duration($rhs);
}

sub subtract_duration { $_[0]->add_duration($_[1]->inverse) }

sub subtract {
    my $self = shift;
    my $class = ref $self;

    my $lhs = $self;
    my $rhs = $class->new(@_);
    return $lhs->subtract_duration($rhs);
}

sub multiply {
    my ($lhs, $rhs) = @_;
    $lhs->{$_} *= $rhs for ALL_UNITS;
    return $lhs->_normalize_nanoseconds();
}

sub compare {
    my ($class, $lhs, $rhs, $base) = @_;
    $base ||= DateTimeX::Moment->now;
    return DateTimeX::Moment->compare(
        $base->clone->add_duration($lhs),
        $base->clone->add_duration($rhs)
    );
}

sub _isa_datetime { blessed $_[0] && $_[0]->isa('DateTime') }

sub _add_overload {
    my ($lhs, $rhs, $flip) = @_;
    ($lhs, $rhs) = ($rhs, $lhs) if $flip;

    if (_isa_datetime($rhs)) {
        $rhs->add_duration($lhs);
        return;
    }

    # will also work if $lhs is a DateTime.pm object
    return $lhs->clone->add_duration($rhs);
}

sub _subtract_overload {
    my ($lhs, $rhs, $flip) = @_;
    ($lhs, $rhs) = ($rhs, $lhs) if $flip;

    if (_isa_datetime($rhs)) {
        Carp::croak('Cannot subtract a DateTimeX::Moment object from a DateTimeX::Moment::Duration object');
    }

    return $lhs->clone->subtract_duration($rhs);
}

sub _multiply_overload {
    my ($lhs, $rhs) = @_;
    return $lhs->clone->multiply($rhs);
}

sub _compare_overload {
    Carp::croak('DateTimeX::Moment::Duration does not overload comparison.  See the documentation on the compare() method for details.');
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

DateTimeX::Moment::Duration - TODO

=head1 SYNOPSIS

    use DateTimeX::Moment::Duration;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<DateTime::Duration>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
