#!/usr/bin/perl -w
use strict;
use warnings;

use Image::Synchronize::GpsPositionCollection;
use Test::More;
use YAML::Any qw(Dump);

my @data = ( 3, 7, 9, 14, 33, 51, 78, 79, 85 );

sub get {
  return $data[ $_[0] ];
}

sub search {
  Image::Synchronize::GpsPositionCollection::search(@_);
}

is_deeply(
  [ map { search( $data[$_], scalar(@data), \&get ) } 0 .. $#data ],
  [ 0 .. $#data ],
  'find exact (odd count)'
);

is_deeply(
  [ map { search( $data[$_] - 1, scalar(@data), \&get ) } 0 .. $#data ],
  [ -1, 0, 1, 2, 3, 4, 5, 6, 7 ],
  'find one less (odd count)'
);

is_deeply(
  [ map { search( $data[$_] + 1, scalar(@data), \&get ) } 0 .. $#data ],
  [ 0, 1, 2, 3, 4, 5, 7, 7, 8 ],
  'find one more (odd count)'
);

pop @data;

is_deeply(
  [ map { search( $data[$_], scalar(@data), \&get ) } 0 .. $#data ],
  [ 0 .. $#data ],
  'find exact (even count)'
);

is_deeply(
  [ map { search( $data[$_] - 1, scalar(@data), \&get ) } 0 .. $#data ],
  [ -1, 0, 1, 2, 3, 4, 5, 6 ],
  'find one less (even count)'
);

is_deeply(
  [ map { search( $data[$_] + 1, scalar(@data), \&get ) } 0 .. $#data ],
  [ 0, 1, 2, 3, 4, 5, 7, 7 ],
  'find one more (even count)'
);

my $gpc = Image::Synchronize::GpsPositionCollection->new;

$gpc->add( 1000000, 1, 2, 3, 'x', 'foo' );
is_deeply( [ $gpc->ids_for_track ], ['x'], 'track IDs 1' );

is_deeply(
  $gpc->points_for_track('x'),
  [ [ 1000000, 1, 2, 3 ] ],
  'track positions 1'
);

is_deeply(
  [ $gpc->extreme_times_for_track('x') ],
  [ 1000000, 1000000 ],
  'track extreme times 1'
);

$gpc->add( 1000005, 5, 6, 7, 'x', 'foo' );
is_deeply( [ $gpc->ids_for_track ], ['x'], 'track IDs 2' );

is_deeply(
  $gpc->points_for_track('x'),
  [ [ 1000000, 1, 2, 3 ], [ 1000005, 5, 6, 7 ] ],
  'track positions 2'
);

is_deeply(
  [ $gpc->extreme_times_for_track('x') ],
  [ 1000000, 1000005 ],
  'track extreme times 2'
);

$gpc->add( 1000010, 9, 10, 11, 'x', 'foo' );
is_deeply( [ $gpc->ids_for_track ], ['x'], 'track IDs 3' );

is_deeply(
  $gpc->points_for_track('x'),
  [ [ 1000000, 1, 2, 3 ], [ 1000005, 5, 6, 7 ], [ 1000010, 9, 10, 11 ] ],
  'track positions 3'
);

is_deeply(
  [ $gpc->extreme_times_for_track('x') ],
  [ 1000000, 1000010 ],
  'track extreme times 3'
);

$gpc->add( 1000007, 13, 14, 15, 'y', 'foo/bar' )
  ->add( 1000009, 17, 18, 19, 'y', 'foo/bar' )
  ->add( 1000020, 21, 22, 23, 'y', 'foo/bar' );
is_deeply( [ $gpc->ids_for_track ], [ 'x', 'y' ], 'track IDs 4' );

is_deeply(
  $gpc->points_for_track('x'),
  [ [ 1000000, 1, 2, 3 ], [ 1000005, 5, 6, 7 ], [ 1000010, 9, 10, 11 ] ],
  'track x positions 4'
);

is_deeply(
  $gpc->points_for_track('y'),
  [ [ 1000007, 13, 14, 15 ], [ 1000009, 17, 18, 19 ], [ 1000020, 21, 22, 23 ] ],
  'track y positions 4'
);

is_deeply(
  [ $gpc->extreme_times_for_track('y') ],
  [ 1000007, 1000020 ],
  'track y extreme times 4'
);

$gpc->add( 1000040, 25, 26, 27, 'z', 'foo/fie' );
is_deeply( [ $gpc->ids_for_track ], [ 'x', 'y', 'z' ], 'track IDs 5' );

is_deeply(
  [ $gpc->ids_for_track('foo') ],
  [ 'x', 'y', 'z' ],
  'track IDs 5 for foo'
);
is_deeply( [ $gpc->ids_for_track('foo/bar') ],
  ['y'], 'track IDs 5 for foo/bar' );
is_deeply( [ $gpc->ids_for_track('foo/fie') ],
  ['z'], 'track IDs 5 for foo/fie' );

$gpc->reduce;

is_deeply(
  $gpc->points_for_track('y'),
  [ [ 1000007, 13, 14, 15 ], [ 1000009, 17, 18, 19 ], [ 1000020, 21, 22, 23 ] ],
  'track y positions 5'
);

# use Dump to construct the 'expected' outcome, because some
# implementations of YAML produce a whitespace character after the
# '---' and some do not.
is( "$gpc",
    Dump(['1970-01-12T13:46:40+00:00/13:46:50    5.00000000    6.00000000',
          '1970-01-12T13:46:47+00:00/13:47:00   17.00000000   18.00000000',
          '1970-01-12T13:47:20+00:00            25.00000000   26.00000000']),
    'stringified' );

done_testing;
