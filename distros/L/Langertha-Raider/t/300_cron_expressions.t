#!/usr/bin/env perl
# ABSTRACT: Five-field cron expressions: validation, the next match in local time, Claude Code's jitter (ADR 0031, k169)
use strict;
use warnings;
use Test2::V0;
use POSIX ();
use Langertha::Raider::Cron;

my $cron = 'Langertha::Raider::Cron';

sub with_tz {
  my ( $tz, $code ) = @_;
  local $ENV{TZ} = $tz;
  POSIX::tzset();
  my @r = $code->();
  return $r[0];
}

# Local time to epoch.
sub at { my ( $y, $m, $d, $H, $M ) = @_; POSIX::mktime( 0, $M, $H, $d, $m - 1, $y - 1900, -1 ) }
sub show { my ( $t ) = @_; POSIX::strftime( '%Y-%m-%d %H:%M', localtime $t ) }

subtest 'validation' => sub {
  is( $cron->validate('*/5 * * * *'), undef, 'every five minutes' );
  is( $cron->validate('0 9 * * 1-5'), undef, 'weekdays at nine' );
  is( $cron->validate('30 14 15 3 *'), undef, 'a date' );
  is( $cron->validate('1,15,30 * * * 0'), undef, 'a list and Sunday' );
  is( $cron->validate('0 0 * * 7'), undef, '7 is Sunday too' );
  like( $cron->validate('* * * *'), qr/five fields.*got 4/, 'too few fields' );
  like( $cron->validate('* * * * * *'), qr/five fields.*got 6/, 'a seconds field is not accepted' );
  like( $cron->validate('60 * * * *'), qr/out of range in the minute field/, 'minute 60' );
  like( $cron->validate('* 24 * * *'), qr/out of range in the hour field/, 'hour 24' );
  like( $cron->validate('* * 0 * *'), qr/out of range in the dom field/, 'day 0' );
  like( $cron->validate('* * * 13 *'), qr/out of range in the month field/, 'month 13' );
  like( $cron->validate('* * * * 8'), qr/out of range in the dow field/, 'weekday 8' );
  like( $cron->validate('* * * JAN *'), qr/unsupported syntax in the month field: JAN/, 'names are not supported' );
  like( $cron->validate('* * * * MON'), qr/unsupported syntax/, 'weekday names neither' );
  like( $cron->validate('0 0 L * *'), qr/unsupported syntax/, 'L neither' );
  like( $cron->validate('? * * * *'), qr/unsupported syntax/, '? neither' );
  like( $cron->validate('*/0 * * * *'), qr/bad step/, 'step 0' );
  like( $cron->validate('5-1 * * * *'), qr/out of range/, 'a backwards range' );
  like( $cron->validate('1,,2 * * * *'), qr/empty entry/, 'an empty list entry' );
  like( $cron->validate(undef), qr/no cron expression/, 'undef' );
  like( $cron->validate('0 0 31 2 *'), qr/does not match any date/, '31 February never comes' );
};

subtest 'next match, local time' => sub {
  with_tz( 'UTC', sub {
    my $now = at( 2026, 10, 20, 10, 3 );
    is( show( $cron->next( '*/5 * * * *', $now ) ), '2026-10-20 10:05', 'the next five-minute mark' );
    is( show( $cron->next( '*/5 * * * *', at( 2026, 10, 20, 10, 5 ) ) ), '2026-10-20 10:10', 'strictly after the time given' );
    is( show( $cron->next( '7 * * * *', $now ) ), '2026-10-20 10:07', 'minute 7' );
    is( show( $cron->next( '0 9 * * *', $now ) ), '2026-10-21 09:00', 'tomorrow at nine' );
    is( show( $cron->next( '0 9 * * 1-5', at( 2026, 10, 23, 12, 0 ) ) ), '2026-10-26 09:00', 'Friday noon -> Monday' );
    is( show( $cron->next( '30 14 15 3 *', $now ) ), '2027-03-15 14:30', 'a yearly date' );
    is( show( $cron->next( '0 0 29 2 *', $now ) ), '2028-02-29 00:00', 'February 29th, the next leap year' );
    is( show( $cron->next( '15,45 8-9 * * *', $now ) ), '2026-10-21 08:15', 'lists and ranges' );
    is( show( $cron->next( '10-20/5 12 * * *', $now ) ), '2026-10-20 12:10', 'a stepped range' );
    is( show( $cron->next( '0 0 * * 0', $now ) ), '2026-10-25 00:00', 'Sunday as 0' );
    is( show( $cron->next( '0 0 * * 7', $now ) ), '2026-10-25 00:00', 'Sunday as 7' );
    is( $cron->next( '0 0 31 2 *', $now ), undef, 'nothing for an impossible date' );
    is( $cron->next( 'nonsense', $now ), undef, 'nothing for an invalid expression' );
  } );
};

subtest 'day of month and day of week: either matches when both are constrained' => sub {
  with_tz( 'UTC', sub {
    # 2026-10-20 is a Tuesday. "the 25th or a Monday"
    my $now = at( 2026, 10, 20, 0, 0 );
    is( show( $cron->next( '0 12 25 * 1', $now ) ), '2026-10-25 12:00', 'the 25th (a Sunday) comes before the next Monday' );
    is( show( $cron->next( '0 12 25 * 1', at( 2026, 10, 25, 13, 0 ) ) ), '2026-10-26 12:00', 'then Monday' );
    # one of them a wildcard: both must match
    is( show( $cron->next( '0 12 25 * *', $now ) ), '2026-10-25 12:00', 'only the day of month' );
    is( show( $cron->next( '0 12 * * 1', $now ) ), '2026-10-26 12:00', 'only the day of week' );
  } );
};

