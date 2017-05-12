#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 13;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }

# import anything
use Devel::Size::Report qw/
  report_size track_size element_type
  entries_per_element
  /;

use Devel::Size qw/size total_size/;
use Scalar::Util qw/weaken/;
use Array::RefElem qw/av_push/;

#############################################################################
# find out how large one single array ref is
my @size = track_size( [] );
my $array_size = $size[2];
print "# array size: $array_size\n";

# find out how big a single scalar is
@size = track_size( 1 );
my $scalar_size = $size[2];
print "# scalar size: $scalar_size\n";

# find out how much an array grows
@size = track_size( [ 1,2 ] );
my $array_grow = ($size[2] - $scalar_size * 2 - $array_size) / 2;
print "# array grow: $array_grow\n";

#############################################################################
# Take an empty array, add one other empty array, this must be equal to
# the size two empty arrays, plus the array growth.

@size = track_size( [ [ ] ] );

# if there is only one element in the array, it does not grow by "$array_grow"
is ($size[2], 2 * $array_size + $array_grow, 'two empty arrays');

@size = track_size( [ 1, [ ] ] );
is ($size[2], $array_grow * 2 + 2 * $array_size + 1 * $scalar_size, 'two empty arrays, one scalar');

@size = track_size( [ 1, 2, [ ] ] );
is ($size[2], $array_grow * 3 + 2 * $array_size + 2 * $scalar_size, 'two empty arrays, two scalars');

@size = track_size( [ 1, 2, 3, [ ] ] );
is ($size[2], $array_grow * 4 + 2 * $array_size + 3 * $scalar_size, 'two empty arrays, three scalars');

@size = track_size( [ 1, 2, 3, [ 1 ] ] );
is ($size[2], $array_grow * 5 + 2 * $array_size + 4 * $scalar_size, 'two empty arrays, four scalars');

@size = track_size( [ 1, 2, 3, [ 1, 2] ] );
is ($size[2], $array_grow * 6 + 2 * $array_size + 5 * $scalar_size, 'two empty arrays, five scalars');

#############################################################################
#############################################################################
# See that pushing double scalars onto an array does not increase the size

my $scalar = 1;
my $array = [ ];

@size = track_size( $array );
is ($size[2], $array_size, 'one empty array');

av_push @$array, $scalar;

@size = track_size( $array );

# 4 times array grow because the push extends the array by 4 slots, seemingly
my $base_size = $array_size + 1 * $scalar_size + 4 * $array_grow;

is ($size[2], $base_size, 'one array, plus one scalars (no double testing)');

# the same since there is only one scalar involved
@size = track_size( $array, { doubles => 1 } );
is ($size[2], $base_size, 'one array, plus one scalars (double testing)');

#############################################################################
# test without "double" first, so we do not notice the doubled scalar

av_push( @$array, $scalar);

@size = track_size( $array );
is ($size[2], $base_size + 1 * $scalar_size, 'one array, plus two scalars (no double testing)');

@size = track_size( $array, { doubles => 1 } );
is ($size[2], $base_size, 'one array, plus two scalars (double testing)');

# one more:

av_push( @$array, $scalar);

@size = track_size( $array );
is ($size[2], $base_size + 2 * $scalar_size, 'one array, plus two scalars (no double testing)');

@size = track_size( $array, { doubles => 1 } );
is ($size[2], $base_size, 'one array, plus two scalars (double testing)');


