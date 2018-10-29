#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Vectors in two dimensions
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2017
#-------------------------------------------------------------------------------
# podDocumentation

package Math::Vectors2;
require v5.16;
our $VERSION = '20181026';
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Table::Text qw(:all);

my $nearness = 1e-6;                                                            # Definition of near

sub zero1($)                                                                    # Check a scalar is near zero
 {my ($o) = @_;
  near1($o, 0)
 }

sub zero2($)                                                                    # Check a vectors is nearly the 0 vector
 {my ($o) = @_;
  near1($o->x, 0) && near1($o->y, 0)
 }

sub near1($$)                                                                   # Check two scalars are near each other
 {my ($o, $p) = @_;
  abs($p-$o) < $nearness
 }

sub near2($$)                                                                   # Check two vectors are near each other
 {my ($o, $p) = @_;
  $o->d($p) < $nearness
 }

#1 Attributes                                                                   # Attributes that can be set by =

genLValueScalarMethods(qw(x));                                                  # X component of vector.
genLValueScalarMethods(qw(y));                                                  # Y component of vector.

#1 Methods                                                                      # Vector methods.

sub new($$)                                                                     # Create new vector from components.
 {my ($x, $y) = @_;                                                             # X component, Y component
  bless {x=>$x, y=>$y}
 }

sub zeroAndUnits()                                                              # Create the useful vectors: o=(0,0), x=(1,0), y=(0,1)
 {map {&new(@$_)} ([0, 0], [1, 0], [0, 1])
 }

sub print($@)                                                                   # Print one or more vectors.
 {my ($p, @p) = @_;                                                             # Vector to print, more vectors to print
  join ', ', map {'('.$_->x.','.$_->y.')'} @_
 }

sub values($)                                                                   # Return components of a vector as a list.
 {my ($p) = @_;                                                                 # Vector
  ($p->x, $p->y)
 }

sub clone($)                                                                    # Clone a vector.
 {my ($o) = @_;                                                                 # Vector to clone
  new($o->x, $o->y)
 }

sub plus($@)                                                                    # Add zero or more other vectors to a copy of the first vector and return the result.
 {my ($o, @p) = @_;                                                             # First vector, other vectors
  my $q = $o->clone;
  for(@p)
   {$q->x += $_->x;
    $q->y += $_->y;
   }
  $q
 }

sub minus($@)                                                                   # Subtract zero or more vectors from a copy of the first vector and return the result.
 {my ($o, @p) = @_;                                                             # First vector, other vectors
  my $q = $o->clone;
  for(@p)
   {$q->x -= $_->x;
    $q->y -= $_->y;
   }
  $q
 }

sub times($$)                                                                   # Multiply a copy of a vector by a scalar and return the result.
 {my ($o, $m) = @_;                                                             # Vector, scalar to multiply by
  new($o->x * $m, $o->y * $m)
 }

sub l($)                                                                        # Length of a vector.
 {my ($o) = @_;                                                                 # Vector
  sqrt($o->x**2 + $o->y**2)
 }

sub l2($)                                                                       # Length squared of a vector.
 {my ($o) = @_;                                                                 # Vector
  $o->x**2 + $o->y**2
 }

sub d($$)                                                                       # Distance between the points identified by two vectors when placed on the same point.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  sqrt(($o->x-$p->x)**2 + ($o->y-$p->y)**2)
 }

sub d2($$)                                                                      # Distance squared between the points identified by two vectors when placed on the same point.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  ($o->x-$p->x)**2 + ($o->y-$p->y)**2
 }

sub n($)                                                                        # Return a normalized a copy of a vector.
 {my ($o) = @_;                                                                 # Vector
  my $l = $o->l;
  $l == 0 and confess;
  new($o->x / $l, $o->y / $l)
 }

sub dot($$)                                                                     # Dot product of two vectors.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->x * $p->x + $o->y * $p->y
 }

sub area($$)                                                                    # Signed area of the parallelogram defined by the two vectors. The area is negative if the second vector appears to the right of the first if they are both placed at the origin and the observer stands against the z-axis in a left handed coordinate system.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->x * $p->y - $o->y * $p->x
 }

sub cos($$)                                                                     # cos(angle between two vectors) in radians.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->dot($p) / $o->l / $p->l
 }

sub sin($$)                                                                     # sin(angle between two vectors) in radians.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->area($p) / $o->l / $p->l
 }

sub r90($)                                                                      # Rotate a vector by 90 degrees anticlockwise.
 {my ($o) = @_;                                                                 # Vector to rotate
  new(-$o->y, $o->x)
 }