subtest 'the local time zone decides, not UTC' => sub {
  my $utc    = with_tz( 'UTC',           sub { $cron->next( '0 9 * * *', 1_792_000_000 ) } );
  my $berlin = with_tz( 'Europe/Berlin', sub { $cron->next( '0 9 * * *', 1_792_000_000 ) } );
  isnt( $utc, $berlin, 'nine o clock in Berlin is not nine o clock in UTC' );
  is( $utc - $berlin, 7200, 'in October Berlin is two hours ahead (summer time)' ) if $utc > $berlin;
};

subtest 'daylight saving time does not loop or skip' => sub {
  with_tz( 'Europe/Berlin', sub {
    # 2026-03-29: 02:00 -> 03:00. A job at 02:30 has no such minute that day.
    my $before = at( 2026, 3, 28, 12, 0 );
    my $next = $cron->next( '30 2 * * *', $before );
    ok( defined $next && $next > $before, 'a time that does not exist today is found' );
    # 2026-10-25: 03:00 -> 02:00. An hourly job fires once per hour, forward only.
    my $t = at( 2026, 10, 25, 0, 30 );
    my @seen;
    for ( 1 .. 6 ) { $t = $cron->next( '0 * * * *', $t ); push @seen, $t }
    my @sorted = sort { $a <=> $b } @seen;
    is( \@seen, \@sorted, 'an hourly job over the end of summer time only moves forward' );
  } );
};

subtest 'matches' => sub {
  with_tz( 'UTC', sub {
    ok( $cron->matches( '*/5 * * * *', at( 2026, 10, 20, 10, 5 ) ), 'a matching minute' );
    ok( $cron->matches( '*/5 * * * *', at( 2026, 10, 20, 10, 5 ) + 30 ), 'any second of it' );
    ok( !$cron->matches( '*/5 * * * *', at( 2026, 10, 20, 10, 6 ) ), 'not a different minute' );
  } );
};

subtest 'jitter, as Claude Code documents it' => sub {
  with_tz( 'UTC', sub {
    my $at = at( 2026, 10, 20, 10, 7 );
    is( $cron->jitter( '*/5 * * * *', at( 2026, 10, 20, 10, 5 ), key => 'a', recurring => 1 ), -15,
      'every five minutes: 15 seconds sooner, whatever the key' );
    is( $cron->jitter( '*/5 * * * *', at( 2026, 10, 20, 10, 5 ), key => 'b', recurring => 1 ), -15, 'the same for another job' );

    my $hourly = $cron->jitter( '7 * * * *', $at, key => 'cron_1', recurring => 1 );
    ok( $hourly >= 0 && $hourly <= 1800, 'hourly: 0 to 30 minutes late' ) or diag $hourly;
    is( $cron->jitter( '7 * * * *', $at, key => 'cron_1', recurring => 1 ), $hourly, 'the same key shifts the same every time' );
    my %seen = map { $cron->jitter( '7 * * * *', $at, key => 'cron_'.$_, recurring => 1 ) => 1 } 1 .. 20;
    ok( keys %seen > 5, 'different jobs are shifted differently' );

    my $half = $cron->jitter( '*/30 * * * *', at( 2026, 10, 20, 10, 0 ), key => 'x', recurring => 1 );
    ok( $half >= 0 && $half <= 900, 'every 30 minutes: 0 to 15 minutes late' ) or diag $half;
    my $ten = $cron->jitter( '*/10 * * * *', at( 2026, 10, 20, 10, 0 ), key => 'x', recurring => 1 );
    ok( $ten >= 0 && $ten <= 300, 'every 10 minutes: 0 to 5 minutes late' ) or diag $ten;
    my $daily = $cron->jitter( '0 9 * * *', at( 2026, 10, 20, 9, 0 ), key => 'zzz', recurring => 1 );
    ok( $daily >= 0 && $daily <= 1800, 'daily: capped at 30 minutes' ) or diag $daily;

    # uneven gaps: :07 and :37 are 30 minutes apart, :00 and :15 are 15 and 45
    my $uneven = $cron->jitter( '0,15 * * * *', at( 2026, 10, 20, 10, 0 ), key => 'u', recurring => 1 );
    ok( $uneven >= 0 && $uneven <= 450, 'uneven gaps: half of the gap that follows' ) or diag $uneven;

    is( $cron->jitter( '3 9 * * *', at( 2026, 10, 21, 9, 3 ), key => 'o' ), 0, 'a one-shot off the hour is not shifted' );
    my $early = $cron->jitter( '0 9 * * *', at( 2026, 10, 21, 9, 0 ), key => 'o' );
    ok( $early <= 0 && $early >= -90, 'a one-shot on the hour runs up to 90 seconds early' ) or diag $early;
    my $half_hour = $cron->jitter( '30 9 21 10 *', at( 2026, 10, 21, 9, 30 ), key => 'p' );
    ok( $half_hour <= 0 && $half_hour >= -90, 'and on the half hour' ) or diag $half_hour;
    is( $cron->jitter( 'bad', 1, key => 'p', recurring => 1 ), 0, 'no jitter for an expression that does not parse' );
  } );
};

done_testing;
