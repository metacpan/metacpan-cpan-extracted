package # hah! take that PAUSE
    Devel::Deprecations::Environmental::MicroDateTime;

use strict;
use warnings;

use overload (
    '<=>'    => '_spaceship',
    bool     => sub { 1 },
    fallback => 1,
);

our $VERSION = '1.101';

sub _spaceship {
    my($self, $other, $swap) = @_;
    ($other, $self) = ($self, $other) if($swap);
    $self->epoch() <=> $other->epoch();
}

sub from_epoch {
    my($class, %args) = @_;
    return bless({ %args }, $class);
}

# This exists only because Windows is a brain-dead piece of shit
# whose POSIX::strftime seems to not support %s to turn a list
# of second/minute/hour/day/month-1/year-1900 into epoch seconds
sub _to_epoch {
    my($class, $year, $month, $day, $hour, $minute, $second) = @_;
    die("Ancient history! $year\n") if($year < 1970);

    my $epoch = 0;
    foreach my $this_year (1970 .. $year) {
        my @month_days = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
        $month_days[2] += 1 if($class->_is_leap($this_year));
        $epoch += $class->_sum(0, @month_days[0 .. ($this_year < $year ? 12 : $month - 1)])
                  * 24 * 60 * 60;
    }
    $epoch += ($day - 1) * 24 * 60 * 60;
    $epoch += $second + 60 * $minute + 60 * 60 * $hour;
    return $epoch;
}

sub _is_leap {
    my($class, $year) = @_;
    $year % 400 == 0 || ( $year % 4 == 0 && !($year % 100 == 0) );
}

sub _sum {
    my($class, $head, @tail) = @_;
    $head += shift(@tail);
    return !@tail ? $head : $class->_sum($head, @tail);
}

sub parse_datetime {
    my($class, $dt_string) = @_;

    if($dt_string =~ /^
        (\d{4}) -
        (\d{2}) -
        (\d{2})
        (?:
            (?:
                T | \x20   # T or literal space
            )
            (\d{2}) :
            (\d{2}) :
            (\d{2})
        )?
    $/x) {
        my($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
        $hour   ||= 0;
        $minute ||= 0;
        $second ||= 0;
        return $class->from_epoch(epoch => $class->_to_epoch(
            $year, $month, $day, $hour, $minute, $second
        ));
    }
    die("'$dt_string' isn't a valid date/time");
}

sub now { shift->from_epoch(epoch => time); }

sub iso8601 {
    my $self = shift;

    my @time_components = (gmtime($self->{epoch}))[5, 4, 3, 2, 1, 0];
    return sprintf(
        "%04s-%02s-%02sT%02s:%02s:%02s",
        $time_components[0] + 1900,
        $time_components[1] + 1,
        @time_components[2..5]
    );
}

sub epoch { shift->{epoch} }

1;
