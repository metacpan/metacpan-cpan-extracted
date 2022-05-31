#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 9;
use Time::Local;

use Firewall::Config::Element::Schedule::Netscreen;

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

has weekday => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has startTime1 => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has endTime1 => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has startTime2 => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has endTime2 => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has description => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);
=cut

my $schedule;
my $date;

ok(
  do {
    eval { $schedule = Firewall::Config::Element::Schedule::Netscreen->new( fwId => 1, schName => 'a', schType => 'b' ) };
    warn $@ if $@;
    $schedule->isa('Firewall::Config::Element::Schedule::Netscreen');
  },
  ' 生成 Firewall::Config::Element::Schedule::Netscreen 对象'
);

ok(
  do {
    eval { $schedule = Firewall::Config::Element::Schedule::Netscreen->new( fwId => 1, schName => 'a', schType => 'b' ) };
    warn $@ if $@;
    $schedule->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2022 23:59'
      );
    };
    warn $@ if $@;
    $schedule->getSecondFromEpoch('9/24/2013 00:00') == 1379952000
      ? 1
      : 0;
  },
  q{ getSecondFromEpoch('9/24/2013 00:00')}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2022 23:59'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
    $schedule->{timeRange}{min} eq '1318176000'
      and $schedule->{timeRange}{max} eq '1648742340' ? 1 : 0;
  },
  q{ createTimeRange on startDate => '10/10/2011 0:0', endDate => '3/31/2022 23:59'}
);

ok(
  do {
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId       => 1,
        schName    => 'a',
        schType    => 'recurrent',
        weekday    => 'saturday',
        startTime1 => '10:00',
        endTime1   => '12:00',
        startTime2 => '14:00',
        endTime2   => '16:00'
      );
    };
    warn $@ if $@;
    $schedule->createTimeRange;
          $schedule->{timeRange}{saturday}[0]->{min} == 1000
      and $schedule->{timeRange}{saturday}[0]->{max} == 1200
      and $schedule->{timeRange}{saturday}[1]->{min} == 1400
      and $schedule->{timeRange}{saturday}[1]->{max} == 1600 ? 1 : 0;
  },
  q{ createTimeRange on weekday => 'saturday', startTime1 => '10:00', endTime1 => '12:00', startTime2 => '14:00', endTime2 => '16:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2022 23:59'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 1 ? 1 : 0;
  },
  qq{ date '$date' is valid on startDate => '10/10/2011 0:0', endDate => '3/31/2022 23:59'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId       => 1,
        schName    => 'a',
        schType    => 'recurrent',
        weekday    => 'saturday',
        startTime1 => '10:00',
        endTime1   => '12:00',
        startTime2 => '14:00',
        endTime2   => '16:00'
      );
    };
    warn $@ if $@;
    $schedule->isEnable($time) == 1 ? 1 : 0;
  },
  qq{ date '$date' is valid on weekday => 'saturday', startTime1 => '10:00', endTime1 => '12:00', startTime2 => '14:00', endTime2 => '16:00'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2022 23:59'
      );
    };
    warn $@ if $@;
    $schedule->isExpired($time) == 0 ? 1 : 0;
  },
  qq{ date '$date' is not expired on startDate => '10/10/2011 0:0', endDate => '3/31/2022 23:59'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
    my $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
    eval {
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId       => 1,
        schName    => 'a',
        schType    => 'recurrent',
        weekday    => 'friday',
        startTime1 => '10:00',
        endTime1   => '12:00',
        startTime2 => '14:00',
        endTime2   => '16:00'
      );
    };
    warn $@ if $@;
    $schedule->isExpired($time) == 0 ? 1 : 0;
  },
  qq{ date '$date' is not expired on weekday => 'friday', startTime1 => '10:00', endTime1 => '12:00', startTime2 => '14:00', endTime2 => '16:00'}
);
