#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 27;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }
  
use Devel::Size::Report qw/track_size entries_per_element track_sizes/;
use Devel::Size qw/total_size/;

my $x = "A string";
my $v = "V string";
my $y = "A longer string";
my $z = "Some other text";
my $elems = [ $x,$y,$z ];

# see that track_size works ok with scalars
foreach my $elem (@$elems)
  {
  my @size = track_size ( $elem );
  is ($size[0], 0, 'level is 0');
  is ($size[1], Devel::Size::Report::S_SCALAR(), 'type S_SCALAR');
  is ($size[2], total_size($elem), 'size is ok');
  is ($size[3], 0, 'overhead for scalars is 0');
  is ($size[4], undef, 'not a key');
  }

#############################################################################
# check that track_size generates the correct amount of entries
my @size;

# scalars
@size = track_size ( $x );
is (scalar @size, entries_per_element(), '1 (1 scalar) elements');

# scalar ref
my @size_ref = track_size ( \$x );
is (scalar @size_ref, entries_per_element() * 2, '2 (1 ref, 1 scalar) elements');

# check that a scalar ref is bigger than a scalar

is ($size[2] < $size_ref[2], 1, 'ref to scalar is bigger than scalar alone');

# array ref
@size = track_size ( $elems );

is (scalar @size, entries_per_element() * ( 3 + 1), '4 (3 scalars + 1 array) elements');

# check that nested arrays work
@size = track_size ( [ $x,$y,$z, [ $x, $y, $z] ] );

is (scalar @size, entries_per_element() * (6 + 2), '8 (6 scalars + 2 arrays) elements');

# check that nested arrays work
@size = track_size ( { 1 => $x, 2 => $y, 3 => $z, 4 => { 1 => $x, 2 => $y, 3 => $z } } );

is (scalar @size, entries_per_element() * ( 6 + 2), '8 (6 scalars + 2 hashes) elements');

# check that nested arrays/hashes work
@size = track_size ( [ $x,$y,$z, { 1 => $x, 2 => $y, 3 => $z } ] );

is (scalar @size, entries_per_element() * ( 6 + 2), '8 (6 scalars + 1 array + 1 hash) elements');

@size = track_size ( { a => $x, b => $y, c => $z, d => [ $x, $y, $z, $x ] } );
is (scalar @size, entries_per_element() * ( 7 + 2), '9 (7 scalars + 1 array + 1 hash) elements');

#############################################################################
# blessed objects

my $self = [ $x ]; bless $self, 'Foo';
@size = track_size ( $self );

is (scalar @size, entries_per_element() * (1 + 1), '2 (1 scalar + 1 array) elements');

$self = { value => $x }; bless $self, 'Bar';
@size = track_size ( $self );

is (scalar @size, entries_per_element() * (1 + 1), '2 (1 scalar + 1 hash) elements');

#############################################################################
# cycles

$a = { foo => 23, bar => 45, baz => { umpf => 1234 } };
$a->{baz}->{parent} = $a;

@size = track_size ( $a );

#  Hash(0x82add08) 405 bytes (overhead: 183 bytes, 45.19%)
#    'bar' => Scalar(0x82ade10) 16 bytes
#    'baz' => Hash(0x82a0560) 190 bytes (overhead: 158 bytes, 83.16%)
#      'umpf' => Scalar(0x82add38) 16 bytes
#      'parent' => Circular ref(0x82add08) 16 bytes

is (scalar @size, entries_per_element() * 6, '6 (4 scalar + 2 hash) elements');

Devel::Size::Report::hide_tracks();

my $sizes = track_sizes ( $a );

is (scalar @$sizes, entries_per_element() * 6, '6 (4 scalar + 2 hash) elements');

