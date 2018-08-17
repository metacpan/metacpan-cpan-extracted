#!/usr/bin/perl -w
use strict;
use warnings;

use Image::Synchronize::Timerange;
use Image::Synchronize::Timestamp;
use Test::More;
use Time::Local qw(timegm);

is( Image::Synchronize::Timerange->new('20170614T00/11:56'),
  undef, 'bad format' );
is(
  Image::Synchronize::Timerange->new('2017-06-14T00/11:56')->stringify,
  '2017-06-14T00:00:00/11:56:00',
  'ok format'
);

foreach my $test (
  {
    in    => '2001-02-03T04:05:06+07:08/2009-10-11T12:13:14-15:16',
    begin => '2001-02-03T04:05:06+07:08',
    end   => '2009-10-11T12:13:14-15:16',
  },
  {
    in    => '2001-02-03T04:05:06+07:08/12:13:14-15:16',
    begin => '2001-02-03T04:05:06+07:08',
    end   => '2001-02-03T12:13:14-15:16'
  },
  {
    in    => '2001-02-03T04:05:06+07:08/12:13:14',
    begin => '2001-02-03T04:05:06+07:08',
    end   => '2001-02-03T12:13:14+07:08'
  },
  {
    in    => '2001-02-03T04:05:06+07:08/2009-10-11T12:13:14',
    begin => '2001-02-03T04:05:06+07:08',
    end   => '2009-10-11T12:13:14+07:08'
  },
  {
    in    => '2001-02-03T04:05:06+07:08',
    begin => '2001-02-03T04:05:06+07:08',
    end   => '2001-02-03T04:05:06+07:08'
  },
  {
    in    => '2001-02-03T04:05:06+07:08/02:00:00',
    begin => '2001-02-03T02:00:00+07:08',
    end   => '2001-02-03T04:05:06+07:08'
  },

  # with pieces missing
  {
    in    => '2001-02-03T04:05:06/07:08:09',
    begin => '2001-02-03T04:05:06',
    end   => '2001-02-03T07:08:09'
  },
  {
    in    => '2001-02-03T04:05/07:08',
    begin => '2001-02-03T04:05:00',
    end   => '2001-02-03T07:08:00'
  },
  {
    in    => '2001-02-03T04/07',
    begin => '2001-02-03T04:00:00',
    end   => '2001-02-03T07:00:00'
  },
  {
    in    => '2001-02-03T23/04',
    begin => '2001-02-03T23:00:00',
    end   => '2001-02-03T04:00:00'
  },
  )
{
  my $text = "from text $test->{in}";
  my $t1   = Image::Synchronize::Timestamp->new( $test->{begin} );
  my $t2   = Image::Synchronize::Timestamp->new( $test->{end} );
  my $r    = Image::Synchronize::Timerange->new( $test->{in} );
  is( $r->begin->display_iso,
    $test->{begin}, sprintf( "%-16s $text", 'begin new' ) );
  is( $r->end->display_iso, $test->{end}, sprintf( "%-16s $text", 'end new' ) );
  is_deeply(
    [ $r->time_local ],
    [ $t1->time_local, $t2->time_local ],
    sprintf( "%-16s $text", 'time_local' )
  );
  is_deeply(
    [ $r->time_utc ],
    [ $t1->time_utc, $t2->time_utc ],
    sprintf( "%-16s $text", 'time_utc' )
  );
  is_deeply(
    [ $r->offset_from_utc ],
    [ $t1->offset_from_utc, $t2->offset_from_utc ],
    sprintf( "%-16s $text", 'offset_from_utc' )
  );
  is( $r->length, $t2 - $t1, sprintf( "%-16s $text", 'length' ) );
}

my $r = Image::Synchronize::Timerange->new;
is( "$r", "", 'empty range' );

