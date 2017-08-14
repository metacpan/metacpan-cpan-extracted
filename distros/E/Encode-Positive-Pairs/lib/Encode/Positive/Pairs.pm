#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Encode pairs of positive integers as a single integer and vice-versa
#
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2017
#-------------------------------------------------------------------------------
# podDocumentation

package Encode::Positive::Pairs;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Math::BigInt;

our $VERSION = '20170812';

#1 Convert                                                                      # Encode pairs of positive integers as a single integer and vice-versa

sub equation($)                                                                 #P The sum of the numbers from 1 to a specified number
 {my ($t) = @_;                                                                 # The number of leading integers to sum
  $t * ($t + 1) / 2
  }

sub search($$$)                                                                 #P Return the pair that encode to the number specified
 {my ($n, $l, $u) = @_;                                                         # Number to decode, lower limit, upper limit

  for(1..4*length($n))
   {my ($L, $U) = map{equation(Math::BigInt->new($_))} $l, $u;

    return ($l, 0) if $n == $L;
    return ($u, 0) if $n == $U;

    my $m = ($l+$u) >> 1;

    if ($l == $m)
     {my $d = $n - $L;
      return ($l - $d, $d);
     }

    my $M = equation($m);
    return ($m, 0) if $M == $n;
    ($M > $n ? $u : $l) = $m
   }
 }

sub singleToPair($)                                                             # Decode a single integer into a pair of integers
 {my ($N) = @_;                                                                 # Number to decode
  $N =~ m/\A\d+\Z/s or confess "$N is not an integer";
  return (0, 0) unless $N;                                                      # Simple case

  my $n = Math::BigInt->new($N);

  for my $x(0..4*length($N))                                                    # Maximum number of searches required
   {my $t = Math::BigInt->new(1)<<$x;
    my $steps = equation($t);
    return ($t, 0) if $steps == $n;
    next if $steps < $n;
    return search($n, Math::BigInt->new(1)<<($x-1), Math::BigInt->new(1)<<$x);
   }
 }

sub pairToSingle($$)                                                            # Return the single integer representing a pair of integers
 {my ($I, $J) = @_;                                                             # First number of pair to encode, second number of pair to encode
  my $i = Math::BigInt->new($I);
  my $j = Math::BigInt->new($J);
  my $d = $i + $j;
  ($d * $d + $d) / 2 + $j
 }

#-------------------------------------------------------------------------------
# Export
#---------------------------------------/lib/Encode/Positive/Pairs.pm   ----------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Encode::Positive::Pairs - encode pairs of positive integers as a single integer and vice versa

=head1 Synopsis

 use Encode::Positive::Pairs;

 my ($i, $j) = Encode::Positive::Pairs::singleToPair(4);
 ok $i == 1 && $j == 1;

 ok 4 == Encode::Positive::Pairs::pairToSingle(1, 1);

Larger numbers are automatically supported via L<Math::BigInt>:

  my $n = '1'.('0'x121).'1';
  my ($i, $j) = Encode::Positive::Pairs::singleToPair($n);

  ok $i == "1698366900312561357458283662619176178439283700581622961703001";
  ok $j == "12443768723418389130558603579477804607257435053187857770063795";

  ok $n == Encode::Positive::Pairs::pairToSingle($i, $j);

=head1 Description

=head2 Convert

Encode pairs of positive integers as a single integer and vice-versa

=head3 singleToPair($)

Decode a single integer into a pair of integers

  1  $N  Number to decode  

=head3 pairToSingle($$)

Return the single integer representing a pair of integers

  1  $I  First number of pair to encode   
  2  $J  Second number of pair to encode  


=head1 Private Methods

=head2 equation($)

The sum of the numbers from 1 to a specified number

  1  $t  The number of leading integers to sum  

=head2 search($$$)

Return the pair that encode to the number specified

  1  $n  Number to decode  
  2  $l  Lower limit       
  3  $u  Upper limit       


=head1 Index


L<equation|/equation>

L<pairToSingle|/pairToSingle>

L<search|/search>

L<singleToPair|/singleToPair>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests=>5156;

if (1)
 {for   my $i(0..100)
   {for my $j(0..$i)
     {my $n       = Encode::Positive::Pairs::pairToSingle($i, $j);
      my ($I, $J) = Encode::Positive::Pairs::singleToPair($n);
      ok $i == $I && $j == $J;
     }
   }
 }

if (1)
 {my ($i, $j) = Encode::Positive::Pairs::singleToPair(4);
  ok $i == 1 && $j == 1;
  ok 4 == Encode::Positive::Pairs::pairToSingle(1, 1);
 }

if (1)
 {my $n = '1'.('0'x121).'1';
  my ($i, $j) = Encode::Positive::Pairs::singleToPair($n);
  ok $i == "1698366900312561357458283662619176178439283700581622961703001";
  ok $j == "12443768723418389130558603579477804607257435053187857770063795";
  ok $n == Encode::Positive::Pairs::pairToSingle($i, $j);
 }
