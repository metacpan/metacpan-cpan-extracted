package HTML::CalendarMonth::DateTool::TimeLocal;
{
  $HTML::CalendarMonth::DateTool::TimeLocal::VERSION = '1.26';
}

# Interface to Time::Local

use strict;
use warnings;
use Carp;

use base qw( HTML::CalendarMonth::DateTool );

use Time::Local;

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  # map month to 0-12
  --$month;
  # years since 1900...hooh-rah for POSIX...
  $year -= 1900;
  my $nmonth = $month + 1;
  my $nyear  = $year;
  if ($nmonth > 11) {
    # Happy new year
    $nmonth = 0;
    ++$nyear;
  }
  # Leave dow of 1st in 0-based format
  my $dow1st  = (gmtime(Time::Local::timegm(0,0,0,1,$month,$year)))[6];
  # Last day is one day prior to 1st of month after
  my $lastday = (gmtime(Time::Local::timegm(0,0,0,1,$nmonth,$nyear)
                        - 60*60*24))[3];
  ($dow1st, $lastday);
}

1;
