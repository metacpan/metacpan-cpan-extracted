#!/usr/bin/perl -w
use Modern::Perl;

use Image::Synchronize::CameraOffsets;
use Image::Synchronize::Logger qw(log_message set_printer);
use Image::Synchronize::Timestamp;
use Test::More;
use YAML::Any qw(Dump Load);

sub t {
  Image::Synchronize::Timestamp->new($_[0]);
}

sub v {
  my $t = Image::Synchronize::Timestamp->new($_[0]);
  return $t->time_utc // $t->time_local;
}

my $co = Image::Synchronize::CameraOffsets->new;
isa_ok( $co, 'Image::Synchronize::CameraOffsets' );
is( $co->get( 'A', t('2020-08-12T10:00:00') ), undef,
    'no data yet for camera A' );

$co->set( 'A', t('2020-08-12T12:34:00'), -5 );
is_deeply(
  $co->{added},
  { A => { v('2020-08-12T12:34:00') => { offset => '-00:00:05' } } },
  'set first item'
);
is_deeply( $co->{effective}, {}, 'not synchronized yet' );
is( $co->get( 'B', t('2020-08-12T10:00:00') ), undef,
    'no data for camera B' );
is_deeply( $co->{effective}, { A => { v('2020-08-12T12:34:00') => '-00:00:05' } },
           'synchronized' );
is( $co->get( 'A', t('2020-08-12T12:33:00') ), '-00:00:05', 'before first' );
is( $co->get( 'A', t('2020-08-12T12:34:00') ), '-00:00:05', 'begin of segment' );
is( $co->get( 'A', t('2020-08-12T12:35:00') ), '-00:00:05', 'after last' );

$co->set( 'A', t('2020-08-12T13:05:00'), '-00:00:05' );
is_deeply(
  $co->{added},
  {
    A => {
      v('2020-08-12T12:34:00') => { offset => '-00:00:05' },
      v('2020-08-12T13:05:00') => { offset => '-00:00:05' }
    }
  },
  'extend segment'
);
is( $co->get( 'A', v('2020-08-12T12:33:00') ), '-00:00:05',
    '2020-08-12T12:33:00 before first' );
is_deeply(
  $co->{effective},
  {
    A => {
      v('2020-08-12T12:34:00') => '-00:00:05',
      v('2020-08-12T13:05:00') => '-00:00:05'
    }
  },
  'synchronized'
);
is( $co->get( 'A', t('2020-08-12T12:34:00') ), '-00:00:05',
    '2020-08-12T12:34:00 in segment 1' );
is( $co->get( 'A', t('2020-08-12T12:35:00') ), '-00:00:05',
    '2020-08-12T12:35:00 in segment 1' );
is( $co->get( 'A', t('2020-08-12T13:05:00') ), '-00:00:05',
    '2020-08-12T13:05:00 in segment 1' );
is( $co->get( 'A', t('2020-08-12T13:06:00') ), '-00:00:05',
    '2020-08-12T13:06:00 after last ' );

$co->set( 'A', t('2020-08-12T14:00:00'), '-00:00:05' );
is_deeply(
  $co->{added},
  {
    A => {
      v('2020-08-12T12:34:00') => { offset => '-00:00:05' },
      v('2020-08-12T13:05:00') => { offset => '-00:00:05' },
      v('2020-08-12T14:00:00') => { offset => '-00:00:05' }
    }
  },
  'extend segment'
);
$co->set( 'A', t('2020-08-12T14:45:00'), 0 );
is_deeply(
  $co->{added},
  {
    A => {
      v('2020-08-12T12:34:00') => { offset => '-00:00:05' },
      v('2020-08-12T13:05:00') => { offset => '-00:00:05' },
      v('2020-08-12T14:00:00') => { offset => '-00:00:05' },
      v('2020-08-12T14:45:00') => { offset => '+00:00' }
    }
  },
  'new segment'
);
$co->set( 'A', t('2020-08-12T15:00:00'), 0 );
is_deeply(
  $co->{added},
  {
    A => {
      v('2020-08-12T12:34:00') => { offset => '-00:00:05' },
      v('2020-08-12T13:05:00') => { offset => '-00:00:05' },
      v('2020-08-12T14:00:00') => { offset => '-00:00:05' },
      v('2020-08-12T14:45:00') => { offset => '+00:00' },
      v('2020-08-12T15:00:00') => { offset => '+00:00' }
    }
  },
  'extend segment'
);

is_deeply(
  $co->{effective},
  {
    A => {
      v('2020-08-12T12:34:00') => '-00:00:05',
      v('2020-08-12T13:05:00') => '-00:00:05'
    }
  },
  'not resynchronized'
);
is( $co->get( 'A', t('2020-08-12T12:33:00') ), '-00:00:05', 'before first' );
is_deeply(
  $co->{effective},
  {
    A => {
      v('2020-08-12T12:34:00') => '-00:00:05',
      v('2020-08-12T14:45:00') => '+00:00',
      v('2020-08-12T15:00:00') => '+00:00'
    }
  },
  'resynchronized'
);
is( $co->get( 'A', t('2020-08-12T14:44:00') ), '-00:00:05', 'first' );
is( $co->get( 'A', t('2020-08-12T14:45:00') ), '+00:00',  'begin of last' );
is( $co->get( 'A', t('2020-08-12T15:00:00') ), '+00:00',  'end of last' );
is( $co->get( 'A', t('2020-08-12T15:00:00') ), '+00:00',  'beyond last' );

my $two_ranges = <<EOD;
---
A:
  '2020-08-12T10:00:00' : -00:00:05
  '2020-08-12T20:00:00' : '+00:00'
  '2020-08-13T01:00:00' : '+00:00'