sub r180($)                                                                     # Rotate a vector by 180 degrees.
 {my ($o) = @_;                                                                 # Vector to rotate
  new(-$o->x, -$o->y)
 }

sub r270($)                                                                     # Rotate a vector by 270 degrees anticlockwise.
 {my ($o) = @_;                                                                 # Vector to rotate
  new($o->y, -$o->x)
 }

# podDocumentation

=encoding utf-8

=head1 Name

Math::Vectors2 - Vectors in two dimensions

=head1 Synopsis

 use Math::Vectors2;

 my ($o, $x, $y) = Math::Vectors2::zeroAndUnits;
 ok $o->print($x, $y) eq '(0,0), (1,0), (0,1)';

 my $p1 = $x->times(3);
 my $p2 = $y->times(4);
 my $p  = $o->plus($p1, $p2);

 ok $p->print($p1, $p2) eq '(3,4), (3,0), (0,4)';
 ok $o->d($p) == 5;

Or more briefly:

 use Math::Vectors2;

 *v = *Math::Vectors2::new;

 ok v(3,4)->l == 5;

=head1 Description

Vectors in two dimensions


Version '20171009'.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.




=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Math::Vectors2

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 42;

my ($o, $x, $y) = Math::Vectors2::zeroAndUnits;                                 #TzeroAndUnits
ok $o->print($x, $y) eq '(0,0), (1,0), (0,1)';                                  #TzeroAndUnits #Tnew #Tprint #Ttimes #Tdot #Td2

my $p1 = $x->times(3);                                                          #Ttimes
my $p2 = $y->times(4);                                                          #Ttimes
my $P = $o->plus($p1, $p2);                                                     #Tplus
ok $o->print($P, $p1, $p2) eq '(0,0), (3,4), (3,0), (0,4)';                     #Tclone #Tplus #Ttimes
my $p = $P->clone;                                                              #Tclone
ok $p->print($P) eq '(3,4), (3,4)';                                             #Tclone #Tl
ok $p->l == 5;                                                                  #Tl #Tn
ok $P->l == 5;

ok near1($p->x, 3);
ok near1($p->y, 4);
ok near2($p, $p);
ok $o->print($p) eq '(0,0), (3,4)';                                             #Td
ok $o->d($p) == 5;                                                              #Td
ok $p->d($o) == 5;

ok $o->print($p, $p1, $p2) eq '(0,0), (3,4), (3,0), (0,4)';                     #Tminus
ok near2($o, $p->minus($p1, $p2));                                              #Tminus

ok near2(Math::Vectors2::new(0, 0), $o);                                        #Tnew

ok near1($p->n->l, 1);                                                          #Tn

ok near1($x->dot($y), 0);                                                       #Tdot

if (1)
 {ok near1($x->d2($y), 2);                                                      #Td2
  ok near1($x->plus($x)->d2($y), 5);                                            #Td2
 }

if (1)
 {ok near1($x->plus($y)->l2, 2);                                                #Tl2
 }

if (1)
 {my ($x, $y) = Math::Vectors2::new(3, 4)->values;                              #Tvalues
  ok $x == 3 && $y == 4;                                                        #Tvalues
 }

ok near2($x->r90, $y);                                                          #Tr90
ok near2($y->r90, $o->minus($x));                                               #Tr90
ok near2($x->r90->r90, $x->r180);                                               #Tr180
ok near2($y->r90->r90, $y->r180);
ok near2($x->r90->r90->r90, $x->r270);                                          #Tr270
ok near2($y->r90->r90->r90, $y->r270);

ok near1($x->cos($x), +1);                                                      #Tcos
ok near1($y->cos($y), +1);
ok zero1($x->cos($y));                                                          #Tcos
ok zero1($y->cos($x));

ok zero1($x->sin($x));                                                          #Tsin
ok zero1($y->sin($y));
ok near1($x->sin($y), +1);                                                      #Tsin
ok near1($y->sin($x), -1);

ok near1($x->plus($y)->sin($x), -sqrt(1/2));
ok near1($x->plus($y)->sin($y), +sqrt(1/2));
ok near1($x->plus($y)->area($x->times(2)), -2);                                 #Tarea
ok near1($x->plus($y)->area($y->times(2)), +2);                                 #Tarea

ok near1($x->plus($y)->r90->area($x->plus($y)),  -2);
ok near1($x->plus($y)->r270->area($x->plus($y)), +2);

if (1)
 {*v = *Math::Vectors2::new;
  ok v(3,4)->l         == 5;
  ok v(3,4)->d(v(0,0)) == 5;
 }
