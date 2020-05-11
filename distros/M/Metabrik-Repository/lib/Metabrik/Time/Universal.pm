#
# $Id$
#
# time::universal Brik
#
package Metabrik::Time::Universal;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable timezone) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         timezone => [ qw(string) ],
         separator => [ qw(character) ],
         use_hires => [ qw(0|1) ],
      },
      attributes_default => {
         timezone => [ 'Europe/Paris' ],
         separator => '-',
         use_hires => 0,
      },
      commands => {
         list_timezones => [ ],
         search_timezone => [ qw(string) ],
         localtime => [ qw(timezone|OPTIONAL) ],
         hour => [ ],
         today => [ qw(separator|OPTIONAL) ],
         yesterday => [ qw(separator|OPTIONAL) ],
         day => [ qw(timestamp|OPTIONAL) ],
         week => [ qw(timestamp|OPTIONAL) ],
         year => [ qw(timestamp|OPTIONAL) ],
         date => [ qw(timestamp|OPTIONAL) ],
         gmdate => [ qw(timestamp|OPTIONAL) ],
         month => [ qw(timezone|OPTIONAL) ],
         last_month => [ qw(timezone|OPTIONAL) ],
         is_timezone => [ qw(timezone) ],
         timestamp => [ ],
         to_timestamp => [ qw(string) ],
         timestamp_to_tz_time => [ qw(timestamp|OPTIONAL) ],
         timestamp_to_tz_gmtime => [ qw(timestamp|OPTIONAL) ],
      },
      require_modules => {
         'DateTime' => [ ],
         'DateTime::TimeZone' => [ ],
         'POSIX' => [ qw(strftime) ],
         'Time::Local' => [ qw(timelocal) ],
         'Time::HiRes' => [ qw(time) ],
         'Date::Calc' => [ qw(Today Day_of_Week) ],
      },
   };
}

sub list_timezones {
   my $self = shift;

   return DateTime::TimeZone->all_names;
}

sub search_timezone {
   my $self = shift;
   my ($pattern) = @_;

   $self->brik_help_run_undef_arg('search_timezone', $pattern) or return;

   my $list = $self->list_timezones;

   my @found = ();
   for my $this (@$list) {
      if ($this =~ /$pattern/i) {
         push @found, $this;
      }
   }

   return \@found;
}

sub localtime {
   my $self = shift;
   my ($timezone) = @_;

   $timezone ||= $self->timezone;
   $self->brik_help_run_undef_arg('localtime', $timezone) or return;

   my $time = {};
   if (ref($timezone) eq 'ARRAY') {
      for my $tz (@$timezone) {
         if (! $self->is_timezone($tz)) {
            $self->log->warning("localtime: invalid timezone [$timezone]");
            next;
         }
         my $dt = DateTime->now(
            time_zone => $tz,
         );
         $time->{$tz} = "$dt";
      }
   }
   else {
      if (! $self->is_timezone($timezone)) {
         return $self->log->error("localtime: invalid timezone [$timezone]");
      }
      my $dt = DateTime->now(
         time_zone => $timezone,
      );
      $time->{$timezone} = "$dt";
   }

   return $time;
}

sub hour {
   my $self = shift;

   my @a = CORE::localtime();
   my $h = $a[2];

   return sprintf("%02d", $h);
}

sub today {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;
   my $d = $a[3];

   return sprintf("%04d$sep%02d$sep%02d", $y, $m, $d);
}

sub yesterday {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime(time() - (24 * 3600));
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;
   my $d = $a[3];

   return sprintf("%04d$sep%02d$sep%02d", $y, $m, $d);
}

sub day {
   my $self = shift;
   my ($timestamp) = @_;

   $timestamp ||= $self->timestamp;

   my @t = CORE::localtime($timestamp);

   my $year = $t[5] + 1900;
   my $month = $t[4] + 1;
   my $day = $t[3];

   return sprintf("%04d-%02d-%02d", $year, $month, $day);
}

sub week {
   my $self = shift;
   my ($timestamp) = @_;

   $timestamp ||= $self->timestamp;

   my ($year, $month, $day) = Date::Calc::Localtime($timestamp);
   my $week = Date::Calc::Week_of_Year($year, $month, $day);

   return sprintf("%02d", $week);
}

sub year {
   my $self = shift;
   my ($timestamp) = @_;

   my $day = $self->day($timestamp) or return;

   my ($year) = $day =~ m{^(\d{4})};

   return $year;
}

sub date {
   my $self = shift;
   my ($timestamp) = @_;

   $timestamp ||= $self->timestamp;

   return CORE::localtime($timestamp)."";
}

sub gmdate {
   my $self = shift;
   my ($timestamp) = @_;

   $timestamp ||= $self->timestamp;

   return POSIX::strftime("%a %b %e %H:%M:%S %Y", CORE::gmtime($timestamp));
}

#
# timestamp => '2016-11-01T00:06:39.000Z'
#
sub timestamp_to_tz_time {
   my $self = shift;
   my ($timestamp) = @_;

   $timestamp ||= $self->timestamp;
   $self->brik_help_run_undef_arg('timestamp_to_tz_time', $timestamp) or return;

   if ($self->use_hires) {
      my $t = $timestamp || Time::HiRes::time();
      my $date = POSIX::strftime("%Y-%m-%d".'T'."%H:%M:%S", CORE::localtime($t));
      $date .= sprintf(".%03dZ", ($t-int($t))*1000); # without rounding

      return $date;
   }

   return POSIX::strftime("%Y-%m-%d".'T'."%H:%M:%S.000Z", CORE::localtime($timestamp));
}