EOD

sub test_id {
  my ($text) = @_;
  $text =~ s/^---//;
  $text =~ s/\s*\n\s*/ /g;
  $text;
}

my @tests = (
  {    # conflict
    input => <<EOD,
'2020-08-12T15:00:00': '-00:00:05'
'2020-08-12T20:00:00': '-00:00:05'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new before first, other offset
    input => <<EOD,
'2020-08-12T04:00:00' : -7
'2020-08-12T08:00:00' : -7
EOD
    expect => <<EOD,
---
A:
  2020-08-12T04:00:00: -00:00:07
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new before first, same offset
    input => <<EOD,
'2020-08-12T04:00:00': '-00:00:05'
'2020-08-12T08:00:00': '-00:00:05'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T04:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new equal to first
    input => <<EOD,
'2020-08-12T10:00:00': '-00:00:05'
'2020-08-12T15:00:00': '-00:00:05'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new after first, same offset
    input => <<EOD,
'2020-08-12T15:00:00': '-00:00:05'
'2020-08-12T17:00:00': '-00:00:05'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new between first and second, other offset
    input => <<EOD,
'2020-08-12T16:00:00': 77
'2020-08-12T17:00:00': 77
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T16:00:00: +00:01:17
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new between first and second, touching second
    input => <<EOD,
'2020-08-12T17:00:00': '+00:00'
'2020-08-12T20:00:00': '+00:00'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T17:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new equal to existing
    input => <<EOD,
'2020-08-12T20:00:00': '+00:00'
'2020-08-13T01:00:00': '+00:00'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new range encompassing second, merge
    input => <<EOD,
'2020-08-12T18:00:00': '+00:00'
'2020-08-13T03:00:00': '+00:00'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T18:00:00: +00:00
  2020-08-13T03:00:00: +00:00
EOD
  },

  {    # new range after and touching last, merge
    input => <<EOD,
'2020-08-12T20:00:00': '+00:00'
'2020-08-13T03:00:00': '+00:00'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T03:00:00: +00:00
EOD
  },

  {    # new range after and touching last, merge
    input => <<EOD,
'2020-08-13T01:00:00': '+00:00'
'2020-08-13T04:00:00': '+00:00'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T04:00:00: +00:00
EOD
  },

  {    # new range after last, merge
    input => <<EOD,
'2020-08-13T03:00:00': '+00:00'
'2020-08-13T04:00:00': '+00:00'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T04:00:00: +00:00
EOD
  },

  {    # new range after last, other offset
    input => <<EOD,
'2020-08-13T03:00:00': 22
'2020-08-13T04:00:00': 22
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T03:00:00: +00:00:22
  2020-08-13T04:00:00: +00:00:22
EOD
  },

  {
    input => <<EOD,
'2020-08-12T09:00:00': -10
'2020-08-12T13:00:00': -10
EOD
    expect => <<EOD,
---
A:
  2020-08-12T09:00:00: -00:00:10
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T13:00:00: -00:00:10
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new range after and overlapping first, conflict
    input => <<EOD,
'2020-08-12T13:00:00': -10
'2020-08-12T16:00:00': -10
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T13:00:00: -00:00:10
  2020-08-12T20:00:00: +00:00
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new range overlapping first and second, conflict
    input => <<EOD,
'2020-08-12T13:00:00': '-00:00:05'
'2020-08-12T22:00:00': '-00:00:05'
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-12T22:00:00: -00:00:05
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new range before and overlapping second, conflict
    input => <<EOD,
'2020-08-12T17:00:00': -10
'2020-08-12T22:00:00': -10
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T17:00:00: -00:00:10
  2020-08-12T20:00:00: +00:00
  2020-08-12T22:00:00: -00:00:10
  2020-08-13T01:00:00: +00:00
EOD
  },

  {    # new range encompassing second, conflict
    input => <<EOD,
'2020-08-12T17:00:00': -10
'2020-08-13T03:00:00': -10
EOD
    expect => <<EOD,
---
A:
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T17:00:00: -00:00:10
  2020-08-12T20:00:00: +00:00
  2020-08-13T03:00:00: -00:00:10
EOD
  },

  {    # new encompassing both
    input => <<EOD,
'2020-08-12T08:00:00': -10
'2020-08-13T03:00:00': -10
EOD
    expect => <<EOD,
---
A:
  2020-08-12T08:00:00: -00:00:10
  2020-08-12T10:00:00: -00:00:05
  2020-08-12T20:00:00: +00:00
  2020-08-13T03:00:00: -00:00:10
EOD
  },

);

foreach my $test (@tests) {
  $co =
    Image::Synchronize::CameraOffsets
      ->new( log_callback => sub { print @_ } );
  $co->parse( Load($two_ranges) );
  if ( $test->{expect} ) {
    my $input = Load( $test->{input} );
    while ( my ( $time, $offset ) = each %{$input} ) {
      $time = Image::Synchronize::Timestamp->new($time);
      $co->set( 'A', $time, $offset );
    }
    $co->make_effective;
    is(
      Dump(Image::Synchronize::CameraOffsets::export_internal($co->{effective})),
      Dump(Load($test->{expect})), # output may depend on YAML version
      'merge ' . test_id( $test->{input} )
    );
  }
  else {
    fail("bad merge?");
  }
}

# Test offsets with timezones

$co = $co->new;
my $t = Image::Synchronize::Timestamp->new('-0:1:2+05:00');
$co->set('A', t('2020-08-12T12:34:00'), $t);
my $t2 = $co->get('A', t('2020-08-12T10:00:00'));
is($t2->display_time, '-00:01:02+05:00', 'offset with timezone');

done_testing;
