#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 16;
use Mojo::Util qw(dumper);
use Time::Local;

use Firewall::Config::Element::Schedule::Asa;

=lala
#设备Id
has fwId => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

#在同一个设备中描述一个对象的唯一性特征
has sign => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_buildSign',
);

has schName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has schType=> (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has startDate => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has endDate => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);


has periodic => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has startTime => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has endTime => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

=cut

my $schedule;
my $date;

ok(
  do {
    eval { $schedule = Firewall::Config::Element::Schedule::Asa->new( fwId => 1, schName => 'a', schType => 'absolute' ) };
    warn $@ if $@;
    $schedule->isa('Firewall::Config::Element::Schedule::Asa');
  },
  ' 生成 Firewall::Config::Element::Schedule::Asa 对象'
);

ok(
  do {
    eval { $schedule = Firewall::Config::Element::Schedule::Asa->new( fwId => 1, schName => 'a', schType => 'absolute' ) };
    warn $@ if $@;
    $schedule->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2009'
      );
    };
    warn $@ if $@;
    $schedule->getSecondFromEpoch('00:00 24 September 2013') == 1379952000 ? 1 : 0;
  },
  q{ getSecondFromEpoch('00:00 24 September 2013')}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId    => 1,
        schName => 'a',
        schType => 'absolute',
        endDate => '23:59 30 November 2009'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
    $schedule->{timeRange}{min} == 0
      and $schedule->{timeRange}{max} == 1259596740;
  },
  q{ createTimeRange on endDate => '23:59 30 November 2009'}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2009'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
    $schedule->{timeRange}{min} eq '1257004800'
      and $schedule->{timeRange}{max} eq '1259596740' ? 1 : 0;
  },
  q{ createTimeRange on startDate => '00:00 01 November 2009', endDate => '23:59 30 November 2009'}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'daily',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
          $schedule->{timeRange}{Sunday}{min} eq '800'
      and $schedule->{timeRange}{Monday}{min} eq '800'
      and $schedule->{timeRange}{Tuesday}{min} eq '800'
      and $schedule->{timeRange}{Wednesday}{min} eq '800'
      and $schedule->{timeRange}{Thursday}{min} eq '800'
      and $schedule->{timeRange}{Friday}{min} eq '800'
      and $schedule->{timeRange}{Saturday}{min} eq '800'
      and $schedule->{timeRange}{Sunday}{max} eq '1400'
      and $schedule->{timeRange}{Monday}{max} eq '1400'
      and $schedule->{timeRange}{Tuesday}{max} eq '1400'
      and $schedule->{timeRange}{Wednesday}{max} eq '1400'
      and $schedule->{timeRange}{Thursday}{max} eq '1400'
      and $schedule->{timeRange}{Friday}{max} eq '1400'
      and $schedule->{timeRange}{Saturday}{max} eq '1400' ? 1 : 0;
  },
  q{ createTimeRange on periodic => 'daily', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'weekdays',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
          $schedule->{timeRange}{Monday}{min} eq '800'
      and $schedule->{timeRange}{Tuesday}{min} eq '800'
      and $schedule->{timeRange}{Wednesday}{min} eq '800'
      and $schedule->{timeRange}{Thursday}{min} eq '800'
      and $schedule->{timeRange}{Friday}{min} eq '800'
      and $schedule->{timeRange}{Monday}{max} eq '1400'
      and $schedule->{timeRange}{Tuesday}{max} eq '1400'
      and $schedule->{timeRange}{Wednesday}{max} eq '1400'
      and $schedule->{timeRange}{Thursday}{max} eq '1400'
      and $schedule->{timeRange}{Friday}{max} eq '1400' ? 1 : 0;
  },
  q{ createTimeRange on periodic => 'weekdays', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'weekend',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
          $schedule->{timeRange}{Sunday}{min} eq '800'
      and $schedule->{timeRange}{Saturday}{min} eq '800'
      and $schedule->{timeRange}{Sunday}{max} eq '1400'
      and $schedule->{timeRange}{Saturday}{max} eq '1400' ? 1 : 0;
  },
  q{ createTimeRange on periodic => 'weekend', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'Monday Thursday',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
          $schedule->{timeRange}{Thursday}{min} eq '800'
      and $schedule->{timeRange}{Monday}{min} eq '800'
      and $schedule->{timeRange}{Thursday}{max} eq '1400'
      and $schedule->{timeRange}{Monday}{max} eq '1400' ? 1 : 0;
  },
  q{ createTimeRange on periodic => 'Monday Thursday', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2019'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 1 ? 1 : 0;
  },
  qq{ date '$date' is valid on startDate => '00:00 01 November 2009', endDate => '23:59 30 November 2019'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'daily',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 1 ? 1 : 0;
  },
  qq{ date '$date' is valid on periodic => 'daily', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'weekdays',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 0 ? 1 : 0;
  },
  qq{ date '$date' is not valid on periodic => 'weekdays', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'weekend',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 1 ? 1 : 0;
  },
  qq{ date '$date' is valid on periodic => 'weekend', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'Monday Thursday',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 0 ? 1 : 0;
  },
  qq{ date '$date' is not valid on periodic => 'Monday Thursday', startTime => '8:00', endTime => '14:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2019'
      );
    };
    warn $@ if $@;
    $schedule->isExpired($time) == 0 ? 1 : 0;

    #print dumper($schedule);
  },
  qq{ date '$date' is not expired on startDate => '00:00 01 November 2009', endDate => '23:59 30 November 2019'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'periodic',
        periodic  => 'Monday Thursday',
        startTime => '8:00',
        endTime   => '14:00'
      );
    };
    warn $@ if $@;
    $schedule->isExpired($time) == 0 ? 1 : 0;
  },
  qq{ date '$date' is not expired on periodic => 'Monday Thursday', startTime => '8:00', endTime => '14:00'}
);