sub timestamp_to_tz_gmtime {
   my $self = shift;
   my ($timestamp) = @_;

   $timestamp ||= $self->timestamp;
   $self->brik_help_run_undef_arg('timestamp_to_tz_gmtime', $timestamp) or return;

   if ($self->use_hires) {
      my $t = $timestamp || Time::HiRes::time();
      my $date = POSIX::strftime("%Y-%m-%d".'T'."%H:%M:%S", CORE::gmtime($t));
      $date .= sprintf(".%03dZ", ($t-int($t))*1000); # without rounding

      return $date;
   }

   return POSIX::strftime("%Y-%m-%d".'T'."%H:%M:%S.000Z", CORE::gmtime($timestamp));
}

sub month {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4] + 1;

   return sprintf("%04d$sep%02d", $y, $m);
}

sub last_month {
   my $self = shift;
   my ($sep) = @_;

   $sep ||= $self->separator;

   my @a = CORE::localtime();
   my $y = $a[5] + 1900;
   my $m = $a[4];

   if ($m == 0) {
      $m = 12;
      $y -= 1;
   }

   return sprintf("%04d$sep%02d", $y, $m);
}

sub is_timezone {
   my $self = shift;
   my ($tz) = @_;

   $self->brik_help_run_undef_arg('is_timezone', $tz) or return;

   my $tz_list = $self->list_timezones;
   my %h = map { $_ => 1 } @$tz_list;

   return exists($h{$tz}) ? 1 : 0;
}

sub timestamp {
   my $self = shift;

   if ($self->use_hires) {
      return Time::HiRes::time();
   }

   return CORE::time();
}

sub to_timestamp {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('to_timestamp', $string) or return;

   my %month = (
      Jan => 0,
      Feb => 1,
      Mar => 2,
      Apr => 3,
      May => 4,
      Jun => 5,
      Jul => 6,
      Aug => 7,
      Sep => 8,
      Oct => 9,
      Nov => 10,
      Dec => 11,
   );

   my $timestamp = 0;
   # 2015-12-30
   if ($string =~ m{^(\d{4})-(\d{2})-(\d{2})$}) {
      $timestamp = Time::Local::timelocal(0, 0, 12, $3, $2-1, $1);
      if ($self->use_hires) {
         my $msec = 0;
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # 20190115
   elsif ($string =~ m{^(\d{4})(\d{2})(\d{2})$}) {
      $timestamp = Time::Local::timelocal(0, 0, 12, $3, $2-1, $1);
      if ($self->use_hires) {
         my $msec = 0;
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # Wed Nov  9 07:01:18 2016
   elsif ($string =~ m{^\S+\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$}) {
      my $mon = $1;
      my $mday = $2;
      my $hour = $3;
      my $min = $4;
      my $sec = $5;
      my $year = $6;
      my $msec = $7;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $month{$mon}, $year);
      if ($self->use_hires) {
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # May 17 18:23:47
   elsif ($string =~ m{^(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)$}) {
      my $mon = $1;
      my $mday = $2;
      my $hour = $3;
      my $min = $4;
      my $sec = $5;
      my $msec = 0;
      my @time = CORE::localtime();
      my $year = $time[5] + 1900;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
      if ($self->use_hires) {
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # 2016-04-12T17:25:50.713Z
   elsif ($string =~ m{^(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})Z$}) {
      my $mon = $2 - 1;
      my $mday = $3;
      my $hour = $4;
      my $min = $5;
      my $sec = $6;
      my $year = $1;
      my $msec = $7;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
      if ($self->use_hires) {
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # 2019-10-23T18:15Z
   elsif ($string =~ m{^(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2})Z$}) {
      my $mon = $2 - 1;
      my $mday = $3;
      my $hour = $4;
      my $min = $5;
      my $sec = 0;
      my $year = $1;
      my $msec = 0;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
      if ($self->use_hires) {
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # 2017-10-11 07:40:55.612514
   elsif ($string =~ m{^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{6})$}) {
      my $mon = $2 - 1;
      my $mday = $3;
      my $hour = $4;
      my $min = $5;
      my $sec = $6;
      my $year = $1;
      my $msec = $7;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
      if ($self->use_hires) {
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   # 2019-01-07 17:02
   elsif ($string =~ m{^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2})$}) {
      my $mon = $2 - 1;
      my $mday = $3;
      my $hour = $4;
      my $min = $5;
      my $year = $1;
      $timestamp = Time::Local::timelocal(0, $min, $hour, $mday, $mon, $year);
   }
   # 2019-01-07 11:40:24
   elsif ($string =~ m{^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})$}) {
      my $mon = $2 - 1;
      my $mday = $3;
      my $hour = $4;
      my $min = $5;
      my $sec = $6;
      my $year = $1;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
   }
   # 11/04/19 11:40:00
   elsif ($string =~ m{^(\d{2})/(\d{2})/(\d{2}) (\d{2}):(\d{2}):(\d{2})$}) {
      my $mon = $1 - 1;
      my $mday = $2;
      my $hour = $4;
      my $min = $5;
      my $sec = $6;
      my $year = $3 + 2000;  # Y2100 bug.
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
   }
   # 2000-10-20T00:00:00.000-04:00
   elsif ($string =~ m{^(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})}) {
      my $mon = $2 - 1;
      my $mday = $3;
      my $hour = $4;
      my $min = $5;
      my $sec = $6;
      my $year = $1;
      my $msec = $7;
      $timestamp = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);
      if ($self->use_hires) {
         $timestamp .= sprintf(".%03d", $msec);
      }
   }
   else {
      return $self->log->error("to_timestamp: string [$string] not a valid date format");
   }

   return $timestamp;
}

1;

__END__

=head1 NAME

Metabrik::Time::Universal - time::universal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
