package HTML::CalendarMonth::DateTool::DateManip;
{
  $HTML::CalendarMonth::DateTool::DateManip::VERSION = '1.26';
}

# Interface to Date::Manip

use strict;
use warnings;
use Carp;

use base qw( HTML::CalendarMonth::DateTool );

use Date::Manip qw(
  Date_DaysInMonth
  Date_DayOfWeek
  DateCalc
  UnixDate
  Date_SecsSince1970
  ParseDateDelta
);

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  ($self->dow(1), Date_DaysInMonth($month, $year));
}

sub day_epoch {
  my($self, $day, $month, $year) = @_;
  $day || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  Date_SecsSince1970($month, $day, $year, 0, 0, 0);
}

sub dow {
  # Date::Manip uses 1..7 as indicies in the week, starting with Monday.
  # Convert to 0..6 starting with Sunday.
  my($self, $day, $month, $year) = @_;
  $day   || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  Date_DayOfWeek($month, $day, $year) % 7;
}

sub add_days {
  my($self, $delta, $day, $month, $year) = @_;
  defined $delta || croak "delta (in days) required.\n";
  $day   || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $date = DateCalc(
    sprintf("%04d%02d%02d", $year, $month, $day),
    "$delta days"
  );
  my($y, $m, $d) = $date =~ /^(\d{4})(\d\d)(\d\d)/;
  $_ += 0 foreach ($y, $m, $d);
  ($d, $m, $y);
}

sub week_of_year {
  my($self, $day, $month, $year) = @_;
  $day   || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $week = UnixDate(sprintf("%04d%02d%02d", $year, $month, $day), '%U');
  $week += 0;
  ($year, $week);
}

1;
