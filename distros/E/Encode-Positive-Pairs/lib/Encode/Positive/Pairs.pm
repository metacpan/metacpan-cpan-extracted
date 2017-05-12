#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Encode pairs of positive integers as a single integer and vice-versa
#
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Encode::Positive::Pairs;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);

our $VERSION = '2017.302';

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub equation($) {my ($t) = @_; $t * ($t + 1) / 2}

sub search($$$)
 {my ($n, $l, $u) = @_;

  for(1..64)
   {my ($L, $U) = map{equation($_)} $l, $u;

    return ($l, 0) if $n == $L;
    return ($u, 0) if $n == $U;

    my $m = int(($l+$u) / 2);

    if ($l == $m)
     {my $d = $n-$L;
      return ($l-$d, $d);
     }

    my $M = equation($m);
    return ($m, 0) if $M == $n;
    ($M > $n ? $u : $l) = $m
   }
 }

sub singleToPair($)
 {my ($n) = @_;
  return (0, 0) unless $n;
  $n < 2**64 or confess "singleToPair: $n >= 2**64";
  $n == int($n) or confess "singleToPair: $n is not an integer";

  for my $x(0..64)
   {my $t = 1<<$x;
    my $steps = equation($t);
    return ($t, 0) if $steps == $n;
    next if $steps < $n;
    return search($n, 1<<($x-1), 1<<$x);
   }
 }

sub pairToSingle($$)
 {my ($i, $j) = @_;
  my $d = $i + $j;
  ($d * $d + $d) / 2 + $j
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <Encode::Positive::Pairs::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

=pod

=encoding utf-8

=head1 Name

Encode::Positive::Pairs - encode pairs of positive integers as a single integer and vice versa

=head1 Synopsis

 use Encode::Positive::Pairs;

 my ($i, $j) = Encode::Positive::Pairs::singleToPair(4);
 ok $i == 1 && $j == 1;

 ok 4 == Encode::Positive::Pairs::pairToSingle(1, 1);

=head1 Description

 Encode::Positive::Pairs::singleToPair($n)

finds the pair of positive integers ($i, $j) with $j < $i corresponding to the
positive integer $n

 Encode::Positive::Pairs::pairToSingle($i, $j)

finds the single integer representing the pair of positive integers ($i, $j)

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests=>5153;

for   my $i(0..100)
 {for my $j(0..$i)
   {my $n       = Encode::Positive::Pairs::pairToSingle($i, $j);
    my ($I, $J) = Encode::Positive::Pairs::singleToPair($n);
    ok $i == $I && $j == $J;
   }
 }

if (1)
 {my ($i, $j) = Encode::Positive::Pairs::singleToPair(4);
  ok $i == 1 && $j == 1;
  ok 4 == Encode::Positive::Pairs::pairToSingle(1, 1);
 }
