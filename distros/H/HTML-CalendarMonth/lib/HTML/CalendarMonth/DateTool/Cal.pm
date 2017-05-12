package HTML::CalendarMonth::DateTool::Cal;
{
  $HTML::CalendarMonth::DateTool::Cal::VERSION = '1.26';
}

# Interface to unix 'cal' command

use strict;
use warnings;
use Carp;

use base qw( HTML::CalendarMonth::DateTool );

sub dow1st_and_lastday {
  my($self, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  my $cmd = $self->_cal_cmd or croak "cal command not found\n";

  my @cal = grep(!/^\s*$/,`$cmd $month $year`);
  chomp @cal;
  my @days     = grep(/\d+/,split(/\s+/,$cal[2]));
  my $dow1st   = 6 - $#days;
  my($lastday) = $cal[$#cal] =~ /(\d+)\s*$/;
  # With dow1st and lastday, one builds a calendar sequentially.
  # Historically, in particular Sep 1752, days have been skipped. Here's
  # the chance to catch that.
  $self->_skips(undef);
  if ($month == 9 && $year == 1752) {
    my %skips;
    grep(++$skips{$_}, 3 .. 13);
    $self->_skips(\%skips);
  }
  ($dow1st, $lastday);
}

1;
