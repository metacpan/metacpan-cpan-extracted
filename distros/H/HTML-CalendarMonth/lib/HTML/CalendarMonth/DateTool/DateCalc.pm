package HTML::CalendarMonth::DateTool::DateCalc;
{
  $HTML::CalendarMonth::DateTool::DateCalc::VERSION = '1.26';
}

# Interface to Date::Calc

use strict;
use warnings;
use Carp;

use base qw( HTML::CalendarMonth::DateTool );

use Date::Calc qw(
  Days_in_Month
  Day_of_Week
  Add_Delta_Days
  Weeks_in_Year
  Week_of_Year
  Week_Number
  Mktime
);

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  ($self->dow(1), Days_in_Month($year, $month));
}

sub day_epoch {
  my($self, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  Mktime($year, $month, $day, 0, 0, 0);
}

sub dow {
  my($self, $day, $month, $year) = @_;
  $day || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  # Date::Calc uses 1..7 as indicies in the week, starting with Monday.
  # Convert to 0..6, starting with Sunday.
  Day_of_Week($year, $month, $day) % 7;
}

sub add_days {
  my($self, $delta, $day, $month, $year) = @_;
  defined $delta || croak "delta (in days) required.\n";
  $day   || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my($y, $m, $d) = Add_Delta_Days($year, $month, $day, $delta);
  ($d, $m, $y);
}

sub week_of_year {
  my($self, $day, $month, $year) = @_;
  $day || croak "day required.\n";
  $month ||= $self->month;
  $year  ||= $self->year;
  my $week;
  ($week, $year) = Week_of_Year($year, $month, $day);
  ($year, $week);
}

1;
