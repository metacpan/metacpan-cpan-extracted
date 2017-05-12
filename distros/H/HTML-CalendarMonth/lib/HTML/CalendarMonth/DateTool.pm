package HTML::CalendarMonth::DateTool;
{
  $HTML::CalendarMonth::DateTool::VERSION = '1.26';
}

# Base class for determining what date calculation package to use.

use strict;
use warnings;
use Carp;

use File::Which qw( which );

my %Toolmap = (
  'Time::Local' => 'TimeLocal',
  'Date::Calc'  => 'DateCalc',
  'DateTime'    => 'DateTime',
  'Date::Manip' => 'DateManip',
  'ncal'        => 'Ncal',
  'cal'         => 'Cal',
);

my %Classmap;
$Classmap{lc $Toolmap{$_}} = $_ foreach keys %Toolmap;

my($Cal_Cmd, $Ncal_Cmd);

sub _toolmap {
  shift;
  my $str = shift;
  my $tool = $Toolmap{$str};
  unless ($tool) {
    foreach (values %Toolmap) {
      if ($str =~ /^$_$/i) {
        $tool = $_;
        last;
      }
    }
  }
  return unless $tool;
  join('::', __PACKAGE__, $tool);
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  my %parms = @_;
  $self->{year}     = $parms{year};
  $self->{month}    = $parms{month};
  $self->{weeknum}  = $parms{weeknum};
  $self->{historic} = $parms{historic};
  if (! $self->{year}) {
    my @dmy = $self->_dmy_now;
    $self->{year}    = $dmy[2];
    $self->{month} ||= $dmy[1];
  }
  $self->{month} ||= 1;
  if ($parms{datetool}) {
    $self->{datetool} = $self->_toolmap($parms{datetool})
      or croak "Sorry, didn't find a tool for datetool '$parms{datetool}'\n";
  }
  my $dc = $self->_summon_date_class;
  unless (eval "require $dc") {
    croak "Problem loading $dc ($@)\n";
  }
  # rebless into new class
  bless $self, $dc;
}

sub year     { shift->{year}     }
sub month    { shift->{month}    }
sub weeknum  { shift->{weeknum}  }
sub historic { shift->{historic} }
sub datetool { shift->{datetool} }

sub _name {
  my $class = shift;
  $class = ref $class || $class;
  lc((split(/::/, $class))[-1]);
}

sub _cal_cmd {
  my $self = shift;
  if (! defined $Cal_Cmd) {
    $Cal_Cmd = which('cal') || '';
    if ($Cal_Cmd) {
      my @out = grep { ! /^\s*$/ } `$Cal_Cmd 9 1752`;
      #   September 1752
      #Su Mo Tu We Th Fr Sa
      #       1  2 14 15 16
      #17 18 19 20 21 22 23
      #24 25 26 27 28 29 30
      my @pat = (
        qr/^\s*\S+\s+\d+$/,
        qr/^\s*\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s*$/,
        qr/^\s*\d+\s+\d+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s*$/,
      );
      if (@out == @pat) {
        for my $i (0 .. $#out) {
          if ($out[$i] !~ $pat[$i]) {
            $Cal_Cmd = '';
            last;
          }
        }
      }
      else {
        $Cal_Cmd = '';
      }
    }
  }
  $Cal_Cmd;
}