foreach my $test (
  {
    in  => '2010-11-12T13:14:15',
    tzp => '2010-11-12T13:14:15+01:00',
    tzm => '2010-11-12T13:14:15-01:00',
  },
  {
    in   => '2010-11-12T13:14:15+06:17',
    tzp  => '2010-11-12T07:57:15+01:00',
    tzm  => '2010-11-12T05:57:15-01:00',
    tzno => '2010-11-12T13:14:15',
  },
  {
    in   => '2010-11-12T13:14:15+06:17/2010-11-12T13:14:15+06:17',
    out  => '2010-11-12T13:14:15+06:17',
    tzp  => '2010-11-12T07:57:15+01:00',
    tzm  => '2010-11-12T05:57:15-01:00',
    tzno => '2010-11-12T13:14:15',
  },
  {
    in   => '2010-11-12T13:14:15+06:17/2010-11-12T13:14:15+03:00',
    out  => '2010-11-12T13:14:15+06:17/13:14:15+03:00',
    tzp  => '2010-11-12T07:57:15+01:00/11:14:15',
    tzm  => '2010-11-12T05:57:15-01:00/09:14:15',
    tzno => '2010-11-12T13:14:15/16:31:15'
  },
  {
    in   => '2010-11-12T13:14:15+06:17/2010-11-12T13:14:17+06:17',
    out  => '2010-11-12T13:14:15+06:17/13:14:17',
    tzp  => '2010-11-12T07:57:15+01:00/07:57:17',
    tzm  => '2010-11-12T05:57:15-01:00/05:57:17',
    tzno => '2010-11-12T13:14:15/13:14:17',
  },
  )
{
  $r->set_from_text( $test->{in} );
  is( "$r", $test->{out} // $test->{in}, "set_from_text       $test->{in}" );
  my $r2 = $r->clone->set_timezone_offset(3600);
  is( "$r2", $test->{tzp}, "set_timezone_offset(+3600) $test->{in}" );
  $r2 = $r->clone->set_timezone_offset(-3600);
  is( "$r2", $test->{tzm}, "set_timezone_offset(-3600) $test->{in}" );
  $r2 = $r->clone->set_timezone_offset;
  is(
    "$r2",
    $test->{tzno} // $test->{in},
    "set_timezone_offset no     $test->{in}"
  );
}

foreach my $test (
  '2010-11-12T13:14:15',
  '2010-11-12T13:14:15+02:00',
  '2010-11-12T13:14:15/2011-01-01T00:00:00',
  '2010-11-12T13:14:15+02:00/2011-01-01T00:00:00+03:00',
  )
{
  my $r1 = Image::Synchronize::Timerange->new($test);
  my $r2 = Image::Synchronize::Timerange->new($test);
  ok( $r1->identical($r2), "$test identical to $test" );
}

for my $test ( '2010-11-12T13:14:15', '2010-11-12T13:14:15+03:00', ) {
  my $r1 = Image::Synchronize::Timerange->new($test);
  my $r2 = Image::Synchronize::Timerange->new("$test/$test");
  ok( $r1->identical($r2), "$test identical to $test/$test" );
  ok( $r2->identical($r1), "$test/$test identical to $test" );
}

for my $test (
  {
    one => '2010-11-12T13:14:15',
    two => [
      '2010-11-12T13:14:16', '2010-11-12T13:14:15+00:00',
      '2010-11-12T13:14:15/13:14:17'
    ],
  },
  {
    one => '2010-11-12T13:14:15+03:00',
    two => [
      '2010-11-12T13:14:16+03:00',
      '2010-11-12T13:14:15+03:01',
      '2011-11-12T13:14:15+03:00',
      '2010-11-12T13:14:15+03:00/13:14:17',
      '2010-11-12T13:14:14+03:00/13:14:16',
      '2010-11-12T12:14:16+02:00',
    ],
  },
  )
{
  my $r1 = Image::Synchronize::Timerange->new( $test->{one} );
  foreach my $two ( @{ $test->{two} } ) {
    my $r2 = Image::Synchronize::Timerange->new($two);
    ok( not( $r1->identical($r2) ), "$test->{one} not identical to $two" );
    ok( not( $r2->identical($r1) ), "$two not identical to $test->{one}" );
  }
}

foreach my $test (
  {
    one    => '2010-11-12T13:14:15',
    two    => '2010-11-12T13:14:15',
    expect => 0
  },
  {
    one    => '2010-11-12T13:14:15',
    two    => '2010-11-12T13:14:17',
    expect => -3
  },
  {
    one    => '2010-11-12T13:14:15-03:11',
    two    => '2010-11-12T13:14:15-03:11',
    expect => 0
  },
  {
    one    => '2010-11-12T13:14:15-03:11',
    two    => '2010-11-12T13:14:17-03:11',
    expect => -3
  },
  {
    one    => '2010-11-12T13:14:15-03:11',
    two    => '2010-11-12T11:14:15-05:11',
    expect => 0
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T17:00:01',
    expect => -3
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T17:00:00',
    expect => -2
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T15:00:01',
    expect => -2
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T15:00:00',
    expect => -1
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T14:59:59',
    expect => +2
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T13:00:00',
    expect => +2
  },
  {
    one    => '2010-11-12T13:00:00/17:00:00',
    two    => '2010-11-12T12:59:59',
    expect => +3
  },
  )
{
  # no timezone offsets
  my $r1 = Image::Synchronize::Timerange->new( $test->{one} );
  my $r2 = Image::Synchronize::Timerange->new( $test->{two} );
  is( $r1 <=> $r2, $test->{expect},  "$test->{one} <=> $test->{two}" );
  is( $r2 <=> $r1, -$test->{expect}, "$test->{two} <=> $test->{one}" );

  # one timezone offset
  $r1->set_timezone_offset(2000);
  is( $r1 <=> $r2, $test->{expect},  "$test->{one} TZ <=> $test->{two}" );
  is( $r2 <=> $r1, -$test->{expect}, "$test->{two} <=> $test->{one} TZ" );

  # two equal timezone offsets
  $r2->set_timezone_offset(2000);
  is( $r1 <=> $r2, $test->{expect},  "$test->{one} TZ <=> $test->{two} TZ" );
  is( $r2 <=> $r1, -$test->{expect}, "$test->{two} TZ <=> $test->{one} TZ" );
}

foreach my $test (
  {
    two    => '2010-11-12T17:00:01+04:00/19:00:00',
    expect => -3
  },
  {
    two    => '2010-11-12T17:00:00+04:00/19:00:00',
    expect => -2
  },
  {
    two    => '2010-11-12T15:00:00+04:00/17:00:00',
    expect => -2
  },
  {
    two    => '2010-11-12T14:00:01+04:00/16:00:00',
    expect => -2
  },
  {
    two    => '2010-11-12T14:00:00+04:00/16:00:00',
    expect => -1
  },
  {
    two    => '2010-11-12T13:00:01+04:00/16:59:59',
    expect => -1
  },
  {
    two    => '2010-11-12T13:00:00+04:00/17:00:00',
    expect => 0
  },
  {
    two    => '2010-11-12T13:59:59+04:00/16:00:00',
    expect => +2
  },
  {
    two    => '2010-11-12T11:00:00+04:00/13:00:00',
    expect => +2
  },
  {
    two    => '2010-11-12T10:00:00+04:00/12:00:00',
    expect => +3
  },
  )
{
  my $one = '2010-11-12T13:00:00+04:00/17:00:00';
  my $r1  = Image::Synchronize::Timerange->new($one);
  my $r2  = Image::Synchronize::Timerange->new( $test->{two} );
  is( $r1 <=> $r2, $test->{expect},  "$one <=> $test->{two}" );
  is( $r2 <=> $r1, -$test->{expect}, "$test->{two} <=> $one" );
}

$r = Image::Synchronize::Timerange->new('2010-11-12T13:14:15+06:07/18:19:20');
my $r2 = $r + 360;
is( "$r2", '2010-11-12T13:20:15+06:07/18:25:20', 'plus 360' );
$r2 = $r - 360;
is( "$r2", '2010-11-12T13:08:15+06:07/18:13:20', 'minus 360' );

ok( $r->contains_instant( $r->begin->time_utc ),     'contains begin' );
ok( $r->contains_instant( $r->begin->time_utc + 1 ), 'contains begin + 1' );
ok( not( $r->contains_instant( $r->begin->time_utc - 1 ) ),
  'does not contain begin - 1' );
ok( $r->contains_instant( $r->end->time_utc ),     'contains end' );
ok( $r->contains_instant( $r->end->time_utc - 1 ), 'contains end - 1' );
ok( not( $r->contains_instant( $r->end->time_utc + 1 ) ),
  'does not contain end + 1' );
ok( $r->contains_instant( $r->begin ),     'contains begin ET' );
ok( $r->contains_instant( $r->begin + 1 ), 'contains begin + 1 ET' );
ok( not( $r->contains_instant( $r->begin - 1 ) ),
  'does not contain begin - 1 ET' );
ok( $r->contains_instant( $r->end ),            'contains end ET' );
ok( $r->contains_instant( $r->end - 1 ),        'contains end - 1 ET' );
ok( not( $r->contains_instant( $r->end + 1 ) ), 'does not contain end + 1 ET' );

foreach my $tz ( '', '+01:02', '-17:18' ) {
  ok(
    not(
      $r->contains_local(
        Image::Synchronize::Timestamp->new("2010-11-12T13:14:14$tz")
      )
    ),
    "local does not contain begin - 1 $tz"
  );
  ok(
    $r->contains_local(
      Image::Synchronize::Timestamp->new("2010-11-12T13:14:15$tz")
    ),
    "local contains begin $tz"
  );
  ok(
    $r->contains_local(
      Image::Synchronize::Timestamp->new("2010-11-12T13:14:16$tz")
    ),
    "local contains begin + 1 $tz"
  );
  ok(
    $r->contains_local(
      Image::Synchronize::Timestamp->new("2010-11-12T18:19:19$tz")
    ),
    "local contains end - 1 $tz"
  );
  ok(
    $r->contains_local(
      Image::Synchronize::Timestamp->new("2010-11-12T18:19:20$tz")
    ),
    "local contains end $tz"
  );
  ok(
    not(
      $r->contains_local(
        Image::Synchronize::Timestamp->new("2010-11-12T18:19:21$tz")
      )
    ),
    "local does not contain end + 1 $tz"
  );
}

done_testing();
