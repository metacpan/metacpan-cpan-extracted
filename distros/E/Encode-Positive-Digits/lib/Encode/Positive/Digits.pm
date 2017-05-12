#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Encode a positive integer using the specified digits and vice-versa
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Encode::Positive::Digits;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);

our $VERSION = '2017.302';

sub encode($$)
 {my ($n, $digits) = @_;

  $n < 2**64 or confess "singleToPair: $n >= 2**64";
  $n == int($n) or confess "encode: $n is not an integer";

  my @b = split //, $digits;
  my $b = @b;
  $b > 1 or confess "encode: number of digits too few, must be at least 2";
  return $b[0] if $n == 0;

  my $e = '';
  for my $position(0..64)
   {my $p = $b ** $position;
    next if $p < $n;
    return $b[1].($b[0] x $position) if $p == $n;
    for my $divide(reverse 0..$position-1)
     {my $P = $b ** $divide;
      my $D = int($n / $P);
      $e .= $b[$D];
      $n -= $P*$D;
     }
    return $e;
   }
 }

sub decode($$)
 {my ($number, $digits) = @_;

  my @b = split //, $digits;
  my $b = @b;
  $b > 1 or confess "decode: number of digits too few, must be at least 2";

  my @n = split //, $number;
  my $n = @n;

  for(1..$n)                                                                    # Validate digits
   {my $d = $n[$_-1];
    my $i = index($digits, $d);
    $i < 0 and confess "decode: Invalid digit \"$d\" in number $number at position $_";
    $n[$_-1] = $i;
   }

  my $p = 1;
  my $s = 0;
  for(reverse @n)                                                               # Decode each digit
   {$s += $p * $_;
    $p *=  $b;
   }
  $s
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <Encode::Positive::Digits::DATA>) || die $@
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

Encode::Positive::Digits - Encode a positive integer using the specified digits and vice-versa

=head1 Synopsis

 use Encode::Positive::Digits;

 ok 4830138323689 == Encode::Positive::Digits::decode("hello world", " abcdefghlopqrw");
 ok "hello world" eq Encode::Positive::Digits::encode(4830138323689, " abcdefghlopqrw");

=head1 Description

 Encode::Positive::Digits::encode($number, $digits)

expresses the positive, integer,decimal number $number as a number using the
digits supplied in $digits.

 Encode::Positive::Digits::decode($number, $digits)

returns the decimal number corresponding to the value of number $number
represented with digits $digits.

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
use Test::More tests=>642;

for my $i(0..127)
 {my $b = Encode::Positive::Digits::encode($i, "01");
  ok $b eq sprintf("%b", $i);
  ok "$i" eq Encode::Positive::Digits::decode($b, "01");
  my $x = Encode::Positive::Digits::encode($i, "0123456789abcdef");
  ok $x eq sprintf("%x", $i);
  ok "$i" eq Encode::Positive::Digits::decode($x, "0123456789abcdef");
  ok "$i" eq Encode::Positive::Digits::encode($i, "0123456789");
 }

if (1)
 {ok 4830138323689 == Encode::Positive::Digits::decode("hello world", " abcdefghlopqrw");
  ok "hello world" eq Encode::Positive::Digits::encode(4830138323689, " abcdefghlopqrw");
 }
