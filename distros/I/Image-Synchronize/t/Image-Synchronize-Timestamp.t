#!/usr/bin/perl -w
use strict;
use warnings;

use Image::Synchronize::Timestamp;
use Scalar::Util qw(refaddr);
use Test::More;
use Time::Local qw(timegm);

sub parse_components_ {
  Image::Synchronize::Timestamp::parse_components_(@_);
}

my $et = Image::Synchronize::Timestamp->new;
isa_ok( $et, 'Image::Synchronize::Timestamp' );
is( $et->time_local,      undef, 'time_local undef' );
is( $et->time_utc,        undef, 'time_utc undef' );
is( $et->offset_from_utc, undef, 'offset_from_utc undef' );
is( $et->stringify,       undef, 'stringify undef' );
{
  no warnings;    # don't complain about $et being undefined
  is( "$et", '', 'stringify undef' );
}

foreach my $test (
  {
    in         => '2001-02-03T04:05:06+07:08:09',
    components => [ 2001, 2, 3, 4, 5, 6, 7 * 3600 + 8 * 60 + 9 ]
  },
  {
    in         => '2001-02-03T04:05:06+07:08',
    components => [ 2001, 2, 3, 4, 5, 6, 7 * 3600 + 8 * 60 ]
  },
  {
    in         => '2001-02-03T04:05:06-07:08',
    components => [ 2001, 2, 3, 4, 5, 6, -7 * 3600 - 8 * 60 ]
  },
  {
    in         => '2001-02-03T04:05:06Z',
    components => [ 2001, 2, 3, 4, 5, 6, 0 ]
  },
  {
    in         => '2001:02:03T04:05:06',
    components => [ 2001, 2, 3, 4, 5, 6, undef ]
  },
  {
    in         => '2001-02-03 04:05:06',
    components => [ 2001, 2, 3, 4, 5, 6, undef ]
  },
  {
    in         => '2001-02-03T04:05',
    components => [ 2001, 2, 3, 4, 5, undef, undef ]
  },
  {
    in         => '2001-02-03T04',
    components => [ 2001, 2, 3, 4, undef, undef, undef ]
  },
  {
    in         => '04:05:06',
    components => [ undef, undef, undef, 4, 5, 6, undef ]
  },
  {
    in         => '04:05:06-07:08',
    components => [ undef, undef, undef, 4, 5, 6, -7 * 3600 - 8 * 60 ]
  },
  {
    in         => '04:05:06+07',
    components => [ undef, undef, undef, 4, 5, 6, 7 * 3600 ]
  },
  {
    in         => '04:05',
    components => [ undef, undef, undef, 4, 5, undef, undef ]
  },
  {
    in         => '04',
    components => [ undef, undef, undef, 4, undef, undef, undef ]
  },
  )
{
  is_deeply( [ parse_components_( $test->{in} ) ],
    $test->{components}, "parse_components_ $test->{in}" );
}

foreach my $test (
  {
    in  => '2001-02-03T04:05:06+07:08:09',
    out => '2001-02-03T04:05:06+07:08:09'
  },
  {
    in  => '2001:02:03 04:05:06+07:08',
    out => '2001-02-03T04:05:06+07:08'
  },
  {
    in  => '2001-02-03T04:05:06-07:08',
    out => '2001-02-03T04:05:06-07:08'
  },
  {
    in  => '2001-02-03T04:05:06Z',
    out => '2001-02-03T04:05:06+00:00'
  },
  {
    in  => '2001-02-03T04:05:06+00:00',
    out => '2001-02-03T04:05:06+00:00'
  },
  {
    in  => '2001:02:03T04:05:06',
    out => '2001-02-03T04:05:06'
  },
  {
    in  => '2001-02-03 04:05:06',
    out => '2001-02-03T04:05:06'
  },
  {
    in  => '2001-02-03T04:05',
    out => '2001-02-03T04:05:00'
  },
  {
    in  => '2001-02-03T04',
    out => '2001-02-03T04:00:00'
  },
  {
    in  => '2001-02-03T04+01',
    out => '2001-02-03T04:00:00+01:00'
  },
  )
{
  is( Image::Synchronize::Timestamp->new( $test->{in} )->display_iso,
    $test->{out}, 'timestamp ' . $test->{out} );
}

foreach my $test (
  {
    in  => [ '04:05:06', '2001-02-03T04:05:06+07:08:09' ],
    out => '2001-02-03T04:05:06+07:08:09'
  },
  {
    in  => [ '12:15:33', '2001:02:03 04:05:06+07:08' ],
    out => '2001-02-03T12:15:33+07:08'
  },
  {
    in  => [ '01:00:00', '2001:02:03 04:05:06+07:08' ],
    out => '2001-02-03T01:00:00+07:08'
  },
  {
    in  => [ '16:05:07', '2001:02:03 04:05:06+07:08' ],
    out => '2001-02-02T16:05:07+07:08'
  },
  {
    in  => [ '16:05:06', '2001-02-03T04:05:06-07:08' ],
    out => '2001-02-03T16:05:06-07:08'
  },
  {
    in  => [ '16:05:05', '2001-02-03T04:05:06-07:08' ],
    out => '2001-02-03T16:05:05-07:08'
  },
  )
{
  is( Image::Synchronize::Timestamp->new( @{ $test->{in} } )->display_iso,
    $test->{out}, "2 timestamps @{$test->{in}}" );
}

