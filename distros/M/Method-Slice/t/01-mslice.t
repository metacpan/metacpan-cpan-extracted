#!perl

# stupid class just to have some methods to test
package Point;
use strict;
use warnings;

# constructor
sub new {
  my $class = shift;
  bless {x => shift, y => shift, z => shift}, $class;
}

# x and y accessors
for my $meth (qw/x y/) {
  no strict 'refs';
  *$meth = sub { my $self = shift;
                 $self->{$meth} = shift if @_;
                 return $self->{$meth}; };
}

sub z {
  my $self = shift;
  $self->{z} = shift if @_;
  return wantarray
    ? (qw(hello list context))
    : $self->{z};
}

package main;
use strict;
use warnings;
use Method::Slice;
use Test::More;

plan tests => 9;

my $point = Point->new(5, 7, 1_000);
is($point->x, 5);
is($point->y, 7);
is($point->z, 1_000);

# transpose
(mslice($point, qw/x y/)) = mslice($point, qw/y x/);
is($point->x, 7);
is($point->y, 5);

# move 10 units on x, y, and z axes
(mslice($point, qw/x y z/)) = map {$_ + 10} @{[mslice($point, qw/x y z/)]};
is($point->x, 17);
is($point->y, 15);
is($point->z, 1_010);

# the call context for method calls is correct
my ($x, $y, $z) = mslice($point, qw/x y z/);
is_deeply( {x => $x,        y => $y,        z => $z   },
           {x => $point->x, y => $point->y, z => 1_010} );

# The line below won't work because that's an lvalue context without ASSIGN
# (mslice($point, qw/x y/)) = map {$_ - 2} mslice($point, qw/y x/);

# These won't work because they assign to a throwaway copy
# $_ += 50 for mslice($point, qw/x y/);
# is($point->x, 67);
# is($point->y, 65);