sub _ncal_cmd {
  my $self = shift;
  if (! defined $Ncal_Cmd) {
    $Ncal_Cmd = which('ncal') || '';
    if ($Ncal_Cmd) {
      my @out = grep { ! /^\s*$/ } map { s/^\s*//; $_ } `$Ncal_Cmd 9 1752`;
      #    September 1752
      #Mo    18 25
      #Tu  1 19 26
      #We  2 20 27
      #Th 14 21 28
      #Fr 15 22 29
      #Sa 16 23 30
      #Su 17 24
      my @pat = (
        qr/^\s*\S+\s+\d+$/,
        qr/^\s*\S+\s+\d+\s+\d+\s*$/,
        qr/^\s*\S+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\S+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\S+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\S+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\S+\s+\d+\s+\d+\s+\d+\s*$/,
        qr/^\s*\S+\s+\d+\s+\d+\s*$/,
      );
      if (@out == @pat) {
        for my $i (0 .. $#out) {
          if ($out[$i] !~ $pat[$i]) {
            $Ncal_Cmd = '';
            last;
          }
        }
      }
      else {
        $Ncal_Cmd = '';
      }
    }
  }
  $Ncal_Cmd;
}

sub day_epoch {
  # in case our subclasses are lazy
  my($self, $day, $month, $year) = @_;
  $month ||= $self->month;
  $year  ||= $self->year;
  Time::Local::timegm(0,0,0,1,$month,$year);
}

sub _skips {
  my $self = shift;
  @_ ? $self->{skips} = shift : $self->{skips};
}

sub dow1st  { (shift->dow1st_and_lastday)[0] }

sub lastday { (shift->dow1st_and_lastday)[1] }

sub _dmy_now {
  my $self = shift;
  my $ts = @_ ? shift : time;
  my($d, $m, $y) = (localtime($ts))[3,4,5];
  ++$m; $y += 1900;
  ($d, $m, $y);
}

sub _dom_now {
  my $self = shift;
  my $ts = @_ ? shift : time;
  my($d, $m, $y);
  if ($ts =~ /^\d+$/) {
    if (length $ts <= 2) {
      ($d, $m, $y) = ($ts, $self->month, $self->year);
      croak "invalid day of month (1 .. " . $self->lastday . ") '$ts'"
        unless $ts >= 1 && $ts <= $self->lastday;
    }
    else {
      ($d, $m, $y) = $self->_dmy_now($ts);
    }
  }
  else {
    ($y, $m, $d) = $ts =~ m{^(\d+)/(\d\d)/(\d\d)$};
    croak "invalid yyyy/mm/dd date string '$ts'" unless defined $d;
  }
  my($cy, $cm) = ($self->year, $self->month);
  my $first = sprintf("%04d/%02d/%02d", $cy, $cm, 1);
  my $last  = sprintf("%04d/%02d/%02d", $cy, $cm, $self->lastday);
  my $pivot = sprintf("%04d/%02d/%02d", $y, $m, $d);
  return -1 if $pivot gt $last;
  return  0 if $pivot lt $first;
  $d;
}

sub _summon_date_class {
  my $self = shift;
  my @tools;
  if (my $c = $self->datetool) {
    eval "use $c";
    die "invalid date tool $c : $@" if $@;
    @tools = $c->_name;
  }
  else {
    @tools = qw( timelocal datecalc datetime datemanip ncal cal );
  }
  my($dc, @fails);
  for my $tool (@tools) {
    my $method = join('_', '', lc($tool), 'fails');
    if (my $f = $self->$method) {
      push(@fails, [$tool, $f]);
    }
    else {
      $dc = $self->_toolmap($tool);
      last;
    }
  }
  return $dc if $dc;
  if (@tools == 1) {
    croak "invalid date tool " . join(': ', @{$fails[0]});
  }
  else {
    croak join("\n",
      "no valid date tool found:",
      map(sprintf("%11s: %s", @$_), @fails),
      "\n"
    );
  }
}

sub _dump_tests {
  my $self = shift;
  print "Time::Local : ", $self->_timelocal_fails || 1, "\n";
  print " Date::Calc : ", $self->_datecalc_fails  || 1, "\n";
  print "   DateTime : ", $self->_datetime_fails  || 1, "\n";
  print "Date::Manip : ", $self->_datemanip_fails || 1, "\n";
  print "       ncal : ", $self->_ncal_fails      || 1, "\n";
  print "        cal : ", $self->_cal_fails       || 1, "\n";
}

sub _is_julian {
  my $self = shift;
  my $y = $self->year;
  $y < 1752 || ($y == 1752 && $self->month <= 9);
}

sub _timelocal_fails {
  my $self = shift;
  return "not installed" unless $self->_timelocal_present;
  return "week-of-year numbering unsupported" if $self->weeknum;
  my $y = $self->year;
  return "only years between 1970 and 2038 supported"
    if $y < 1970 || $y >= 2038;
  return;
}

sub _ncal_fails {
  my $self = shift;
  return "command not found" unless $self->_ncal_present;
  return "week-of-year numbering not supported prior to 1752/09"
    if $self->weeknum && $self->_is_julian;
  return;
}

sub _cal_fails  {
  my $self = shift;
  return "command not found" unless $self->_cal_present;
  return "week-of-year numbering not supported" if $self->weeknum;
  return;
}

sub _datecalc_fails {
  my $self = shift;
  return "not installed" unless $self->_datecalc_present;
  return "historic mode prior to 1752/09 not supported"
    if $self->historic && $self->_is_julian;
  return;
}

sub _datetime_fails {
  my $self = shift;
  return "not installed" unless $self->_datetime_present;
  return "historic mode prior to 1752/09 not supported"
    if $self->historic && $self->_is_julian;
  return;
}

sub _datemanip_fails {
  my $self = shift;
  return "not installed" unless $self->_datemanip_present;
  return "historic mode prior to 1752/09 not supported"
    if $self->historic && $self->_is_julian;
  eval { require Date::Manip && Date::Manip::Date_Init() };
  return "init failure: $@" if $@;
  return;
}

sub _timelocal_present { eval "require Time::Local"; return !$@ }
sub _datecalc_present  { eval "require Date::Calc";  return !$@ }
sub _datetime_present  { eval "require DateTime";    return !$@ }
sub _datemanip_present { eval "require Date::Manip"; return !$@ }
sub _ncal_present      { shift->_ncal_cmd }
sub _cal_present       { shift->_cal_cmd  };


1;

__END__

=head1 NAME

HTML::CalendarMonth::DateTool - Base class for determining which date package to use for calendrical calculations.

=head1 SYNOPSIS

  my $date_tool = HTML::CalendarMonth::DateTool->new(
                    year     => $YYYY_year,
                    month    => $one_thru_12_month,
                    weeknum  => $weeknum_mode,
                    historic => $historic_mode,
                    datetool => $specific_datetool_if_desired,
                  );

=head1 DESCRIPTION

This module attempts to utilize the best date calculation package
available on the current system. For most contemporary dates this
usually ends up being the internal Time::Local package of perl. For more
exotic dates, or when week number of the years are desired, other
methods are attempted including DateTime, Date::Calc, Date::Manip, and
the linux/unix 'ncal' or 'cal' commands. Each of these has a specific
subclass of this module offering the same utility methods needed by
HTML::CalendarMonth.

=head1 METHODS

=over

=item new()

Constructor. Takes the following parameters:

=over

=item year

Year of calendar in question (required). If you are rendering exotic
dates (i.e. dates outside of 1970 to 2038) then something besides
Time::Local will be used for calendrical calculations.

=item month

Month of calendar in question (required). 1 through 12.

=item weeknum

Optional. When specified, will limit class excursions to those that are
currently set up for week of year calculations.

=item historic

Optional. If the the ncal or cal commands are available, use one of them
rather than other available date modules since these utilities
accurately handle some specific historical artifacts such as the
transition from Julian to Gregorian.

=item datetool

Optional. Mostly for debugging, this option can be used to indicate a
specific HTML::CalendarMonth::DateTool subclass for instantiation. The
value can be either the actual utility class, e.g., Date::Calc, or the
name of the CalendarMonth handler leaf class, e.g. DateCalc. Use 'ncal'
or 'cal', respectively, for the wrappers around those commands.

=back

=back

There are number of methods automatically available:

=over

=item month()

=item year()

=item weeknum()

=item historical()

=item datetool()

Accessors for the parameters provided to C<new()> above.

=item dow1st()

Returns the day of week number for the 1st of the C<year> and C<month>
specified during the call to C<new()>. Relies on the presence of
C<dow1st_and_lastday()>. Should be 0..6 starting with Sun.

=item lastday()

Returns the last day of the month for the C<year> and C<month> specified
during the call to C<new()>. Relies on the presence of
C<dow1st_and_lastday()>.

=back

=head1 Overridden methods

Subclasses of this module must provide at least the C<day_epoch()> and
C<dow1st_and_lastday()> methods.

=over

=item dow1st_and_lastday()

Required. Provides a list containing the day of the week of the first
day of the month (0..6 starting with Sun) along with the last day of
the month.

=item day_epoch()

Optional unless interested in epoch values for wacky dates. For a given
day, and optionally C<month> and C<year> if they are different from
those specified in C<new()>, provide the unix epoch in seconds for that
day at midnight.

=back

If the subclass is expected to provide week of year numbers, three more
methods are necessary:

=over

=item dow()

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide the day of week
number. (0=Sunday, 6=Saturday).

=item add_days($days, $delta, $day, [$month], [$year])

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide a list of year,
month, and day once C<delta> days have been added.

=item week_of_year($day, [$month], [$year])

For a given day, and optionally C<month> and C<year> if they are
different from those specified in C<new()>, provide a list with the week
number of the year along with the year. (some days of a particular year
can end up belonging to the prior or following years).

=back

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2010 Matthew P. Sisk. All rights reserved. All wrongs
revenged. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

HTML::CalendarMonth(3), Time::Local(3), DateTime(3), Date::Calc(3),
Date::Manip(3), cal(1)