my $text = '2001:02:03 04:05:06';
is_deeply(
  [ parse_components_($text) ],
  [ 2001, 2, 3, 4, 5, 6, undef ],
  "parse_components_ $text"
);
is( $et->set_from_text($text)->stringify, $text, "set_from_text $text" );
my $time = timegm( 6, 5, 4, 3, 2 - 1, 2001 - 1900 );
is( $et->time_local,      $time, "time_local $text" );
is( $et->time_utc,        undef, "time_utc $text" );
is( $et->offset_from_utc, undef, "offset_from_utc $text" );
is( $et->stringify,       $text, "stringify $text" );
is( "$et",                $text, "stringify $text" );

$text = '2005-11-23 17:44:28+02:10';
my $et2 = Image::Synchronize::Timestamp->new($text);
my $time2 = timegm( 28, 44, 17, 23, 11 - 1, 2005 - 1900 );
is( $et2->time_local, $time2, "time_local $text" );
is( $et2->time_utc, $time2 - 2 * 3600 - 10 * 60, "time_utc $text" );
is( $et2->offset_from_utc, 2 * 3600 + 10 * 60, "offset_from_utc $text" );
my $text2 = $text;
$text2 =~ s/-/:/g;
is( $et2->stringify, $text2, "stringify $text" );
is( "$et2",          $text2, "stringify $text" );

my $et3 = $et->clone;
isnt( refaddr($et3), refaddr($et), 'clone has different address' );
ok( $et3 == $et,  'clone has same value' );
ok( $et3 != $et2, 'different value' );

my $et4 = Image::Synchronize::Timestamp->new('2005:11:23 17:44:28');
ok( not( $et4->identical($et2) ), 'different, missing offset' );
is( $et4->time_local, $et2->time_local, 'equal local time' );
isnt( $et4->time_utc,        $et2->time_utc,        'unequal utc time' );
isnt( $et4->offset_from_utc, $et2->offset_from_utc, 'unequal offset' );
$et4 = $et4->combine($et2);
isnt( refaddr($et4), refaddr($et2), 'not the same object' );
is( "$et4", "$et2", 'the same stringification' );

$et  = Image::Synchronize::Timestamp->new('2012-03-04T17:12:14');
$et2 = Image::Synchronize::Timestamp->new('2012-03-04T20:12:14');
is( $et2 - $et, 3 * 3600, 'difference no timezone' );

$et = Image::Synchronize::Timestamp->new('2012-03-04T17:12:14+03:00');
is( $et2 - $et, 3 * 3600, 'difference one timezone' );

$et2 = Image::Synchronize::Timestamp->new('2012-03-04T20:12:14+02:00');
is( $et2 - $et, 4 * 3600, 'difference two timezones' );

$et3 = $et2 + 20;
is( "$et3", '2012:03:04 20:12:34+02:00', 'add scalar' );
$et3 = $et2 - 20;
is( "$et3", '2012:03:04 20:11:54+02:00', 'subtract scalar' );

foreach my $test (
  [ '2012-03-04T05:06:07',       '2012-03-04T05:06:07' ],
  [ '2012-03-04T05:06:07',       '2012-03-04T05:06:08' ],
  [ '2012-03-04T05:06:07+08:00', '2012-03-04T05:06:08' ],
  [ '2012-03-04T05:06:08+08:00', '2012-03-04T05:06:08' ],
  [ '2012-03-04T05:06:07-08:00', '2012-03-04T05:06:08' ],
  [ '2012-03-04T05:06:08-08:00', '2012-03-04T05:06:08' ],
  [ '2012-03-04T05:06:07+08:00', '2012-03-04T05:06:08+08:00' ],
  [ '2012-03-04T05:06:08+08:00', '2012-03-04T05:06:08+08:00' ],
  [ '2012-03-04T06:06:08+08:00', '2012-03-04T05:06:08+07:00' ],
  )
{
  ok(
    Image::Synchronize::Timestamp->new( $test->[0] ) <=
      Image::Synchronize::Timestamp->new( $test->[1] ),
    "$test->[0] <= $test->[1]"
  );
  ok(
    Image::Synchronize::Timestamp->new( $test->[1] ) >=
      Image::Synchronize::Timestamp->new( $test->[0] ),
    "$test->[1] >= $test->[0]"
  );
}

my $noet = Image::Synchronize::Timestamp->new;
ok( $noet <= $noet, 'undef <= undef' );
ok( $noet >= $noet, 'undef >= undef' );
ok( $noet <= $et2,  'undef <= def' );
ok( $et2 >= $noet,  'def >= undef' );

$et = Image::Synchronize::Timestamp->new('2012-03-04T17:12:14+03:00');
is( $et->display_utc, '2012-03-04T14:12:14Z', 'utc' );
$et2 = Image::Synchronize::Timestamp->new('2012-03-04T20:12:14');

$et->set_timezone_offset(3600);
is( $et->display_iso, '2012-03-04T15:12:14+01:00', 'set_timezone_offset w/tz' );

$et2->set_timezone_offset(3600);
is( $et2->display_iso, '2012-03-04T20:12:14+01:00',
  'set_timezone_offset wo/tz' );

my $l   = $et->local_offset_from_utc;
my $etu = $et->time_utc;
$et->clone_to_local_timezone;
is( $et->time_utc,        $etu, 'clone_to_local_timezone' );
is( $et->offset_from_utc, $l,   'local timezone offset' );

$et->set_timezone_offset(3603);
is( $et->display_iso, '2012-03-04T15:12:17+01:00:03', 'timezone with seconds' );

$et->set_timezone_offset(-3603);
is(
  $et->display_iso,
  '2012-03-04T13:12:11-01:00:03',
  'negative timezone with seconds'
);

is( $et->date, '2012:03:04', 'date' );
is( $et->time, '13:12:11',   'time' );

done_testing();
