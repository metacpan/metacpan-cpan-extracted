#!/usr/bin/perl
use Modern::Perl;

use Scalar::Util qw(refaddr looks_like_number);
use Test::More;
use Time::Local qw(timegm_modern timelocal_modern);
use Image::Synchronize::Timestamp;

sub parse_components_ {
  Image::Synchronize::Timestamp::parse_components_(@_);
}

# test unrecognized timestamp

foreach my $test
  (
   undef,                       # undefined
   '',                          # empty
   '2001-02-03',                # date only
   'some text',
   ' 2001-02-03T04:05:06',      # whitespace prefix
 )
{
  my $et = Image::Synchronize::Timestamp->new($test);
  ok(not(defined $et), 'unrecognized timestamp: ' . ($test // 'undef'));
}

my $chosen_time = 981180000;
my $chosen_time_iso = '2001-02-03T06:00:00Z';
is_deeply([gmtime($chosen_time)],
          # sec,min,hr,mday,mon,year,wday,yday,isdst
          [   0,  0, 6,   3,  1, 101,   6,  33,    0],
          'check chosen time');

# test various ways of specifying the same instant of time with
# timezone, equivalent to 2001-02-03T06:00:00Z

foreach my $test
  (
   '2001:02:03 14:00:00+08:00', # exif format with timezone
   '2001-02-03 14:00:00+08:00', # - as date separator
   '2001-02-03T14:00:00+08:00', # ISO 8601
   '2001-02-03T14:00:00+08:00:00', # timezone seconds, too
   '2001-02-03T14:00:00+08',    # timezone hours only
   '2001-02-03T14:00+08:00',    # no clock seconds
   '2001-02-03T14+08',          # no minutes or seconds
   '2001-02-03T13+07',          # different timezone, same instant
   '2001-02-03T06+00',          # UTC
   '2001-02-03T06Z',            # UTC
   '2001-02-03T05-01',          # negative timezone offset
   '2001-02-03T05-1',           # single timezone hour digit
   '2001-2-3T7+1',              # omit initial 0s
 )
{
  my $et = Image::Synchronize::Timestamp->new($test);
  is($et->time_utc, $chosen_time, "same instant with tz: $test");
}

# test epoch
{
  my $et = Image::Synchronize::Timestamp->new('1970-01-01T00+00');
  is($et->time_utc, 0, 'epoch');
}

# test minutes and seconds
foreach my $test
  (
   {
    in => '2001-02-03T14:15:16+08:00:00',
    expect => $chosen_time + 15*60 + 16,
  },
   {
    in => '2001-02-03T14:00:00+08:09:10',
    expect => $chosen_time - 9*60 - 10,
  },
 )
{
  my $et = Image::Synchronize::Timestamp->new($test->{in});
  is($et->time_utc, $test->{expect}, 'same instant with tz: ' . $test->{in});
}

# test various ways of specifying the same time without a date, which
# is 06:00:00Z

foreach my $test
  (
   '+14:00:00+08:00',
   '+14+8',
   '+6Z',
   '+06:00+00:00',
   '14:00+8',
   '14+8',
   '6Z',
   '6+0',
   '6-0',
 )
{
  my $et = Image::Synchronize::Timestamp->new($test);
  is($et->time_utc, 21600, "same time with tz without a date: $test");
}

# test various ways of specifying the same instant of time without
# timezone, equivalent to 2001-02-03T06:00:00

foreach my $test
  (
   '2001:02:03 06:00:00',          # exif format
   '2001-02-03 06:00:00',          # - as date separator
   '2001-02-03T06:00:00',          # ISO 8601
   '2001-02-03T06:00',             # no clock seconds
   '2001-02-03T06',                # no minutes or seconds
 )
{
  my $et = Image::Synchronize::Timestamp->new($test);
  is($et->time_local, $chosen_time, "same instant no tz: $test");
}

# test minutes and seconds, without timezone
foreach my $test
  (
   {
    in => '2001-02-03T06:15:16',
    expect => $chosen_time + 15*60 + 16,
  },
 )
{
  my $et = Image::Synchronize::Timestamp->new($test->{in});
  is($et->time_local, $test->{expect}, 'same instant no tz: ' . $test->{in});
}

# test various ways of specifying the same time without a date and
# timezone, equivalent to 06:00:00

foreach my $test
  (
   '+06:00:00',
   '+6:0',
 )
{
  my $et = Image::Synchronize::Timestamp->new($test);
  is($et->time_local, 21600, "same time without a date or tz: $test");
}

# clone

{
  my $et = Image::Synchronize::Timestamp->new('2000-01-01T11:03');
  my $et2 = $et;
  is("$et2", "$et", 'assignment yields same value');
  is(refaddr($et2), refaddr($et), 'assignment yields ref to same object');

  $et = $et->clone;
  is("$et2", "$et", 'clone yields same value');
  isnt(refaddr($et2), refaddr($et), 'clone yields ref to other object');
}

# stringify

{
  my $et = Image::Synchronize::Timestamp->new('2000-01-01T11:03');
  is("$et", '2000:01:01 11:03:00', 'implicit stringify');
  is($et->stringify, '2000:01:01 11:03:00', 'explicit stringify');
  is($et->display_iso, '2000-01-01T11:03:00', 'ISO 8601 stringify');
  is($et->display_utc, undef, 'UTC stringify'); # no timezone, so undef
  is($et->display_time, '+262979:03', 'time stringify');

  $et = Image::Synchronize::Timestamp->new('2000-01-01T11:03:05');
  is("$et", '2000:01:01 11:03:05', 'implicit stringify, with seconds');
  is($et->stringify, '2000:01:01 11:03:05', 'explicit stringify, with seconds');
  is($et->display_iso, '2000-01-01T11:03:05', 'ISO 8601 stringify, with seconds');
  is($et->display_utc, undef, 'UTC stringify, with seconds'); # no timezone, so undef
  is($et->display_time, '+262979:03:05', 'time stringify, with seconds');

  $et = Image::Synchronize::Timestamp->new('2000-01-01T11:03+01');
  is("$et", '2000:01:01 11:03:00+01:00', 'implicit stringify, with tz');
  is($et->stringify, '2000:01:01 11:03:00+01:00', 'explicit stringify, with tz');
  is($et->display_iso, '2000-01-01T11:03:00+01:00', 'ISO 8601 stringify, with tz');
  is($et->display_utc, '2000-01-01T10:03:00Z', 'UTC stringify, with tz');
  is($et->display_time, '+262979:03+01:00', 'time stringify, with tz');

  $et = Image::Synchronize::Timestamp->new('16:44');
  is("$et", '+16:44', 'implicit stringify (no date)');
  is($et->stringify, '+16:44', 'explicit stringify (no date)');
  is($et->display_iso, '+16:44', 'ISO 8601 stringify (no date)');
  is($et->display_utc, undef, 'UTC stringify (no date)');
  is($et->display_time, '+16:44', 'time stringify (no date)');
}

# query

{
  my $et = Image::Synchronize::Timestamp->new($chosen_time_iso);
  is($et->time_utc, $chosen_time, 'time_utc');
  is($et->time_local, $chosen_time, 'time_local'); # here same as UTC
  is($et->timezone_offset, 0, 'timezone_offset');

  $et->set_timezone_offset(3600); # UTC+1
  is($et->time_utc, $chosen_time - 3600, 'time_utc (shifted tz)');
  is($et->time_local, $chosen_time, 'time_local (shifted tz)');
  is($et->timezone_offset, 3600, 'timezone_offset (shifted tz)');

  my @t = localtime($chosen_time);
  my $tz_offset = timegm_modern(@t) - timelocal_modern(@t);
  is($et->local_timezone_offset, $tz_offset, 'local_timezone_offset');

  ok($et->has_timezone_offset, 'has_timezone_offset');
  $et->remove_timezone;
  ok(not($et->has_timezone_offset), 'has_timezone_offset (no tz)');

  ok(not($et->is_empty), 'is_empty (not empty)');

  $et = Image::Synchronize::Timestamp->new;
  ok($et->is_empty, 'is empty');

  ok(Image::Synchronize::Timestamp->istypeof($et), 'istypeof (class)');
  ok($et->istypeof($et), 'istypeof (object)');
  ok(not($et->istypeof(3)), '3 is not a timestamp');
}

# combine

{
  my $et = Image::Synchronize::Timestamp->new($chosen_time_iso);
  my $et2 = $et + 30;
  is($et2->time_utc - $et->time_utc, 30, 'timestamp + 30');

  $et2 = 30 + $et;
  is($et2->time_utc - $et->time_utc, 30, '30 + timestamp');

  $et2 += 20;
  is($et2->time_utc - $et->time_utc, 50, 'timestamp += 20');

  eval {
    my $et3 = $et + $et2;
  };
  like($@, qr/^Sorry, cannot add Image::Synchronize::Timestamp and Image::Synchronize::Timestamp/, 'cannot add timestamps');

  my $d = $et2 - $et;
  is($d, 50, 'subtract timestamps');
  $et2 = $et - 20;
  is($et->time_utc - $et2->time_utc, 20, 'timestamp - 20');

  $et->set_timezone_offset(3600);
  $et2 = -$et;
  is($et2->time_local, -$et->time_local, 'negative (time)');
  is($et2->timezone_offset, $et->timezone_offset, 'negative (tz)');

  $et2 = $et->clone;
  $et -= 30;
  is($et2->time_utc - $et->time_utc, 30, 'timestamp -= 30');

  # now without timezone
  
  $et = Image::Synchronize::Timestamp->new($chosen_time_iso)
    ->remove_timezone;
  $et2 = $et + 30;
  is($et2->time_local - $et->time_local, 30, 'timestamp + 30 (no tz)');

  $et2 = 30 + $et;
  is($et2->time_local - $et->time_local, 30, '30 + timestamp (no tz)');

  $et2 += 20;
  is($et2->time_local - $et->time_local, 50, 'timestamp += 20 (no tz)');

  eval {
    my $et3 = $et + $et2;
  };
  like($@, qr/^Sorry, cannot add Image::Synchronize::Timestamp and Image::Synchronize::Timestamp/, 'cannot add timestamps (no tz)');

  $d = $et2 - $et;
  is($d, 50, 'subtract timestamps (no tz)');
  $et2 = $et - 20;
  is($et->time_local - $et2->time_local, 20, 'timestamp - 20 (no tz)');

  $et2 = -$et;
  is($et2->time_local, -$et->time_local, 'negative (time) (no tz)');
  ok(not($et2->has_timezone_offset), 'still no timezone after negative');

  $et2 = $et->clone;
  $et -= 30;
  is($et2->time_local - $et->time_local, 30, 'timestamp -= 30 (no tz)');
}

# compare

{
  my $t1 = Image::Synchronize::Timestamp->new('+17:44:12+03:00');
  my $t2 = Image::Synchronize::Timestamp->new('+15:44:12+01:00');
  my $t3 = Image::Synchronize::Timestamp->new('+17:00:00+03:00');

  ok($t1 == $t2, '==');    # same instant (though different timezones)
  ok($t3 < $t1, '<');
  ok($t3 <= $t1, '<=');
  ok($t2 >= $t3, '>=');        # because compares UTC, not clock times
  ok($t2 > $t3, '>');
  ok($t3 != $t2, '!=');
  ok($t1->identical($t1), 'identical'); # same clock time and timezone

  ok(not($t1->identical($t2)), 'not identical'); # same instant but
                                                 # not identical time
                                                 # and timezone

  # three-way compare
  is($t1 <=> $t2, 0, '<=> 0');  # same instant
  is($t1 <=> $t3, +1, '<=> +1'); # first one is later
  is($t3 <=> $t1, -1, '<=> -1'); # first one is earlier
}

# modify

{
  my $et = Image::Synchronize::Timestamp->new($chosen_time_iso);
  $et->set_from_text('+17:0'); # old contents are lost
  is($et->display_time, '+17:00', 'set_from_text');
  $et->set_from_text(17); # old contents are lost
  is($et->display_time, '+00:00:17', 'set_from_text');
}

{
  my $et = Image::Synchronize::Timestamp->new($chosen_time_iso); # 06+00
  my $et2 = $et->clone->adjust_timezone_offset(-3600);           # 05-01
  is($et2->time_utc, $et->time_utc, 'adjust_timezone_offset (utc)');
  is($et2->time_local, $et->time_local - 3600,
     'adjust_timezone_offset (local)');

  $et = $et2->clone->adjust_to_utc; # 05-01 -> 06+00
  is($et->time_utc, $et2->time_utc, 'adjust_to_utc (utc)');
  is($et->time_local, $et2->time_local + 3600,
     'adjust_to_utc (local)');

  $et2 = $et->clone->set_timezone_offset(3600); # 05-01 -> 05+01
  is($et->time_local, $et2->time_local, 'set_timezone_offset');
  is($et2->timezone_offset, 3600, 'offset_from_utc');

  $et2->remove_timezone;
  ok(not(defined $et2->timezone_offset), 'remove_timezone');
}

done_testing();
