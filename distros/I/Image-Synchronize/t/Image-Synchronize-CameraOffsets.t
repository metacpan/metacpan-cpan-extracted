#!/usr/bin/perl -w
use strict;
use warnings;

use Image::Synchronize::CameraOffsets;
use Image::Synchronize::Logger qw(log_message set_printer);
use Test::More;
use YAML::Any qw(Dump Load);

my $co = Image::Synchronize::CameraOffsets->new;
isa_ok( $co, 'Image::Synchronize::CameraOffsets' );
is( $co->get( 'A', 1000 ), undef, 'no data yet for camera A' );

$co->set( 'A', 1234, -5 );
is_deeply(
  $co->{added},
  { A => { 1234 => { offset => -5 } } },
  'set first item'
);
is_deeply( $co->{effective}, {}, 'not synchronized yet' );
is( $co->get( 'B', 1000 ), undef, 'no data for camera B' );
is_deeply( $co->{effective}, { A => { 1234 => -5 } }, 'synchronized' );
is( $co->get( 'A', 1233 ), -5, 'before first' );
is( $co->get( 'A', 1234 ), -5, 'begin of segment' );
is( $co->get( 'A', 1235 ), -5, 'after last' );

$co->set( 'A', 1265, -5 );
is_deeply(
  $co->{added},
  {
    A => {
      1234 => { offset => -5 },
      1265 => { offset => -5 }
    }
  },
  'extend segment'
);
is( $co->get( 'A', 1233 ), -5, '1233 before first' );
is_deeply(
  $co->{effective},
  {
    A => {
      1234 => -5,
      1265 => -5
    }
  },
  'synchronized'
);
is( $co->get( 'A', 1234 ), -5, '1234 in segment 1' );
is( $co->get( 'A', 1235 ), -5, '1235 in segment 1' );
is( $co->get( 'A', 1265 ), -5, '1265 in segment 1' );
is( $co->get( 'A', 1266 ), -5, '1266 after last ' );

$co->set( 'A', 1400, -5 );
is_deeply(
  $co->{added},
  {
    A => {
      1234 => { offset => -5 },
      1265 => { offset => -5 },
      1400 => { offset => -5 }
    }
  },
  'extend segment'
);
$co->set( 'A', 1445, 0 );
is_deeply(
  $co->{added},
  {
    A => {
      1234 => { offset => -5 },
      1265 => { offset => -5 },
      1400 => { offset => -5 },
      1445 => { offset => 0 }
    }
  },
  'new segment'
);
$co->set( 'A', 1500, 0 );
is_deeply(
  $co->{added},
  {
    A => {
      1234 => { offset => -5 },
      1265 => { offset => -5 },
      1400 => { offset => -5 },
      1445 => { offset => 0 },
      1500 => { offset => 0 }
    }
  },
  'extend segment'
);

is_deeply(
  $co->{effective},
  {
    A => {
      1234 => -5,
      1265 => -5
    }
  },
  'not resynchronized'
);
is( $co->get( 'A', 1233 ), -5, 'before first' );
is_deeply(
  $co->{effective},
  {
    A => {
      1234 => -5,
      1445 => 0,
      1500 => 0
    }
  },
  'resynchronized'
);
is( $co->get( 'A', 1444 ), -5, 'first' );
is( $co->get( 'A', 1445 ), 0,  'begin of last' );
is( $co->get( 'A', 1500 ), 0,  'end of last' );
is( $co->get( 'A', 1500 ), 0,  'beyond last' );

my $two_ranges = <<EOD;
---
A:
  1000 : -5
  2000 : 0
  2500 : 0
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
1500: -5
2000: -5
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2500: 0
EOD
  },

  {    # new before first, other offset
    input => <<EOD,
400 : -7
800 : -7
EOD
    expect => <<EOD,
---
A:
  400: -7
  1000: -5
  2000: 0
  2500: 0
EOD
  },

  {    # new before first, same offset
    input => <<EOD,
400: -5
800: -5
EOD
    expect => <<EOD,
---
A:
  400: -5
  2000: 0
  2500: 0
EOD
  },

  {    # new equal to first
    input => <<EOD,
1000: -5
1500: -5
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2500: 0
EOD
  },

  {    # new after first, same offset
    input => <<EOD,
1500: -5
1700: -5
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2500: 0
EOD
  },

  {    # new between first and second, other offset
    input => <<EOD,
1600: 77
1700: 77
EOD
    expect => <<EOD,
---
A:
  1000: -5
  1600: 77
  2000: 0
  2500: 0
EOD
  },

  {    # new between first and second, touching second
    input => <<EOD,
1700: 0
2000: 0
EOD
    expect => <<EOD,
---
A:
  1000: -5
  1700: 0
  2500: 0
EOD
  },

  {    # new equal to existing
    input => <<EOD,
2000: 0
2500: 0
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2500: 0
EOD
  },

  {    # new range encompassing second, merge
    input => <<EOD,
1800: 0
2700: 0
EOD
    expect => <<EOD,
---
A:
  1000: -5
  1800: 0
  2700: 0
EOD
  },

  {    # new range after and touching last, merge
    input => <<EOD,
2000: 0
2700: 0
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2700: 0
EOD
  },

  {    # new range after and touching last, merge
    input => <<EOD,
2500: 0
2800: 0
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2800: 0
EOD
  },

  {    # new range after last, merge
    input => <<EOD,
2700: 0
2800: 0
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2800: 0
EOD
  },

  {    # new range after last, other offset
    input => <<EOD,
2700: 22
2800: 22
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2700: 22
  2800: 22
EOD
  },

  {
    input => <<EOD,
900: -10
1300: -10
EOD
    expect => <<EOD,
---
A:
  900: -10
  1000: -5
  1300: -10
  2000: 0
  2500: 0
EOD
  },

  {    # new range after and overlapping first, conflict
    input => <<EOD,
1300: -10
1600: -10
EOD
    expect => <<EOD,
---
A:
  1000: -5
  1300: -10
  2000: 0
  2500: 0
EOD
  },

  {    # new range overlapping first and second, conflict
    input => <<EOD,
1300: -5
2200: -5
EOD
    expect => <<EOD,
---
A:
  1000: -5
  2000: 0
  2200: -5
  2500: 0
EOD
  },

  {    # new range before and overlapping second, conflict
    input => <<EOD,
1700: -10
2200: -10
EOD
    expect => <<EOD,
---
A:
  1000: -5
  1700: -10
  2000: 0
  2200: -10
  2500: 0
EOD
  },

  {    # new range encompassing second, conflict
    input => <<EOD,
1700: -10
2700: -10
EOD
    expect => <<EOD,
---
A:
  1000: -5
  1700: -10
  2000: 0
  2700: -10
EOD
  },

  {    # new encompassing both
    input => <<EOD,
800: -10
2700: -10
EOD
    expect => <<EOD,
---
A:
  800: -10
  1000: -5
  2000: 0
  2700: -10
EOD
  },

);

foreach my $test (@tests) {
  $co =
    Image::Synchronize::CameraOffsets->new( log_callback => sub { print @_ } );
  $co->parse( Load($two_ranges) );
  if ( $test->{expect} ) {
    my $input = Load( $test->{input} );
    while ( my ( $time, $offset ) = each %{$input} ) {
      $co->set( 'A', $time, $offset );
    }
    $co->make_effective;
    is(
      Dump( $co->{effective} ),
      Dump( Load( $test->{expect} ) ),
      'merge ' . test_id( $test->{input} )
    );
  }
  else {
    fail("bad merge?");
  }
}

done_testing;
